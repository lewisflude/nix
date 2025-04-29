{
  pkgs,
  lib,
  catppuccin,
  ...
}: {
  home.stateVersion = "25.05";
  home.username = "lewisflude";
  home.homeDirectory = "/Users/lewisflude";

  imports = [
    ./git.nix
    ./shell.nix
    ./apps.nix
    ./ssh.nix
    ./gpg.nix
    ./theme.nix
    ./terminal.nix
    catppuccin.homeModules.catppuccin
  ];
  programs = {home-manager.enable = true;};

  home.sessionVariables = {
    EDITOR = "code";
    VISUAL = "code";
  };
}
