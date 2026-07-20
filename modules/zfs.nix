# ZFS Service Module - Dendritic Pattern
# ZFS filesystem management with auto-snapshot and scrub
_: {
  flake.modules.nixos.zfs =
    { pkgs, lib, ... }:
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
      };

      environment.systemPackages = [ pkgs.zfs ];
    };
}
