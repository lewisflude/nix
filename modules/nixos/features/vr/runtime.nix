# Monado OpenXR Runtime Configuration
{
  config,
  pkgs,
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

  # Required packages for OpenXR to work correctly
  environment.systemPackages = [
    pkgs.openxr-loader
    pkgs.vulkan-loader
    pkgs.libglvnd # Provides libGL
    pkgs.xorg.libX11
  ];
}
