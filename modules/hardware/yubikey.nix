# YubiKey hardware support
{ config, ... }:
{
  flake.modules.nixos.yubikey = { pkgs, lib, ... }: {
    # PC/SC daemon for smartcard support (required for YubiKey)
    services.pcscd.enable = true;

    # udev rules for YubiKey device access
    services.udev.packages = [ pkgs.yubikey-personalization ];

    # Enable GPG smartcard support
    hardware.gpgSmartcards.enable = true;

    # YubiKey touch detector: Visual notifications when YubiKey needs touch
    programs.yubikey-touch-detector = {
      enable = true;
      libnotify = true;
    };
  };
}
