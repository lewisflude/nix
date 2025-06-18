{ pkgs, ... }:
{
  # Enable Touch ID for sudo (nix-darwin only supports sudo_local PAM service)
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    watchIdAuth = true;
  };

  # Add YubiKey tools
  environment.systemPackages = with pkgs; [
    yubikey-personalization
    yubico-pam
    yubikey-manager
  ];
}
