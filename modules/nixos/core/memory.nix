{lib, ...}: {
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
      "^(chromium|chrome|firefox)"
    ];
  };
  boot.kernel.sysctl = {
    # Swappiness for zram usage (kernel caps at 100, but zram benefits from aggressive swapping)
    # With 50% zram allocation, value of 100 is appropriate
    "vm.swappiness" = lib.mkForce 100;

    # Memory reclamation aggressiveness (default: 10, max practical: ~500)
    # Reduced from 125 to 75 - less aggressive reclaim means less CPU overhead
    # Increase if you experience OOM issues
    "vm.watermark_scale_factor" = 75;

    # Write cache settings (good defaults for desktop)
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 20;

    # Memory map count for gaming (some games need higher limits)
    "vm.max_map_count" = lib.mkDefault 262144;

    # Disable swap clustering for zram (correct for compressed swap)
    "vm.page-cluster" = 0;

    # File watches for development (IDEs, build tools)
    "fs.inotify.max_user_watches" = 1048576;
  };
}
