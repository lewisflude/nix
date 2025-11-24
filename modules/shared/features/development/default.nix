{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}:
let
  inherit (lib) mkIf optionalAttrs;
  inherit (lib.lists) optional;
  cfg = config.host.features.development;
  platformLib = (import ../../../../lib/functions.nix { inherit lib; }).withSystem hostSystem;
  packageSets = import ../../../../lib/package-sets.nix {
    inherit pkgs;
  };
  featureBuilders = import ../../../../lib/feature-builders.nix {
    inherit lib packageSets;
  };
  inherit (platformLib) isLinux;
in
{
  # Automatically enable git when rust is enabled (implicit dependency)
  config.host.features.development.git = lib.mkDefault cfg.rust;

  config = mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.variables = featureBuilders.mkDevEnvironment cfg;

        environment.systemPackages = mkIf isLinux (
          featureBuilders.mkSystemPackages {
            inherit cfg pkgs;
          }
          ++ lib.optionals (cfg.buildTools or false) [ pkgs.glibc.dev ]
        );
      }

      (optionalAttrs isLinux {
        virtualisation.docker = mkIf cfg.docker {
          enable = true;
          daemon.settings = {
            data-root = "/var/lib/docker";
          };
        };

        users.users.${config.host.username}.extraGroups = optional cfg.docker "docker";
      })

      {
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
      }
    ]
  );
}
