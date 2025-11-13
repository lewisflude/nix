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
    [
      pkgs.curl
      pkgs.wget
      # Note: yq is handled via programs.yq in home/common/apps/yq.nix

      pkgs.coreutils

      pkgs.libnotify
      pkgs.tree

      # Note: cachix is handled via programs.cachix in home/common/apps/cachix.nix
      pkgs.nix-tree
      pkgs.nix-du
      pkgs.nix-update
      pkgs.nix-prefetch-github
      pkgs.nvfetcher
      pkgs.nix-output-monitor
    ]
    ++ lib.optional (nx != null) nx
    ++ [
      pkgs.yaml-language-server
    ]
    ++
      platformLib.platformPackages
        [
          pkgs.xdg-utils
        ]
        [
          # Linux packages
          pkgs.xcodebuild
        ] # Darwin packages
    ++ [
      pkgs.gnutar
      pkgs.gzip
    ];
}
