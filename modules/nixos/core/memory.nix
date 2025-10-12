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
    ];
  };
  boot.kernel.sysctl = {
    "vm.swappiness" = lib.mkForce 60;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 20;
    "vm.max_map_count" = 262144;
    "vm.page-cluster" = 0;
    "fs.inotify.max_user_watches" = 1048576;
  };
}
