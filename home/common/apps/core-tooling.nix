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
      # Core CLI tooling
      git
      gh
      curl
      wget
      jq
      yq
      git-lfs

      # Monitoring & utilities
      coreutils
      delta
      htop
      btop
      libnotify
      tree

      # Nix tooling
      cachix
      nix-tree
      nix-du

      # Development helpers
      rustup
      pkg-config
      openssl
      libsecret
      libiconv
      cmake
      gnumake
      zellij

      # AI / workflow helpers
      claude-code
      pkgs.gemini-cli-bin
      pkgs.cursor-cli
      codex
      nx-latest

      # Language servers
      yaml-language-server
    ]
    ++ platformLib.platformPackages
    [
      musescore
      xdg-utils
    ]
    [
      xcodebuild
      gnutar
      gzip
    ];
}
