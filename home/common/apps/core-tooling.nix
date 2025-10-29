{
  pkgs,
  lib,
  system,
  inputs,
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
      yq
      git-lfs

      # Monitoring & utilities
      coreutils
      delta
      # htop and btop configured via programs.* in packages.nix
      libnotify
      tree

      # Nix tooling
      cachix
      nix-tree
      nix-du
      inputs.flakehub.packages.${system}.default

      # Development helpers
      rustup
      pkg-config
      openssl
      libsecret
      libiconv
      cmake
      gnumake

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
      # musescore moved to packages.nix to avoid duplication
      xdg-utils
    ]
    [
      xcodebuild
      gnutar
      gzip
    ];
}
