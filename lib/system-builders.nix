{
  inputs,
  validationLib, # <-- Now correctly accepted as an argument
}: let
  inherit
    (inputs)
    darwin
    nixpkgs
    home-manager
    mac-app-util
    nix-homebrew
    sops-nix
    catppuccin
    niri
    musnix
    nur
    solaar
    determinate
    chaotic
    ;
  inherit (nixpkgs) lib;

  # Import virtualisation library
  virtualisationLib = import ./virtualisation.nix {inherit lib;};

  # Common modules shared between Darwin and NixOS systems
  commonModules = [
    ../modules/shared
  ];

  # Helper function to create the validation module
  # This eliminates all duplication
  mkValidationModule = importPatterns: {
    config,
    lib,
    ...
  }: let
    # Use the validationLib passed into this file
    validation = validationLib;
    checks = [
      # Host config must include core fields
      (validation.validateHostConfig (config.host or {}))

      # If SOPS is enabled, secrets should be defined
      (validation.validateSecretsConfig config)

      # Import patterns for known path-based imports in this builder
      (validation.mkCheck {
        name = "Import Patterns";
        assertion = validation.validateImportPatterns importPatterns;
        message = "Imports follow standard patterns (directory imports flagged as warnings).";
        severity = "warn";
      })
    ];
    report = validation.mkValidationReport {inherit config checks;};
    failedMessages = lib.concatStringsSep " | " (map (c: "${c.name}: ${c.message}") report.failed);
  in {
    assertions =
      # One assertion per check so failures surface clearly
      (map (c: {
          assertion = c.status != "fail";
          message = "[Validation] ${c.name}: ${c.message}";
        })
        report.allChecks)
      # Aggregated assertion for a concise summary in CI logs
      ++ [
        {
          assertion = report.success;
          message =
            if report.failed == []
            then "[Validation] All checks passed"
            else "[Validation] Failed checks: ${failedMessages}";
        }
      ];
  };

  # Common Home Manager configuration
  mkHomeManagerConfig = {
    hostConfig,
    extraSharedModules ? [],
  }: {
    useGlobalPkgs = true;
    verbose = true;
    backupFileExtension = "backup";
    extraSpecialArgs =
      inputs
      // hostConfig
      // {
        inherit inputs;
        inherit (hostConfig) system;
        hostSystem = hostConfig.system;
        host = hostConfig;
        inherit (hostConfig) username useremail hostname;
        virtualisation = hostConfig.features.virtualisation or {};
        modulesVirtualisation = virtualisationLib.mkModulesVirtualisationArgs {
          hostVirtualisation = hostConfig.features.virtualisation or {};
        };
      };
    sharedModules =
      [
        sops-nix.homeManagerModules.sops
        catppuccin.homeModules.catppuccin
      ]
      ++ extraSharedModules;
    users.${hostConfig.username} = import ../home;
  };
in {
  # Build a Darwin (macOS) system configuration
  mkDarwinSystem = hostName: hostConfig: {homebrew-j178}:
    darwin.lib.darwinSystem {
      inherit (hostConfig) system;

      specialArgs = {
        inherit inputs;
        inherit (hostConfig) system; # For modules that expect 'system' arg
        hostSystem = hostConfig.system;
        inherit (hostConfig) username;
        inherit (hostConfig) useremail;
        inherit (hostConfig) hostname;
      };

      modules =
        [
          # Host-specific configuration
          ../hosts/${hostName}/configuration.nix

          # Set host options from host config
          {
            config.host = hostConfig;
          }

          # Platform modules
          ../modules/darwin/default.nix

          # Integration modules
          determinate.darwinModules.default
          home-manager.darwinModules.home-manager
          mac-app-util.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew
          sops-nix.darwinModules.sops

          # Apply overlays from overlays/ directory
          {
            nixpkgs = {
              overlays = nixpkgs.lib.attrValues (
                import ../overlays {
                  inherit inputs;
                  inherit (hostConfig) system;
                }
              );
              config = {
                allowUnfree = true;
                allowUnfreePredicate = _: true;
                allowBroken = true; # Allow broken packages (e.g., CUDA packages)
                # Insecure packages removed - test if builds still work
                # If something breaks, add back: permittedInsecurePackages = ["mbedtls-2.28.10"];
              };
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
              extraSharedModules = [mac-app-util.homeManagerModules.default];
            };
          }
          (
            {config, ...}: {
              home-manager.extraSpecialArgs.systemConfig = config;
            }
          )

          # Validation assertions - now just a call to our helper
          (mkValidationModule [
            "../hosts/${hostName}/configuration.nix"
            "../modules/darwin/default.nix"
          ])
        ]
        ++ commonModules;
    };

  # Build a NixOS system configuration
  mkNixosSystem = hostName: hostConfig: {self}:
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

      modules =
        [
          # Host-specific configuration
          ../hosts/${hostName}/configuration.nix

          # Set host options from host config
          {
            config.host = hostConfig;
          }

          # Apply overlays from overlays/ directory
          {
            nixpkgs = {
              overlays = nixpkgs.lib.attrValues (
                import ../overlays {
                  inherit inputs;
                  inherit (hostConfig) system;
                }
              );
              config = {
                allowUnfree = true;
                allowUnfreePredicate = _: true;
                allowBroken = true; # Allow broken packages (e.g., CUDA packages)
                # Insecure packages removed - test if builds still work
                # If something breaks, add back: permittedInsecurePackages = ["mbedtls-2.28.10"];
              };
            };
          }

          # Platform modules
          ../modules/nixos/default.nix
          determinate.nixosModules.default

          # Integration modules
          sops-nix.nixosModules.sops
          niri.nixosModules.niri
          chaotic.nixosModules.default
          inputs.nix-topology.nixosModules.default
        ]
        ++ lib.optional (
          hostConfig.system == "x86_64-linux" || hostConfig.system == "aarch64-linux"
        )
        catppuccin.nixosModules.catppuccin
        ++ [
          musnix.nixosModules.musnix
          nur.modules.nixos.default
          solaar.nixosModules.default
          home-manager.nixosModules.home-manager

          # Home Manager configuration
          {
            home-manager =
              mkHomeManagerConfig {inherit hostConfig;}
              // {
                useUserPackages = true;
              };
          }
          (
            {config, ...}: {
              home-manager.extraSpecialArgs.systemConfig = config;
            }
          )

          # Validation assertions - now just a call to our helper
          (mkValidationModule [
            "../hosts/${hostName}/configuration.nix"
            "../modules/nixos/default.nix"
          ])
        ]
        ++ commonModules;
    };
}
