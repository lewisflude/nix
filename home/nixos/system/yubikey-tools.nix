{pkgs, ...}: {
  home.packages = with pkgs; [
    yubikey-manager
    yubioath-flutter
    pcsc-tools
  ];
}
