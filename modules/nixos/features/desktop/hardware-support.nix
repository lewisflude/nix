{
  config,
  lib,
  ...
}:
let
  cfg = config.host.features.desktop;
in
{
  config = lib.mkIf cfg.enable {
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
