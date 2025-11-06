{
  pkgs,
  lib,
  system,
  ...
}: let
  helpers = import ./_helpers.nix {inherit lib pkgs system;};
  inherit (helpers) platformLib getNxPackage;
  nx = getNxPackage pkgs;
in {
  home.packages = with pkgs;
    [
      claude-code
      codex
      coreutils
      libnotify
      tree
      pgcli
      cachix
      nix-tree
      nix-du
      sops
      yaml-language-server
      musescore
      gnutar
      gzip
    ]
    ++ lib.optional (nx != null) nx
    ++ platformLib.platformPackages
    [] # Linux packages

    [
      xcodebuild
    ]; # Darwin packages

  programs.htop.enable = true;
  programs.btop.enable = true;
}
