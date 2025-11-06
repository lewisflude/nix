{ inputs }:
let
  nixpkgs = inputs.nixpkgs or (throw "nixpkgs input is required");
  inherit (nixpkgs) lib;

  darwin = inputs.darwin or null;
  home-manager = inputs.home-manager or null;
  mac-app-util = inputs.mac-app-util or null;
  nix-homebrew = inputs.nix-homebrew or null;
  sops-nix = inputs.sops-nix or null;
  catppuccin = inputs.catppuccin or null;
  niri = inputs.niri or null;
  musnix = inputs.musnix or null;
  solaar = inputs.solaar or null;
  determinate = inputs.determinate or null;
  chaotic = inputs.chaotic or null;

  functionsLib = import ./functions.nix { inherit lib; };

  commonModules = [
    ../modules/shared
  ];

  mkHomeManagerConfig =
    {
      hostConfig,
      extraSharedModules ? [ ],
    }:
    {
      useGlobalPkgs = true;
      verbose = true;
      backupFileExtension = "backup";
      extraSpecialArgs = functionsLib.mkHomeManagerExtraSpecialArgs {
        inherit inputs hostConfig;
        includeUserFields = true;
      };
      sharedModules =
        lib.optionals (sops-nix != null) [ sops-nix.homeManagerModules.sops ]
        ++ lib.optionals (catppuccin != null) [ catppuccin.homeModules.catppuccin ]
        ++ lib.optionals (chaotic != null) [ chaotic.homeManagerModules.default ]
        ++ extraSharedModules;
      users.${hostConfig.username} = import ../home;
    };
in
{
  mkDarwinSystem =
    hostName: hostConfig:
    { homebrew-j178 }:
    (
      if darwin == null then
        throw "darwin input is required for mkDarwinSystem"
      else
        darwin.lib.darwinSystem
    )
      {
        inherit (hostConfig) system;

        specialArgs = {
          inherit inputs;
          inherit (hostConfig) system;
          hostSystem = hostConfig.system;
          inherit (hostConfig) username;
          inherit (hostConfig) useremail;
          inherit (hostConfig) hostname;
        };

        modules = [
          ../hosts/${hostName}/configuration.nix
          {
            config.host = hostConfig;
          }
          ../modules/darwin/default.nix
        ]
        ++ lib.optionals (determinate != null) [ determinate.darwinModules.default ]
        ++ lib.optionals (home-manager != null) [ home-manager.darwinModules.home-manager ]
        ++ lib.optionals (mac-app-util != null) [ mac-app-util.darwinModules.default ]
        ++ lib.optionals (nix-homebrew != null) [ nix-homebrew.darwinModules.nix-homebrew ]
        ++ lib.optionals (sops-nix != null) [ sops-nix.darwinModules.sops ]
        ++ [
          {
            nixpkgs = {
              overlays = functionsLib.mkOverlays {
                inherit inputs;
                inherit (hostConfig) system;
              };
              config = functionsLib.mkPkgsConfig;
            };
          }
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = hostConfig.username;
              autoMigrate = true;
              taps."j178/homebrew-tap" = homebrew-j178;
              mutableTaps = false;
            };
          }
          {
            home-manager = mkHomeManagerConfig {
              inherit hostConfig;
              extraSharedModules = lib.optionals (mac-app-util != null) [
                mac-app-util.homeManagerModules.default
              ];
            };
          }
          (
            { config, ... }:
            {
              home-manager.extraSpecialArgs.systemConfig = config;
            }
          )
        ]
        ++ commonModules;
      };

  mkNixosSystem =
    hostName: hostConfig:
    { self }:
    nixpkgs.lib.nixosSystem {
      inherit (hostConfig) system;

      specialArgs = {
        inherit inputs;
        inherit (hostConfig) system;
        hostSystem = hostConfig.system;
        inherit (hostConfig) username;
        inherit (hostConfig) useremail;
        inherit (hostConfig) hostname;
        keysDirectory = "${self}/keys";
      };

      modules = [
        ../hosts/${hostName}/configuration.nix
        {
          config.host = hostConfig;
        }
        {
          nixpkgs = {
            overlays = functionsLib.mkOverlays {
              inherit inputs;
              inherit (hostConfig) system;
            };
            config = functionsLib.mkPkgsConfig;
          };
        }
        ../modules/nixos/default.nix
      ]
      ++ lib.optionals (determinate != null) [ determinate.nixosModules.default ]
      ++ lib.optionals (sops-nix != null) [ sops-nix.nixosModules.sops ]
      ++ lib.optionals (niri != null) [ niri.nixosModules.niri ]
      ++ lib.optionals (chaotic != null) [ chaotic.nixosModules.default ]
      ++ lib.optionals (inputs ? nix-topology) [ inputs.nix-topology.nixosModules.default ]
      ++ lib.optionals (inputs ? vpn-confinement) [ inputs.vpn-confinement.nixosModules.default ]
      ++ lib.optionals (
        (hostConfig.system == "x86_64-linux" || hostConfig.system == "aarch64-linux") && catppuccin != null
      ) [ catppuccin.nixosModules.catppuccin ]
      ++ lib.optionals (musnix != null) [ musnix.nixosModules.musnix ]
      ++ lib.optionals (solaar != null) [ solaar.nixosModules.default ]
      ++ lib.optionals (home-manager != null) [ home-manager.nixosModules.home-manager ]
      ++ [
        {
          home-manager = mkHomeManagerConfig { inherit hostConfig; } // {
            useUserPackages = true;
          };
        }
        (
          { config, ... }:
          {
            home-manager.extraSpecialArgs.systemConfig = config;
          }
        )
      ]
      ++ commonModules;
    };
}
