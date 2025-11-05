# Development feature module (cross-platform)
# Controlled by host.features.development.*
# Provides comprehensive development environment with languages, tools, and editors
{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}: let
  inherit (lib) mkIf;
  inherit (lib.lists) optional;
  cfg = config.host.features.development;
  platformLib = (import ../../../../lib/functions.nix {inherit lib;}).withSystem hostSystem;
  packageSets = import ../../../../lib/package-sets.nix {
    inherit pkgs;
    inherit (platformLib) versions;
  };
  featureBuilders = import ../../../../lib/feature-builders.nix {
    inherit lib packageSets;
  };
  inherit (platformLib) isLinux;
in {
  config = mkIf cfg.enable {
    # Environment variables for development
    environment.variables = featureBuilders.mkDevEnvironment cfg;

    # System-level packages (NixOS only)
    environment.systemPackages = mkIf isLinux (
      featureBuilders.mkSystemPackages {
        inherit cfg pkgs;
      }
      # Add Linux-specific packages (e.g., glibc.dev for build tools)
      ++ lib.optionals (cfg.buildTools or false) [pkgs.glibc.dev]
    );

    # NixOS-specific services
    virtualisation.docker = mkIf (isLinux && cfg.docker) {
      enable = true;
      daemon.settings = {
        data-root = "/var/lib/docker";
      };
    };

    # User groups for Docker
    users.users.${config.host.username}.extraGroups = optional (isLinux && cfg.docker) "docker";

    # Assertions
    assertions = [
      {
        assertion = cfg.rust -> (cfg.git or false);
        message = "Rust development requires Git to be enabled";
      }
      {
        assertion = (cfg.kubernetes or false) -> (cfg.docker or false);
        message = "Kubernetes development tools require Docker to be enabled";
      }
    ];
  };
}
