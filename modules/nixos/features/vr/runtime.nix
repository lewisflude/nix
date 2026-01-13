# Monado OpenXR Runtime Configuration
{
  config,
  lib,
  ...
}:
let
  cfg = config.host.features.vr;
in
lib.mkIf cfg.enable {
  # Enable Monado OpenXR runtime
  # Monado is the native open-source OpenXR runtime for Linux
  # It provides VR/AR support on Wayland with excellent performance
  services.monado = lib.mkIf cfg.monado {
    enable = true;
    defaultRuntime = !cfg.wivrn.enable || !cfg.wivrn.defaultRuntime;
    highPriority = cfg.performance; # Enable high priority for better frame timing
  };
}
