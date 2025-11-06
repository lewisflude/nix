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
    enable = platformLib.isLinux;
    package = pkgs.ghostty;
    enableZshIntegration = true;
    settings = {
      font-family = "Iosevka Nerd Font";
      font-feature = "+calt,+liga,+dlig";
      font-size = 12;
      font-synthetic-style = true;
      scrollback-limit = 100000;

      keybind = ["shift+enter=text:\n"];
    };
  };
}
