{
  pkgs,
  lib,
  system,
  ...
}:
let
  helpers = import ./_helpers.nix { inherit lib system; };
  inherit (helpers) platformLib getNxPackage;
  nx = getNxPackage pkgs;
in
{
  home.packages =
    with pkgs;
    [
      curl
      wget
      # Note: yq is handled via programs.yq in home/common/apps/yq.nix

      coreutils

      libnotify
      tree

      # Note: cachix is handled via programs.cachix in home/common/apps/cachix.nix
      nix-tree
      nix-du
      nix-update
      nix-prefetch-github
      nvfetcher
      nix-output-monitor
    ]
    ++ lib.optional (nx != null) nx
    ++ [
      yaml-language-server
    ]
    ++
      platformLib.platformPackages
        [
          xdg-utils
        ]
        [
          # Linux packages
          xcodebuild
        ] # Darwin packages
    ++ [
      gnutar
      gzip
    ];
}
