{
  pkgs,
  lib,
  system,
  ...
}: let
  platformLib = (import ../../../lib/functions.nix {inherit lib;}).withSystem system;
in {
  home.packages = with pkgs;
    [
      claude-code
      # pkgs.gemini-cli-bin # Package doesn't exist in nixpkgs
      # cursor.cursor-cli # cursorCli data missing from cursor-info.json
      codex
      nx-latest
    ]
    ++ [
      coreutils
      libnotify
      tree
    ]
    ++ [
      pgcli
    ]
    ++ [
      cachix
      nix-tree
      nix-du
      sops
    ]
    ++ [
      yaml-language-server
    ]
    ++ platformLib.platformPackages
    [
      musescore
    ]
    [
      xcodebuild
      gnutar
      gzip
    ];

  programs.htop.enable = true;
  programs.btop.enable = true;
}
