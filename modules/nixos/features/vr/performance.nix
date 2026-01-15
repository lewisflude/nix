# VR Performance Optimizations
# Note: vm.swappiness is handled by disk-performance.nix (mkOverride 40)
{
  config,
  lib,
  ...
}:
let
  cfg = config.host.features.vr;
in
lib.mkIf (cfg.enable && cfg.performance) {
  # NVIDIA-specific: Force GPU-accelerated XWayland for VR overlays
  environment.sessionVariables = lib.mkIf config.hardware.nvidia.modesetting.enable {
    XWAYLAND_NO_GLAMOR = "0";
  };

  # Note: fs.inotify.max_user_watches (1048576) is set in memory.nix
  # Note: vm.swappiness (10) is set in disk-performance.nix
}
