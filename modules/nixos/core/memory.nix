{ lib, ... }:
{
  # ZFS ARC memory limit
  # NOTE: This is now managed by modules/nixos/system/disk-performance.nix
  # when system.diskPerformance.enable = true
  # The disk-performance module sets ARC to 48GB (75% of 64GB RAM) for better performance
  # boot.kernelParams = [ "zfs.zfs_arc_max=25769803776" ]; # 24GB in bytes (DISABLED)

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };
  services.fstrim.enable = true;
  services.earlyoom = {
    enable = true;
    freeSwapThreshold = 5;
    freeMemThreshold = 10;
    freeMemKillThreshold = 2;
    freeSwapKillThreshold = 5;
    reportInterval = 0;
    extraArgs = [
      "--avoid"
      "^(niri|wireplumber|pipewire|Xwayland|gdm|sddm)$"
      "--prefer"
      "^(chromium|chrome)"
    ];
  };
  boot.kernel.sysctl = {

    "vm.swappiness" = lib.mkDefault 100;

    "vm.watermark_scale_factor" = 75;

    "vm.dirty_background_ratio" = lib.mkDefault 5;
    "vm.dirty_ratio" = lib.mkDefault 20;

    "vm.page-cluster" = 0;

    "fs.inotify.max_user_watches" = 1048576;
  };
}
