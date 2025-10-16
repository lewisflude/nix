{
  inputs,
  self,
  ...
}: let
  inherit (inputs.nixpkgs) lib;

  hostsConfig = import ../lib/hosts.nix {inherit lib;};
  inherit (hostsConfig) hosts;

  functionsLib = import ../lib/functions.nix {inherit lib;};
  validationLib = import ../lib/validation.nix {inherit lib;};
  cacheLib = import ../lib/cache.nix {inherit lib;};

  systemBuilders = import ../lib/system-builders.nix {
    inherit inputs validationLib;
  };

  outputBuilders = import ../lib/output-builders.nix {
    inputs =
      inputs
      // {
        inherit self;
      };
    inherit hosts;
  };

  mkDarwinSystem = hostName: hostConfig:
    systemBuilders.mkDarwinSystem hostName hostConfig {
      inherit (inputs) homebrew-j178;
    };

  mkNixosSystem = hostName: hostConfig: systemBuilders.mkNixosSystem hostName hostConfig {inherit self;};
in {
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];

  _module.args = {
    inherit
      hosts
      hostsConfig
      systemBuilders
      outputBuilders
      ;
  };

  flake = {
    darwinConfigurations = builtins.mapAttrs mkDarwinSystem (hostsConfig.getDarwinHosts hosts);

    nixosConfigurations = builtins.mapAttrs mkNixosSystem (hostsConfig.getNixosHosts hosts);

    homeConfigurations = outputBuilders.mkHomeConfigurations;

    formatter = outputBuilders.mkFormatters;
    checks = outputBuilders.mkChecks;
    devShells = outputBuilders.mkDevShells;
    apps = outputBuilders.mkApps;

    lib = functionsLib // validationLib // cacheLib;
  };
}
