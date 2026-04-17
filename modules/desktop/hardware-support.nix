# Hardware Support Configuration
# Thunderbolt, backlight, geolocation, color management, USB, power, OOM prevention
_: {
  flake.modules.nixos.hardwareSupport = _: {
    services = {
      udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="*", GROUP="video", MODE="0664"
      '';
      colord.enable = true;
      earlyoom.enable = true;
      geoclue2.enable = true;
      gvfs.enable = true;
      hardware.bolt.enable = true;
      power-profiles-daemon.enable = true;
      tumbler.enable = true;
      udisks2.enable = true;
    };
  };
}
