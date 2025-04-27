{ pkgs, lib, ... }: {
  home.stateVersion = "25.05";
  home.username = "lewisflude";
  home.homeDirectory = "/Users/lewisflude";

  imports =
    [ ./git.nix ./shell.nix ./apps.nix ./cursor.nix ./ssh.nix ./gpg.nix ];
  home.packages = with pkgs; [
    coreutils
    curl
    git
    htop
    jq
    ripgrep
    tree
    wget
    clang
    cmake
    pkg-config
    nixfmt-classic
  ];
  programs = { home-manager.enable = true; };

  home.sessionVariables = {
    EDITOR = "code";
    VISUAL = "code";
  };
}
