{
  pkgs,
  lib,
  ...
}:
{
  home.packages = [
    pkgs.cacert # Provides SSL certificates for tools like curl
    pkgs.curl
    pkgs.wget
    # Note: yq is handled via programs.yq in home/common/apps/yq.nix

    pkgs.coreutils

    pkgs.libnotify
    pkgs.tree

    # Note: cachix is handled via programs.cachix in home/common/apps/cachix.nix
    # Nix development and analysis tools
    pkgs.nix-tree # Interactive dependency graph browser
    pkgs.nix-du # Visualize gc-roots and disk usage
    pkgs.nix-update # Update package versions
    pkgs.nix-prefetch-github # Prefetch GitHub sources (legacy - use nurl instead)
    pkgs.nvfetcher # Auto-update tool
    pkgs.nix-output-monitor # Better nix build output (used by nh)

    # New: Modern Nix development tools
    pkgs.nix-init # Generate Nix packages from URLs (replaces manual derivation writing)
    pkgs.nurl # Generate fetcher calls from repo URLs (modern alternative to nix-prefetch-*)
    pkgs.nix-diff # Explain why two derivations differ (useful for debugging rebuilds)
    pkgs.comma # Instantly run any command without installing (, command-name)

    # Git workflow tools
    pkgs.cocogitto # Conventional commits linting and versioning
    # Note: git-cliff is configured via programs.git-cliff in home/common/apps/git-cliff.nix

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
