# Shell Feature Module - Main Entry Point
# Consolidated ZSH configuration
# Dendritic pattern: Uses osConfig instead of systemConfig, pkgs.stdenv for system
{
  pkgs,
  config,
  osConfig ? {},
  lib,
  ...
}:
let
  sources = import ../../../_sources/generated.nix {
    inherit (pkgs) fetchgit;
  };

  shellHelpers = import ../../../lib/shell-helpers.nix {
    inherit lib config;
  };
in
{
  imports = [
    # zsh.nix uses pkgs.stdenv.isLinux for platform detection
    (import ./zsh.nix {
      inherit
        config
        lib
        pkgs
        ;
    })
    (import ./zsh-init.nix {
      inherit
        config
        pkgs
        lib
        sources
        shellHelpers
        ;
      # Pass osConfig as systemConfig for backwards compatibility
      systemConfig = osConfig;
    })
    (import ./zsh-keybindings.nix {
      inherit config lib;
    })
  ];
}
