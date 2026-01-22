# Shell Feature Module - Main Entry Point
# Combines all shell sub-modules into a cohesive configuration
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
    (import ./zsh-config.nix {
      inherit config lib;
    })
    (import ./completion.nix { inherit config pkgs; })
    (import ./aliases.nix { inherit lib hostSystem; })
    (import ./keybindings.nix { inherit config lib; })
    (import ./init-content.nix {
      inherit
        config
        pkgs
        lib
        systemConfig
        sources
        shellHelpers
        ;
    })
    (import ./environment.nix {
      inherit
        config
        pkgs
        lib
        ;
    })
    (import ./cached-init.nix {
      inherit
        config
        pkgs
        lib
        ;
    })
  ];
}
