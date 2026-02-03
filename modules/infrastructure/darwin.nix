# Darwin configuration factory
# Creates darwinConfigurations flake output from configurations.darwin option
# Follows dendritic pattern: minimal infrastructure, modules imported by hosts
{ lib, config, inputs, ... }:
{
  options.configurations.darwin = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submodule {
        options.module = lib.mkOption {
          type = lib.types.deferredModule;
          description = "Darwin configuration module";
        };
      }
    );
    default = { };
    description = "Darwin host configurations";
  };

  config.flake = {
    darwinConfigurations = lib.flip lib.mapAttrs config.configurations.darwin (
      name: { module }: inputs.darwin.lib.darwinSystem { modules = [ module ]; }
    );

    # Auto-generated checks for each Darwin configuration
    checks =
      config.flake.darwinConfigurations
      |> lib.mapAttrsToList (
        name: darwin: {
          ${darwin.config.nixpkgs.hostPlatform.system} = {
            "configurations:darwin:${name}" = darwin.config.system.build.toplevel;
          };
        }
      )
      |> lib.mkMerge;
  };
}
