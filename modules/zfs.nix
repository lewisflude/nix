# ZFS Service Module - Dendritic Pattern
# ZFS filesystem management with auto-snapshot and scrub
_: {
  flake.modules.nixos.zfs =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      boot.zfs = {
        extraPools = [ "npool" ];
        devNodes = "/dev/disk/by-id";
      };

      # Pin to the 6.12 LTS kernel. ZFS is an out-of-tree module, so the rootfs
      # depends on it building AND behaving against whatever kernel we run.
      # nixpkgs' default kernel floats to bleeding edge (6.18.x), and on
      # 2026-07-18 that crashed the box: a stat() on ZFS hit `kernel BUG at
      # fs/namei.c:844` via zfs_getattr_fast/try_to_unlazy — ZFS 2.4.3 tripping
      # on 6.18's new RCU-walk VFS internals. nixpkgs' compile-time gate (and
      # `latestCompatibleLinuxPackages`) considered 6.18 "compatible", so only an
      # explicit LTS pin holds us on a kernel ZFS is actually battle-tested on.
      # mkDefault so a host can override; bump deliberately when 6.12 nears EOL.
      boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_6_12;

      # Pin ZFS to the 2.3 LTS series. nixpkgs' default `pkgs.zfs` floats to
      # 2.4.x, and 2.4.3 hard-crashed Jupiter three times in three days with
      # three *different* NULL-deref/Oops signatures: block_cloning
      # (zfs_bclone_enabled), zfs_getattr_fast/try_to_unlazy, and on 2026-07-21
      # dsl_bookmark_block_killed in the txg sync/free path (dp_sync_taskq died
      # with irqs disabled, wedging the pool until a hard reboot). Common
      # denominator is 2.4.3, not the kernel — the last crash was on this pinned
      # 6.12. 2.3.8 is battle-tested and imports npool read-write: every *active*
      # pool feature is supported by 2.3, and all 2.4-only features are merely
      # enabled/disabled, never active. Do NOT run `zpool upgrade` while pinned
      # here. Revisit once 2.4.x has proven stable upstream.
      boot.zfs.package = lib.mkDefault pkgs.zfs_2_3;

      # Keep block cloning off — explicitly, not by trusting the default.
      # On 2026-07-18 the bclone crash above was "fixed" by deleting the
      # `zfs_bclone_enabled=1` line and relying on the default being 0. That
      # held on 2.4.3, but the 2.3 pin three days later moved us to 2.3.8,
      # where the default is 1 — so block cloning came back on silently and
      # ran that way until 2026-08-22, when a live read of
      # /sys/module/zfs/parameters/zfs_bclone_enabled showed 1. A default is
      # not a setting; pin it.
      #
      # It is still worth pinning off on 2.3.8 specifically: zfs-2.3.9
      # (2026-08-21) carries "Fix reads for blocks freed after being cloned"
      # (openzfs PR #18421, #18724), where such reads return wrong content.
      # nixpkgs is still on 2.3.8, so we are running with that bug live.
      # Revisit once zfs_2_3 >= 2.3.9 is in nixpkgs.
      #
      # kernelParams, NOT boot.extraModprobeConfig: `/` is npool/root, so zfs
      # loads in the initrd, before the final system's /etc/modprobe.d exists.
      # systemd-initrd does copy modprobe.d/nixos.conf in, so modprobe config
      # happens to work today — but only while boot.initrd.systemd.enable is
      # true, and a silently-reverted bclone setting is exactly the failure we
      # are fixing. The kernel command line applies at module load either way.
      # This is also the form the NixOS ZFS wiki uses (`zfs.zfs_arc_max=...`).
      boot.kernelParams = [ "zfs.zfs_bclone_enabled=0" ];

      # Auto-recover from a wedged kernel thread instead of hanging indefinitely.
      # On 2026-06-21 a `zfs list` (run by the frequent auto-snapshot timer) hit an
      # OpenZFS spl_panic in fnvlist_pack; the thread died holding ZFS locks, txg_sync
      # and others blocked 491s+, and the box stayed frozen ~28h until a manual reboot.
      # Panic (and reboot) on a task hung > 300s so a recurrence self-recovers in minutes.
      # NOTE: 300s (not the 120s default) tolerates transient I/O stalls; if a disk's
      # SATA link is flaky this could still trigger an unwanted reboot.
      boot.kernel.sysctl = {
        "kernel.hung_task_timeout_secs" = 300;
        "kernel.hung_task_panic" = 1;
        "kernel.panic" = 30;
      };

      services.zfs = {
        autoSnapshot = {
          enable = true;
          frequent = 4;
          hourly = 24;
          daily = 7;
          weekly = 4;
          monthly = 12;
        };
        trim = {
          enable = true;
          interval = "weekly";
        };
        autoScrub = {
          enable = true;
          interval = "monthly";
          pools = [ "npool" ];
        };

        # ZED watches pool events (checksum errors, device faults, degraded
        # vdevs, finished scrubs) and, until now, told nobody about them — the
        # monthly scrub's result only existed in `zpool status` until someone
        # thought to look. npool has no redundancy, so a checksum error is not
        # a "ZFS will heal it" event; it is data already lost, and the sooner
        # it is known the better.
        #
        # enableMail is deliberately left off: it asserts on
        # services.mail.sendmailSetuidWrapper, and no MTA is installed here.
        # Setting the ZED_EMAIL_* variables directly points ZED at the alerts
        # fan-out instead, which reaches Home Assistant and the journal.
        zed.settings = {
          ZED_EMAIL_ADDR = [ "root" ];
          ZED_EMAIL_PROG = "${config.alerts.notify}/bin/system-alert";
          ZED_EMAIL_OPTS = "-s '@SUBJECT@' @ADDRESS@";

          # Report successful scrubs too, not just failures. A scrub that
          # stops running is itself a problem, and silence cannot distinguish
          # "healthy" from "the timer died three months ago".
          ZED_NOTIFY_VERBOSE = true;
        };
      };

      # Match the userland CLI to the pinned kernel module (2.3.8), not the
      # nixpkgs default (2.4.x), so `zfs`/`zpool` never mismatch the module.
      environment.systemPackages = [ config.boot.zfs.package ];
    };
}
