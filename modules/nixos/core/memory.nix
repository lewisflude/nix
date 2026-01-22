# Memory Management
# Conservative defaults - disk-performance.nix overrides these when enabled
{ lib, ... }:
{
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
    # Optimal swappiness for zram (in-memory swap is orders of magnitude faster than disk)
    # Based on Arch Wiki: https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
    # For zram: 180-200 is ideal since random I/O is vastly faster than filesystem
    # disk-performance.nix will override this to 10 for systems without zram
    "vm.swappiness" = lib.mkDefault 180;

    # Watermark tuning for zram (from Pop!_OS defaults)
    "vm.watermark_boost_factor" = lib.mkDefault 0;
    "vm.watermark_scale_factor" = lib.mkDefault 125;

    # Page clustering: 0 is optimal for zram (no benefit from reading adjacent pages)
    "vm.page-cluster" = 0;

    # Dirty page handling
    "vm.dirty_background_ratio" = lib.mkDefault 5;
    "vm.dirty_ratio" = lib.mkDefault 20;

    # Inotify watches
    "fs.inotify.max_user_watches" = 1048576;
  };
}
