{ pkgs, ... }:
{
  # PC/SC daemon for smartcard support (required for YubiKey)
  services.pcscd.enable = true;

  # udev rules for YubiKey device access
  services.udev.packages = [ pkgs.yubikey-personalization ];

  # Enable GPG smartcard support
  hardware.gpgSmartcards.enable = true;

  # YubiKey touch detector: Visual notifications when YubiKey needs touch
  # Provides desktop notifications (via libnotify) when YubiKey awaits physical touch
  programs.yubikey-touch-detector = {
    enable = true;
    libnotify = true;  # Desktop notifications on Linux
  };
}
