# Hardware Support Configuration
# Thunderbolt, backlight control, geolocation services
_:
{
  flake.modules.nixos.hardwareSupport =
    _:
    {
      services = {
        udev.extraRules = ''
          ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", GROUP="video", MODE="0664"
        '';
        geoclue2.enable = true;
        hardware.bolt.enable = true;
      };
    };
}
