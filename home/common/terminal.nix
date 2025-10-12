{
  pkgs,
  lib,
  system,
  ...
}: let
  platformLib = import ../../lib/functions.nix {inherit lib system;};
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
      initial-command = "zellij attach -c default";
      keybind = ["shift+enter=text:\n"];
    };
  };
}
