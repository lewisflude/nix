{
  config,
  lib,
  ...
}:
let
  cfg = config.host.features.media.audio;
in
{
  config = lib.mkIf (cfg.enable or false) {
    # Disable USB autosuspend for Apogee Symphony Desktop
    # Audio interfaces should never be power-managed to avoid dropouts and connection issues
    # Vendor ID: 0c60 (Apogee Electronics Corp), Product ID: 002a (Symphony Desktop)
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0c60", ATTR{idProduct}=="002a", \
        TEST=="power/control", ATTR{power/control}="on"
    '';

    # Note: If you need automatic USB reset when switching via KVM, the full reset automation
    # is available in git history (commit before this simplification). For most users, manually
    # running `sudo systemctl --user restart pipewire` after KVM switch is sufficient.
  };
}
