{
  pkgs,
  lib,
  system,
  ...
}: let
  platformLib = (import ../../lib/functions.nix {inherit lib;}).withSystem system;
in {
  home.packages = with pkgs;
    [
      clipse
      wget
      curl
      comma
      devenv
      eza
      rsync
      trash-cli
      fd
      dust
      procs
      gping
      tldr
      p7zip
      pigz
      jq
      git-extras
    ]
    ++ platformLib.platformPackages
    [
      networkmanager
      lsof
      wtype
    ]
    [
    ];
  programs.ghostty = {
    enable = true;
    package = platformLib.platformPackage pkgs.ghostty pkgs.ghostty-bin;
    enableZshIntegration = true;
    settings = {
      font-family = "Iosevka Nerd Font";
      font-feature = "+calt,+liga,+dlig";
      font-size = 12;
      font-synthetic-style = true;
      scrollback-limit = 100000;
      # Removed initial-command to prevent session proliferation
      # Use 'zj' command or direnv layout_zellij instead
      keybind = ["shift+enter=text:\n"];
    };
  };
}
