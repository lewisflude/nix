{
  pkgs,
  lib,
  system,
  ...
}: let
  platformLib = import ../../../lib/functions.nix {inherit lib system;};
in {
  home.packages = with pkgs;
  # Core development tools
    [
      claude-code
      pkgs.gemini-cli-bin
      pkgs.cursor-cli
      codex
      nx-latest
    ]
    # System utilities
    ++ [
      coreutils
      delta
      htop
      btop
      libnotify
      tree
    ]
    # Development libraries and tools
    ++ [
      rustup
      pkg-config
      openssl
      libsecret
      libiconv
      cmake
      gnumake
    ]
    # Database tools
    ++ [
      pgcli
    ]
    # Nix tools
    ++ [
      cachix
      nix-tree
      nix-du
      sops
    ]
    # Language servers
    ++ [
      yaml-language-server
    ]
    # Terminal tools
    ++ [
      git-lfs
      zellij
    ]
    # Platform-specific packages
    ++ platformLib.platformPackages
    # Linux-specific
    [
      musescore
    ]
    # Darwin-specific
    [
      xcodebuild
      gnutar
      gzip
    ];
}
