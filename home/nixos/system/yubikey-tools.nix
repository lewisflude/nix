{pkgs, ...}: {
  home.packages = with pkgs; [
    yubikey-manager
    yubioath-flutter
    pcsctools
  ];
}
