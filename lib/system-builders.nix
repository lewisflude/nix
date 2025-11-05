{
  inputs,
  validationLib, # <-- Now correctly accepted as an argument
}:
let
  # Access inputs conditionally to avoid assumptions about which inputs are present
  nixpkgs = inputs.nixpkgs or (throw "nixpkgs input is required");
  inherit (nixpkgs) lib;

  # Optional inputs - check existence before use
  darwin = inputs.darwin or null;
  home-manager = inputs.home-manager or null;
  mac-app-util = inputs.mac-app-util or null;
  nix-homebrew = inputs.nix-homebrew or null;
  sops-nix = inputs.sops-nix or null;
  catppuccin = inputs.catppuccin or null;
  niri = inputs.niri or null;
  musnix = inputs.musnix or null;
  nur = inputs.nur or null;
  solaar = inputs.solaar or null;
  determinate = inputs.determinate or null;
  chaotic = inputs.chaotic or null;

  # Import virtualisation library
  virtualisationLib = import ./virtualisation.nix { inherit lib; };

  # Import functions library for shared config
  functionsLib = import ./functions.nix { inherit lib; };

  # Common modules shared between Darwin and NixOS systems
  commonModules = [
    ../modules/shared
  ];

  # Helper function to create the validation module
  # Creates assertions for host config and secrets validation
  mkValidationModule =
    { config, ... }:
    let
      validation = validationLib;
      hostCheck = validation.validateHostConfig (config.host or { });
      secretsCheck = validation.validateSecretsConfig config;
    in
    {
      assertions = [
        # Host config validation
        {
          assertion = hostCheck.status != "fail";
          message = "[Validation] ${hostCheck.name}: ${hostCheck.message}";
        }
        # Secrets validation (warning only)
        {
          assertion = secretsCheck.status != "fail";
          message = "[Validation] ${secretsCheck.name}: ${secretsCheck.message}";
        }
      ];
    };

  # Common Home Manager configuration
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
        inherit inputs hostConfig virtualisationLib;
        includeUserFields = true;
      };
      sharedModules =
        lib.optionals (sops-nix != null) [ sops-nix.homeManagerModules.sops ]
        ++ lib.optionals (catppuccin != null) [ catppuccin.homeModules.catppuccin ]
        ++ extraSharedModules;
      users.${hostConfig.username} = import ../home;
    };
in
{
  # Build a Darwin (macOS) system configuration
  # Uses perSystemPkgs from flake-parts perSystem to ensure consistency
  # This follows flake-parts best practices: top-level configs should use withSystem
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
          inherit (hostConfig) system; # For modules that expect 'system' arg
          hostSystem = hostConfig.system;
          inherit (hostConfig) username;
          inherit (hostConfig) useremail;
          inherit (hostConfig) hostname;
        };

        modules = [
          # Host-specific configuration
          ../hosts/${hostName}/configuration.nix

          # Set host options from host config
          {
            config.host = hostConfig;
          }

          # Platform modules
          ../modules/darwin/default.nix

          # Integration modules (conditional on input existence)
        ]
        ++ lib.optionals (determinate != null) [ determinate.darwinModules.default ]
        ++ lib.optionals (home-manager != null) [ home-manager.darwinModules.home-manager ]
        ++ lib.optionals (mac-app-util != null) [ mac-app-util.darwinModules.default ]
        ++ lib.optionals (nix-homebrew != null) [ nix-homebrew.darwinModules.nix-homebrew ]
        ++ lib.optionals (sops-nix != null) [ sops-nix.darwinModules.sops ]
        ++ [
          # Apply overlays from overlays/ directory
          # OVERLAY APPLICATION MECHANISM:
          # Overlays are imported from overlays/default.nix via functionsLib.mkOverlays,
          # which converts the overlay attribute set to a list. Overlays are applied
          # early in the module list so all subsequent modules receive modified packages.
          # See overlays/default.nix for overlay definitions and documentation.
          {
            nixpkgs = {
              overlays = functionsLib.mkOverlays {
                inherit inputs;
                inherit (hostConfig) system;
              };
              config = functionsLib.mkPkgsConfig;
            };
          }

          # Homebrew configuration
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

          # Home Manager configuration
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

          # Validation assertions - now just a call to our helper
          mkValidationModule
        ]
        ++ commonModules;
      };

  # Build a NixOS system configuration
  # Uses perSystemPkgs from flake-parts perSystem to ensure consistency
  # This follows flake-parts best practices: top-level configs should use withSystem
  mkNixosSystem =
    hostName: hostConfig:
    { self }:
    nixpkgs.lib.nixosSystem {
      inherit (hostConfig) system;

      specialArgs = {
        inherit inputs;
        inherit (hostConfig) system; # For modules that expect 'system' arg
        hostSystem = hostConfig.system;
        inherit (hostConfig) username;
        inherit (hostConfig) useremail;
        inherit (hostConfig) hostname;
        keysDirectory = "${self}/keys";
      };

      modules = [
        # Host-specific configuration
        ../hosts/${hostName}/configuration.nix

        # Set host options from host config
        {
          config.host = hostConfig;
        }

        # Apply overlays from overlays/ directory
        # OVERLAY APPLICATION MECHANISM:
        # Overlays are imported from overlays/default.nix via functionsLib.mkOverlays,
        # which converts the overlay attribute set to a list. Overlays are applied
        # early in the module list so all subsequent modules receive modified packages.
        # See overlays/default.nix for overlay definitions and documentation.
        {
          nixpkgs = {
            overlays = functionsLib.mkOverlays {
              inherit inputs;
              inherit (hostConfig) system;
            };
            config = functionsLib.mkPkgsConfig;
          };
        }

        # Platform modules
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
      ++ lib.optionals (nur != null) [ nur.modules.nixos.default ]
      ++ lib.optionals (solaar != null) [ solaar.nixosModules.default ]
      ++ lib.optionals (home-manager != null) [ home-manager.nixosModules.home-manager ]
      ++ [
        # Home Manager configuration
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

        # Validation assertions - now just a call to our helper
        mkValidationModule
      ]
      ++ commonModules;
    };
}
