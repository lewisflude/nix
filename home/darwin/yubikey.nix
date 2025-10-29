{pkgs, ...}: {
  home.packages = with pkgs; [
    terminal-notifier
    yubikey-manager
    pcsctools
  ];
}
