{ pkgs, lib, ... }: {
  home.stateVersion = "25.05";
  home.username = "lewisflude";
  home.homeDirectory = "/Users/lewisflude";

  imports =
    [ ./git.nix ./shell.nix ./apps.nix ./cursor.nix ./ssh.nix ./gpg.nix ];

  programs = { home-manager.enable = true; };

  home.sessionVariables = {
    EDITOR = "code";
    VISUAL = "code";
  };
}
