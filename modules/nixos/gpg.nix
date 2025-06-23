{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    gnupg
    pinentry
    pinentry-curses
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "curses";
  };
}
