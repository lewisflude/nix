{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    yubikey-manager
    yubioath-flutter
  ];

  services.pcscd.enable = true;
  services.udev.packages = [pkgs.yubikey-personalization];
  hardware.gpgSmartcards.enable = true;
}
