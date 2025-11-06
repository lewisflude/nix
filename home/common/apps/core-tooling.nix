{
  pkgs,
  lib,
  system,
  inputs,
  ...
}:
let
  platformLib = (import ../../../lib/functions.nix { inherit lib; }).withSystem system;
in
{
  home.packages =
    with pkgs;
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
    ++
      lib.optionals
        (
          inputs ? flakehub
          && inputs.flakehub ? packages
          && inputs.flakehub.packages ? ${system}
          && inputs.flakehub.packages.${system} ? default
        )
        [
          inputs.flakehub.packages.${system}.default
        ]
    ++ [

      claude-code
      pkgs.gemini-cli-bin
      pkgs.cursor-cli
      codex
      nx-latest

      yaml-language-server
    ]
    ++
      platformLib.platformPackages
        [

          xdg-utils
        ]
        [
          xcodebuild
          gnutar
          gzip
        ];
}
