# VR Performance Optimizations Configuration
{
  config,
  lib,
  ...
}:
let
  cfg = config.host.features.vr;
in
lib.mkIf (cfg.enable && cfg.performance) {
  # VR performance optimizations
  # NVIDIA-specific VR optimizations
  environment.sessionVariables = lib.mkIf config.hardware.nvidia.modesetting.enable {
    # Force GPU-accelerated XWayland for better VR performance
    # This ensures VR overlays and desktop views render efficiently
    XWAYLAND_NO_GLAMOR = "0";
  };

  # System-level optimizations for VR workloads
  boot.kernel.sysctl = {
    # Note: fs.inotify.max_user_watches is already set to 1048576 in memory.nix
    # which is sufficient for VR applications

    # Reduce swappiness for better real-time performance
    # VR requires consistent frame timing and should avoid swap
    "vm.swappiness" = 10;
  };
}
