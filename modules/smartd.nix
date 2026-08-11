# SMART disk monitoring - Dendritic Pattern
#
# Continuous SMART attribute monitoring plus scheduled self-tests for every
# physical disk in the machine.
#
# This exists because a 2026-08-11 audit found no disk monitoring of any kind:
# smartmontools was not even installed, so the first warning of a dying drive
# would have been the drive dying. That matters more here than on a typical
# box for two reasons. npool is a four-device stripe with no redundancy, so any
# single failure takes / and /home with it. And /mnt/disk1 + /mnt/disk2 are XFS
# — no checksums, no scrub — so a scheduled SMART self-test is the *only*
# proactive read verification those two 14 TB drives ever get.
_: {
  flake.modules.nixos.smartd =
    {
      pkgs,
      config,
      ...
    }:
    {
      environment.systemPackages = [ pkgs.smartmontools ];

      services.smartd = {
        enable = true;

        # Devices are listed explicitly rather than autodetected so that a
        # drive silently dropping off the bus is a config mismatch we notice,
        # not a device that quietly stops being monitored.
        autodetect = false;

        # Self-test schedules are staggered so the six drives never contend:
        # short tests nightly, long tests spread across the week. A long test
        # on a 14 TB spinner takes many hours, hence one drive per night rather
        # than both at once.
        #   -a           : monitor all the usual attributes
        #   -o on        : SMART automatic offline data collection (ATA only)
        #   S/../.././HH : short self-test daily at HH:00
        #   L/../../D/HH : long self-test on weekday D at HH:00
        devices = [
          # ── npool vdevs (striped, no redundancy — any loss is pool loss) ──
          {
            device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_1TB_S5GXNG0NB00935H";
            options = "-a -s (S/../.././01|L/../../2/03)";
          }
          {
            device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S6Z2NJ0TB29917B";
            options = "-a -s (S/../.././01|L/../../3/03)";
          }
          {
            device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_2TB_S6Z2NJ0TB29832Z";
            options = "-a -s (S/../.././01|L/../../4/03)";
          }
          {
            device = "/dev/disk/by-id/ata-WDC_WDS200T2B0B-00YS70_20174F801341";
            options = "-a -o on -s (S/../.././02|L/../../5/03)";
          }

          # ── mergerfs branches (XFS: no checksums, no scrub, ~38k hours) ──
          # These two get the most value from long tests: nothing else on this
          # system ever verifies that their platters still read back.
          {
            device = "/dev/disk/by-id/ata-WDC_WD140EDFZ-11A0VA0_9LGED2YG";
            options = "-a -o on -s (S/../.././02|L/../../6/04)";
          }
          {
            device = "/dev/disk/by-id/ata-WDC_WD140EDFZ-11A0VA0_Y5JTWKLC";
            options = "-a -o on -s (S/../.././02|L/../../7/04)";
          }
        ];

        notifications = {
          # "mail" is a misnomer here: the mailer is the alerts fan-out from
          # modules/alerts.nix, which pushes to Home Assistant and forwards to
          # a real MTA if one is ever installed. See that module for why this
          # is shaped like sendmail.
          mail = {
            enable = true;
            mailer = "${config.alerts.notify}/bin/system-alert";
            recipient = "root";
            sender = "smartd@jupiter";
          };

          # Backstop for when nothing is watching the journal or Home
          # Assistant and someone is sitting at a tty.
          #
          # Deliberately no systembus-notify: it would be a third copy of the
          # same message, visible only while logged into the desktop, and its
          # enable flag collides with earlyoom's (two disagreeing plain bools
          # are an eval error, resolvable only with mkForce). Dropping the
          # channel removes both the redundancy and the conflict.
          wall.enable = true;
        };
      };
    };
}
