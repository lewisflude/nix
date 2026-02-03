# Hardware Support Configuration
# Thunderbolt, backlight control, geolocation services
{ config, ... }:
{
  flake.modules.nixos.hardwareSupport = { pkgs, lib, ... }: {
    services = {
      udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", GROUP="video", MODE="0664"
      '';
      geoclue2.enable = true;
      hardware.bolt.enable = true;
    };
  };
}
