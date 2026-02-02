# Hardware Support Configuration
# Thunderbolt, backlight control, geolocation services
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.features.desktop;
  isLinux = pkgs.stdenv.isLinux;
in
{
  config = lib.mkIf (cfg.enable && isLinux) {
    services = {
      udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", GROUP="video", MODE="0664"
      '';
      geoclue2.enable = true;

      # Thunderbolt device management (required for Apogee Symphony Desktop)
      # bolt provides authorization and management for Thunderbolt 3+ devices
      hardware.bolt.enable = true;
    };
  };
}
