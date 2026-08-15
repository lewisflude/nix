# CPU/hardware error surveillance and validation tooling - Dendritic Pattern
#
# rasdaemon has been recording since 2026-08-11 and nothing has ever read it.
# That gap cost real diagnostic time: the 2026-08-14 12:55 hang was investigated
# from scratch, and only then did `ras-mc-ctl --errors` reveal three corrected
# L2 cache MCEs already sitting in the database:
#
#   2026-08-11 10:54  Instruction CACHE Level-2 Instruction-Fetch Error, bank 15
#   2026-08-12 16:10  Data CACHE Level-2 Data-Read Error,               bank 15
#   2026-08-14 01:00  Data CACHE Level-2 Data-Read Error,               bank 15
#   2026-08-14 15:56  Instruction CACHE Level-2 Instruction-Fetch Error, bank 15
#
# The fourth was found while building this module and had gone unseen for a
# day — four events in four days, the last of them *after* the hang that
# prompted the investigation. That is precisely the trend this watches for.
#
# Each carries the kernel's own escalation text: "Large number of corrected
# cache errors. System operating, but might lead to uncorrected errors soon."
# On a 13th-gen i9 that trend is the signature worth watching — an accelerating
# corrected-error rate is the lead indicator for Raptor Lake Vmin-shift
# degradation, and the difference between "some kernel bug" and "this CPU is
# dying" changes what you do next.
#
# Why a polling timer rather than rasdaemon's own trigger mechanism:
# upstream's misc/rasdaemon.env defines exactly four hooks — MC_CE_TRIGGER,
# MC_UE_TRIGGER, AER_CE_TRIGGER, AER_UE_TRIGGER. Those cover EDAC memory
# controller events and PCIe AER. The errors above are `mce_record` events from
# a CPU bank, for which no trigger is documented. Independently, the nixpkgs
# rasdaemon module writes /etc/sysconfig/rasdaemon but its serviceConfig sets
# only StateDirectory/ExecStart/ExecStop/Restart — no EnvironmentFile — so the
# daemon never reads that file and `hardware.rasdaemon.config` is inert on
# NixOS regardless (worth an upstream issue; unused here, so no impact today).
# Polling the database it already maintains is therefore not a workaround for
# laziness, it is the only mechanism that covers CPU MCEs at all.
_: {
  flake.modules.nixos.hardwareErrors =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      environment.systemPackages = [
        # `sensors` was simply absent on this host, so package temperature and
        # thermal behaviour around a crash were unobservable. coretemp
        # autoloads on Intel; no sensors-detect run is needed for CPU zones.
        pkgs.lm_sensors

        # Stability validation. y-cruncher is the primary: the overclocking
        # community treats Prime95 small-FFT-with-AVX as an unrealistically
        # brutal test that cooks the part in ways unrepresentative of the
        # light-load conditions where Vmin shift actually bites, while
        # y-cruncher is repeatedly cited as exposing instability other suites
        # miss. mprime stays as a secondary opinion, not the first resort.
        # (OCCT and Linpack Xtreme, the other two the community leans on, have
        # no usable Linux packaging.)
        pkgs.y-cruncher
        pkgs.mprime
      ];

      # Everything below reads rasdaemon's database, so it is meaningless
      # without the daemon that fills it.
      systemd = lib.mkIf config.hardware.rasdaemon.enable {
        services.mce-watch = {
          description = "Report new machine check events recorded by rasdaemon";

          serviceConfig = {
            Type = "oneshot";
            StateDirectory = "mce-watch";
          };

          # `ras-mc-ctl --errors` rather than sqlite directly: it is the
          # supported read interface, it decodes bank/type into the text a
          # human can act on, and it keeps this independent of the database
          # schema.
          script = ''
            set -u
            state=/var/lib/mce-watch
            notify=${config.alerts.notify}/bin/system-alert

            errors="$(ras-mc-ctl --errors 2>/dev/null || true)"

            # The MCE section is a numbered list under an "MCE events:" header.
            # Stop at the next section header rather than reading to EOF, so
            # rows belonging to "Disk errors:" or any future section can never
            # be counted as machine checks.
            mce="$(printf '%s\n' "$errors" | awk '
              /^MCE events:/ { in_section = 1; next }
              in_section && /^[A-Za-z].*:[[:space:]]*$/ { in_section = 0 }
              in_section && /^[0-9]+[[:space:]]/ { print }
            ')"

            # printf of an empty string still emits one newline, so counting
            # unconditionally would report 1 event when there are none.
            count=0
            if [ -n "$mce" ]; then
              count="$(printf '%s\n' "$mce" | wc -l)"
            fi

            # First run adopts whatever is already recorded as the baseline.
            # The historical events are known and already acted on;
            # re-announcing them would train us to ignore this alert, which is
            # the failure mode that made the recording useless in the first
            # place. The count goes to the journal so the baseline is visible.
            if [ ! -r "$state/seen" ]; then
              echo "$count" > "$state/seen"
              echo "mce-watch: baseline set at $count recorded MCE events"
              exit 0
            fi

            seen="$(cat "$state/seen")"

            # A shrinking count means the database was reset or rotated.
            # Re-baseline instead of going permanently silent waiting to climb
            # back past a watermark that no longer corresponds to anything.
            if [ "$count" -lt "$seen" ]; then
              echo "$count" > "$state/seen"
              echo "mce-watch: event count fell from $seen to $count, database reset — re-baselined"
              exit 0
            fi

            if [ "$count" -eq "$seen" ]; then
              echo "mce-watch: no new MCE events ($count recorded)"
              exit 0
            fi

            new="$((count - seen))"

            # Watermark first: a delivery failure must not turn into the same
            # alert repeating on every timer tick forever.
            echo "$count" > "$state/seen"

            {
              echo "$new new machine check event(s) recorded since the last check."
              echo "Total recorded: $count"
              echo
              printf '%s\n' "$mce" | tail -n "$new"
              echo
              echo "Corrected errors are survivable in isolation; the rate is what matters."
              echo "An uncorrected error, or a cluster of corrected ones, is the point at"
              echo "which this stops being a curiosity. Full history:"
              echo "  ras-mc-ctl --errors"
            } | $notify -s "Jupiter: $new new machine check event(s)"
          '';

          path = [
            pkgs.coreutils
            pkgs.gawk
            config.hardware.rasdaemon.package
          ];

          # The watcher going down silently would restore exactly the blind
          # spot it exists to close.
          onFailure = [ "alert@%n.service" ];
        };

        timers.mce-watch = {
          description = "Periodically check rasdaemon for new machine check events";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            # Hourly, offset from boot. MCEs accumulate over days, so a tighter
            # interval buys nothing; the 15-minute offset keeps the first run
            # clear of the boot-time rush (and of Home Assistant still coming
            # up, which is what swallowed the 2026-08-14 crash report).
            OnBootSec = "15min";
            OnUnitActiveSec = "1h";
            Unit = "mce-watch.service";
          };
        };
      };
    };
}
