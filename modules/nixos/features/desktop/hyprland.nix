{
  config,
  lib,
  ...
}: let
  cfg = config.host.features.desktop;
in {
  config = lib.mkIf cfg.enable {
    services = {
      udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", GROUP="video", MODE="0664"
      '';
      geoclue2.enable = true;
    };
  };
}
