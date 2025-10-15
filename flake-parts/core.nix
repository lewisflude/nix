{ inputs, self, ... }:
let
  inherit (inputs.nixpkgs) lib;

  hostsConfig = import ../lib/hosts.nix { inherit lib; };
  inherit (hostsConfig) hosts;

  systemBuilders = import ../lib/system-builders.nix { inherit inputs; };

  outputBuilders = import ../lib/output-builders.nix {
    inputs = inputs // { inherit self; };
    inherit hosts;
  };

  mkDarwinSystem = hostName: hostConfig:
    systemBuilders.mkDarwinSystem hostName hostConfig {
      inherit (inputs) homebrew-j178;
    };

  mkNixosSystem = hostName: hostConfig:
    systemBuilders.mkNixosSystem hostName hostConfig { inherit self; };
in {
  _module.args = {
    inherit hosts hostsConfig systemBuilders outputBuilders;
  };

  flake = {
    darwinConfigurations =
      builtins.mapAttrs mkDarwinSystem (hostsConfig.getDarwinHosts hosts);

    nixosConfigurations =
      builtins.mapAttrs mkNixosSystem (hostsConfig.getNixosHosts hosts);

    homeConfigurations = outputBuilders.mkHomeConfigurations;

    formatter = outputBuilders.mkFormatters;
    checks = outputBuilders.mkChecks;
    devShells = outputBuilders.mkDevShells;

    lib = {
      inherit
        (import ../lib/functions.nix {
          inherit lib;
          system = "x86_64-linux";
        })
        platformPackages
        platformModules
        homeDir
        configDir
        dataDir
        cacheDir;

      inherit
        (import ../lib/validation.nix {
          inherit lib;
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
        })
        validateHostConfig
        mkCheck;

      inherit
        (import ../lib/cache.nix { inherit lib; })
        createManifest
        generateCacheKey
        evalCache
        cachixConfig
        prebuildManifest;
    };
  };
}
