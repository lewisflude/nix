{
  pkgs,
  lib,
  system,
  ...
}: let
  platformLib = (import ../../../lib/functions.nix {inherit lib;}).withSystem system;
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
      libnotify
      tree
    ]
    # Development libraries and tools
    ++ [
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

  # programs.rustup.enable = true; # Not available in home-manager
  programs.htop.enable = true;
  programs.btop.enable = true;
}
