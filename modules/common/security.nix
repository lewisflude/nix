{ pkgs, ... }:
{

  # Add YubiKey tools
  environment.systemPackages = with pkgs; [
    yubikey-personalization
    yubico-pam
    yubikey-manager
  ];

}
