# System alert delivery - Dendritic Pattern
#
# One sendmail-compatible entry point that hardware monitors (smartd, ZED,
# rasdaemon) hand a message to, fanning it out to every channel that is
# actually configured on this host.
#
# Why a fake "mailer" rather than a bespoke hook: both smartd and ZED already
# speak sendmail. nixpkgs' smartd module pipes its report into
# `${mailer} -i <recipient>`, and ZED calls `$ZED_EMAIL_PROG -s '<subject>'
# <address>`. Implementing that tiny calling convention means both daemons are
# wired up without patching either module, and adding a real MTA later is a
# one-line change here instead of a rewrite.
{ config, ... }:
let
  inherit (config) constants;
in
{
  flake.modules.nixos.alerts =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.alerts;

      notify = pkgs.writeShellApplication {
        name = "system-alert";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.curl
          pkgs.jq
          pkgs.systemd
        ];
        text = ''
          # Sendmail-compatible argument handling. We only care about the
          # subject; recipients are ignored because every channel below is
          # addressed by configuration, not by the caller.
          # uname -n rather than hostname(1): the latter lives in nettools,
          # which is not a runtime input here, so it would fail exactly when an
          # alert is being raised.
          subject="System alert on $(uname -n)"
          while [ "$#" -gt 0 ]; do
            case "$1" in
              -s)
                subject="''${2:-$subject}"
                shift 2 || shift
                ;;
              *)
                shift
                ;;
            esac
          done

          body="$(cat)"

          # The journal is the channel that always works, including when the
          # box is headless, the network is down, or HA is the thing that
          # broke. Everything else below is best-effort on top of it.
          printf '%s\n%s\n' "$subject" "$body" | systemd-cat -t system-alert -p warning

          # Home Assistant push. Both secrets already exist for other
          # consumers; if sops has not decrypted them yet (early boot) we skip
          # rather than fail, because a failing alert must never take down the
          # daemon that raised it.
          ha_token_file=${lib.escapeShellArg cfg.homeAssistant.tokenFile}
          if [ -r "$ha_token_file" ]; then
            ha_url=${lib.escapeShellArg cfg.homeAssistant.baseUrl}
            ha_token="$(tr -d '[:space:]' < "$ha_token_file")"

            # Let curl do the waiting. Home Assistant's unit reaching "started"
            # is not the same as its HTTP API accepting connections: on
            # 2026-08-23 systemd logged "Started Home Assistant" at 13:56:47.991
            # and HA logged "initialized in 14.54s" at 13:57:07. Ordering
            # crash-report after the unit (crash-recovery.nix) cannot close a 20s
            # gap — only waiting on the socket can. The 2026-08-14 12:55 crash
            # report was lost to exactly that gap, and the hand-rolled 3x15s loop
            # that replaced it cleared the bar only by luck: every boot since
            # burned attempt 1 on ECONNREFUSED and narrated it in the journal as
            # a `curl: (7) Failed to connect` line that looked like a real fault.
            #
            # --retry-connrefused is the load-bearing flag: plain --retry does
            # not consider ECONNREFUSED retryable, which is the one error that
            # actually occurs here. --fail turns an expired token (401) into a
            # failure instead of a silently non-2xx success, which the previous
            # version swallowed.
            #
            # The body goes to a file rather than @-: curl cannot replay stdin
            # across a retry, so every retried POST would send an empty body.
            #
            # Widening the window to 120s does not delay boot. crash-report is
            # WantedBy=multi-user.target with no Before=, so nothing waits on it.
            # The journal already has the message by this point, so giving up
            # loses a channel, never the alert.
            payload="$(mktemp)"
            trap 'rm -f "$payload"' EXIT
            jq -n --arg title "$subject" --arg message "$body" \
              '{title: $title, message: $message}' > "$payload"

            if ! curl --silent --show-error --fail \
                 --retry 20 --retry-delay 5 --retry-connrefused --retry-all-errors \
                 --retry-max-time 120 --max-time 10 \
                 --request POST \
                 --header "Authorization: Bearer $ha_token" \
                 --header "Content-Type: application/json" \
                 --data @"$payload" \
                 "$ha_url/api/services/${cfg.homeAssistant.service}" \
                 >/dev/null; then
              echo "system-alert: Home Assistant push failed after 120s of retries" >&2
            fi
          fi

          # Real e-mail, if and only if an MTA has been installed. Nothing
          # provides sendmail on this host yet; enabling programs.msmtp (or any
          # other MTA that sets services.mail.sendmailSetuidWrapper) lights this
          # branch up with no change here.
          if command -v sendmail >/dev/null 2>&1; then
            printf 'Subject: %s\n\n%s\n' "$subject" "$body" \
              | sendmail -i ${lib.escapeShellArg cfg.mailRecipient} || true
          fi

          exit 0
        '';
      };
    in
    {
      options.alerts = {
        notify = lib.mkOption {
          type = lib.types.package;
          default = notify;
          readOnly = true;
          description = ''
            Sendmail-compatible alert fan-out program. Consumed by
            {option}`services.smartd.notifications.mail.mailer` and
            {option}`services.zfs.zed.settings.ZED_EMAIL_PROG`.
          '';
        };

        mailRecipient = lib.mkOption {
          type = lib.types.str;
          default = "root";
          description = "Address used when an MTA is present on the host.";
        };

        homeAssistant = {
          service = lib.mkOption {
            type = lib.types.str;
            default = "persistent_notification/create";
            example = "notify/mobile_app_pixel";
            description = ''
              Home Assistant service path to POST alerts to.

              The default creates a persistent notification in the HA UI, which
              exists on every install and needs no companion app. Point this at
              a `notify/mobile_app_*` service to reach a phone instead.
            '';
          };

          baseUrl = lib.mkOption {
            type = lib.types.str;
            default = "http://127.0.0.1:${toString constants.ports.services.homeAssistant}";
            description = ''
              Base URL of the Home Assistant instance to notify.

              Deliberately the loopback address rather than the public
              `HOME_ASSISTANT_BASE_URL` secret. That hostname resolves to the
              WAN address, so an alert raised on this machine would leave the
              LAN, come back through NAT and terminate TLS at Caddy — which
              fails outright here (`tlsv1 alert internal error`, verified
              2026-08-11), and would in any case make disk-failure alerts
              depend on DNS, the certificate, the reverse proxy and the
              upstream link all working. Home Assistant listens on loopback,
              so talking to it directly removes every one of those from the
              path.
            '';
          };

          tokenFile = lib.mkOption {
            type = lib.types.path;
            default = config.sops.secrets.HOME_ASSISTANT_TOKEN.path;
            defaultText = lib.literalExpression "config.sops.secrets.HOME_ASSISTANT_TOKEN.path";
            description = "File containing a Home Assistant long-lived access token.";
          };
        };
      };

      config = {
        # Available interactively so `system-alert -s test <<< hello` can prove
        # the delivery path works without waiting for a disk to actually fail.
        environment.systemPackages = [ cfg.notify ];

        # Generic failure reporter: add `OnFailure = [ "alert@%n.service" ]` to
        # any unit and its failure reaches the same channels as a disk error.
        #
        # smartd and ZED report *events* through their own hooks, which says
        # nothing about whether those daemons are still running, nor about
        # anything else on the box. podman-huntarr.service sat failed for weeks
        # before a manual audit found it — and the reason turned out to be that
        # upstream had pulled the image over a credential-leaking CVE, which is
        # exactly the kind of thing worth hearing about promptly. A nightly
        # backup that silently stops is strictly worse than no backup, because
        # it looks like one. This closes that gap for any unit worth naming.
        systemd.services."alert@" = {
          description = "Report failure of %i";
          serviceConfig = {
            Type = "oneshot";
            # `systemctl status` is the single most useful thing to have
            # already in hand when the alert arrives, so send it as the body
            # rather than a bare "unit failed".
            ExecStart = ''
              ${pkgs.writeShellScript "alert-unit-failure" ''
                unit="$1"
                {
                  ${pkgs.systemd}/bin/systemctl status --full --lines=50 --no-pager "$unit" || true
                } | ${cfg.notify}/bin/system-alert -s "Unit failed on $(${pkgs.coreutils}/bin/uname -n): $unit"
              ''} %i
            '';
          };
        };
      };
    };
}
