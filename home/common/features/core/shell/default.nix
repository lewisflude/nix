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
  platformLib = (import ../../../../../lib/functions.nix { inherit lib; }).withSystem system;

  sources = import ../../../_sources/generated.nix {
    inherit (pkgs) fetchgit;
  };

  shellHelpers = import ../../../lib/shell-helpers.nix {
    inherit lib config inputs;
  };
in
{
  imports = [
    (./zsh-config.nix {
      inherit
        config
        pkgs
        lib
        system
        ;
    })
    (./completion.nix { inherit config pkgs; })
    (./aliases.nix { inherit lib hostSystem; })
    (./plugins.nix { inherit sources; })
    (./init-content.nix {
      inherit
        config
        pkgs
        lib
        systemConfig
        sources
        shellHelpers
        ;
    })
    (./environment.nix { inherit config pkgs; })
  ];
}
