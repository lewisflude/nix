# Shell Feature Module - Main Entry Point
# Consolidated ZSH configuration
{
  pkgs,
  config,
  systemConfig,
  system,
  hostSystem,
  lib,
  inputs,
  ...
}:
let
  sources = import ../../../_sources/generated.nix {
    inherit (pkgs) fetchgit;
  };

  shellHelpers = import ../../../lib/shell-helpers.nix {
    inherit lib config inputs;
  };
in
{
  imports = [
    (import ./zsh.nix {
      inherit
        config
        lib
        pkgs
        hostSystem
        ;
    })
    (import ./zsh-init.nix {
      inherit
        config
        pkgs
        lib
        systemConfig
        sources
        shellHelpers
        ;
    })
    (import ./zsh-keybindings.nix {
      inherit config lib;
    })
  ];
}
