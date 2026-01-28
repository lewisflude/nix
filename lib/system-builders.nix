{ inputs }:
let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;

  inherit (inputs) darwin;
  inherit (inputs) home-manager;
  mac-app-util = inputs.mac-app-util or null;
  inherit (inputs) nix-homebrew;
  inherit (inputs) sops-nix;
  mcp-home-manager = inputs.mcp-home-manager or null;

  inherit (inputs) niri;
  inherit (inputs) ironbar;
  inherit (inputs) musnix;
  inherit (inputs) solaar;
  inherit (inputs) determinate;
  nix-flatpak = inputs.nix-flatpak or null;
  signal = inputs.signal or null;
  signal-ironbar = inputs.signal-ironbar or null;
  signal-notifications = inputs.signal-notifications or null;

  functionsLib = import ./functions.nix { inherit lib; };

  # Shared resources (eliminates fragile relative imports)
  constants = import ../lib/constants.nix;
  # Note: signalPalette, signalLib, and signalColors are now provided by Signal flake via _module.args
  # as exposed module arguments from the home-manager module

  commonModules = [
    ../modules/shared
  ];


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
          # Shared resources
          inherit constants;
          # Note: signalPalette, signalLib, signalColors provided by Signal flake
        };

        modules =
          [
            ../hosts/${hostName}/configuration.nix
            { config.host = hostConfig; }
            ../modules/darwin/default.nix
          ]
          ++ lib.optionals (determinate != null) [ determinate.darwinModules.default ]
          ++ lib.optionals (sops-nix != null) [ sops-nix.darwinModules.sops ]
          ++ lib.optionals (mac-app-util != null) [ mac-app-util.darwinModules.default ]
          ++ lib.optionals (nix-homebrew != null) [ nix-homebrew.darwinModules.nix-homebrew ]
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
          ]
          ++ lib.optionals (home-manager != null) [
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                verbose = true;
                backupFileExtension = "hm-backup";
                extraSpecialArgs = functionsLib.mkHomeManagerExtraSpecialArgs {
                  inherit inputs hostConfig;
                  includeUserFields = true;
                };
                sharedModules =
                  lib.optionals (sops-nix != null) [ sops-nix.homeManagerModules.sops ]
                  ++ lib.optionals (mcp-home-manager != null) [ mcp-home-manager.homeManagerModules.default ]
                  ++ lib.optionals (ironbar != null && ironbar ? homeManagerModules) [ ironbar.homeManagerModules.default ]
                  ++ lib.optionals (nix-flatpak != null) [ nix-flatpak.homeManagerModules.nix-flatpak ]
                  ++ lib.optionals (signal != null) [ signal.homeManagerModules.default ]
                  ++ lib.optionals (signal-ironbar != null) [ signal-ironbar.homeManagerModules.default ]
                  ++ lib.optionals (mac-app-util != null) [ mac-app-util.homeManagerModules.default ];
                users.${hostConfig.username} = import ../home;
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
        inherit (inputs) nix-colorizer;
        # Shared resources
        inherit constants;
        # Note: signalPalette, signalLib, signalColors provided by Signal flake
      };

      modules =
        [
          ../hosts/${hostName}/configuration.nix
          { config.host = hostConfig; }
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
        ++ lib.optionals (musnix != null) [ musnix.nixosModules.musnix ]
        ++ lib.optionals (solaar != null) [ solaar.nixosModules.default ]
        ++ lib.optionals (inputs ? nix-topology && inputs.nix-topology != null) [ inputs.nix-topology.nixosModules.default ]
        ++ lib.optionals (inputs ? vpn-confinement && inputs.vpn-confinement != null) [ inputs.vpn-confinement.nixosModules.default ]
        ++ lib.optionals (home-manager != null) [
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              verbose = true;
              backupFileExtension = "hm-backup";
              extraSpecialArgs = functionsLib.mkHomeManagerExtraSpecialArgs {
                inherit inputs hostConfig;
                includeUserFields = true;
              };
              sharedModules =
                lib.optionals (sops-nix != null) [ sops-nix.homeManagerModules.sops ]
                ++ lib.optionals (mcp-home-manager != null) [ mcp-home-manager.homeManagerModules.default ]
                ++ lib.optionals (ironbar != null && ironbar ? homeManagerModules) [ ironbar.homeManagerModules.default ]
                ++ lib.optionals (nix-flatpak != null) [ nix-flatpak.homeManagerModules.nix-flatpak ]
                ++ lib.optionals (signal != null) [ signal.homeManagerModules.default ]
                ++ lib.optionals (signal-ironbar != null) [ signal-ironbar.homeManagerModules.default ]
                ++ lib.optionals (signal-notifications != null) [ signal-notifications.homeManagerModules.default ];
              users.${hostConfig.username} = import ../home;
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
