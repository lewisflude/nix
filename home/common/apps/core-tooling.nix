{
  pkgs,
  lib,
  ...
}:
{
  home.packages = [
    pkgs.nix-cacert # Provides SSL certificates for tools like curl
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

    pkgs.yaml-language-server
  ]
  # Linux-only packages
  ++ lib.optionals pkgs.stdenv.isLinux [
    pkgs.xdg-utils
  ]
  ++ [
    pkgs.gnutar
    pkgs.gzip
    pkgs.ouch # Modern compression/decompression tool (Rust-based)
  ];
}
