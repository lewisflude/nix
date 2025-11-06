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
      git
      gh
      curl
      wget
      yq
      git-lfs

      coreutils
      delta

      libnotify
      tree

      cachix
      nix-tree
      nix-du
      nix-update
      nix-prefetch-github
      nvfetcher
      nix-output-monitor
    ]
    ++ [
      claude-code
      codex
    ]
    ++ lib.optional (nx != null) nx
    ++ [
      yaml-language-server
    ]
    ++ platformLib.platformPackages
    [
      xdg-utils
    ] # Linux packages

    [
      xcodebuild
    ] # Darwin packages
    ++ [
      gnutar
      gzip
    ];
}
