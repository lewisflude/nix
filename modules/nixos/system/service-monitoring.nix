{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    ;
  cfg = config.services.systemd-monitoring;
in
{
  options.services.systemd-monitoring = {
    enable = mkEnableOption "systemd service failure monitoring" // {
      default = true;
    };

    notificationEmail = mkOption {
      type = types.str;
      default = "root@localhost";
      description = "Email address to send failure notifications to";
    };

    enableEmailNotifications = mkOption {
      type = types.bool;
      default = false;
      description = "Enable email notifications (requires working mail setup)";
    };

    criticalServices = mkOption {
      type = types.listOf types.str;
      default = [
        "qbittorrent.service"
        "home-assistant.service"
        "protonvpn-portforward.service"
      ];
      description = "List of critical services to monitor for failures";
    };
  };

  config = mkIf cfg.enable {
    systemd.services = lib.mkMerge [
      # Failure notification service template
      {
        "notify-failure@" = {
          description = "Notify about failed %i";
          serviceConfig = {
            Type = "oneshot";
            ExecStart =
              if cfg.enableEmailNotifications then
                "${pkgs.writeShellScript "notify-failure-email" ''
                  #!/bin/sh
                  UNIT="$1"
                  HOSTNAME=$(${pkgs.nettools}/bin/hostname)

                  {
                    echo "Service $UNIT has failed on $HOSTNAME"
                    echo ""
                    echo "=== Service Status ==="
                    ${pkgs.systemd}/bin/systemctl status "$UNIT" --no-pager || true
                    echo ""
                    echo "=== Recent Logs ==="
                    ${pkgs.systemd}/bin/journalctl -u "$UNIT" -n 100 --no-pager || true
                  } | ${pkgs.mailutils}/bin/mail -s "[$HOSTNAME] Service $UNIT failed" ${cfg.notificationEmail}
                ''} %i"
              else
                "${pkgs.writeShellScript "notify-failure-log" ''
                  #!/bin/sh
                  UNIT="$1"
                  echo "========================================" >&2
                  echo "CRITICAL: Service $UNIT has failed" >&2
                  echo "========================================" >&2
                  ${pkgs.systemd}/bin/systemctl status "$UNIT" --no-pager || true
                  echo "========================================" >&2
                  echo "Recent logs for $UNIT:" >&2
                  ${pkgs.systemd}/bin/journalctl -u "$UNIT" -n 50 --no-pager || true
                  echo "========================================" >&2
                ''} %i";
            StandardOutput = "journal";
            StandardError = "journal";
            # Use journal priority for critical failures
            SyslogIdentifier = "service-failure-notification";
          };
        };
      }

      # Add OnFailure to critical services
      (lib.mkMerge (
        map (serviceName: {
          ${serviceName} = {
            unitConfig = {
              OnFailure = "notify-failure@%n.service";
            };
          };
        }) cfg.criticalServices
      ))
    ];
  };
}
