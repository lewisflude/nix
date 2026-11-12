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
      # Pin to an LTS kernel. ZFS is an out-of-tree module, so the rootfs
      # depends on it building AND behaving against whatever kernel we run, and
      # nixpkgs' default floats. The NixOS ZFS wiki recommends an LTS kernel and
      # an explicit pin over computing "latest ZFS-compatible" (which silently
      # walks backwards as kernels go EOL).
      #
      # Back to 6.12 on 2026-09-11. This pin was moved to 6.18 on the theory
      # that `kernel BUG at fs/namei.c:844` (via try_to_unlazy, in the RCU
      # path-walk fast path) was ZFS 2.4.3's fault and so "expired" with the
      # move to the 2.3 branch below. That theory is wrong. Every pstore dump
      # on Jupiter carrying that signature -- 11 of them, 2026-06-29 through
      # 2026-09-11 -- is on 6.18.x (.33, .36, .45), and the last two (08-24 and
      # 09-11) are on 2.3.8, not 2.4.3. Zero occurrences on 6.12. The common
      # factor is the kernel, not the ZFS version.
      #
      # The 09-11 panic hit mid-rsync and cost real data: the box went down
      # unclean, XFS replayed metadata but not the unflushed page cache, and
      # the tail of a 53 GB transfer to /mnt/storage came back as 0-byte files
      # plus one clip truncated 170 MB short -- after rsync had exited 0.
      #
      # Going back costs ntsync (6.14, Proton/Wine) and FUSE-over-io_uring for
      # the mergerfs pool. Worth it: 6.12 is LTS with the same projected EOL
      # (Dec 2028) and is inside zfs_2_3's declared support window. Do NOT
      # return to 6.18 without evidence the namei BUG is fixed upstream.
      #
      # mkDefault so a host can override; bump deliberately, never with `switch`
      # -- stage with `nh os boot` so the old generation stays bootable.
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

    };
}
