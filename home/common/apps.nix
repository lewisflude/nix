{
  pkgs,
  lib,
  system,
  ...
}: let
  platformLib = import ../../lib/functions.nix {inherit lib system;};
in {
  home.packages = with pkgs;
    [
      claude-code
      pkgs.gemini-cli-bin
      pkgs.cursor-cli
      codex
      nx-latest
      coreutils
      delta
      htop
      btop
      libnotify
      pgcli
      rustup
      pkg-config
      openssl
      libsecret
      libiconv
      cmake
      gnumake
      git-lfs
      cachix
      nix-tree
      nix-du
      tree
      yaml-language-server
      zellij
    ]
    ++ platformLib.platformPackages
    [
      musescore
    ]
    [
      xcodebuild
      gnutar
      gzip
    ];
  imports = [
    ./apps/cursor
    ./apps/bat.nix
    ./apps/direnv.nix
    ./apps/fzf.nix
    ./apps/ripgrep.nix
    ./apps/helix.nix
    ./apps/obsidian.nix
    ./apps/aws.nix
    ./apps/docker.nix
    ./apps/atuin.nix
    ./apps/lazygit.nix
    ./apps/lazydocker.nix
    ./apps/micro.nix
    ./apps/eza.nix
    ./apps/jq.nix
    ./apps/zellij.nix
  ];
}
