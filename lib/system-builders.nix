{inputs}: let
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
    ;

  # Common modules shared between Darwin and NixOS
  commonModules = [
    ../modules/shared
  ];

  # Common Home Manager configuration
  mkHomeManagerConfig = {
    hostConfig,
    extraSharedModules ? [],
  }: {
    useGlobalPkgs = true;
    verbose = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
      inherit (hostConfig) system;
      hostSystem = hostConfig.system;
      inherit (hostConfig) username;
      inherit (hostConfig) useremail;
      inherit (hostConfig) hostname;
    };
    sharedModules =
      [
        catppuccin.homeModules.catppuccin
        sops-nix.homeManagerModules.sops
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
          ../modules/darwin

          # Integration modules
          determinate.darwinModules.default
          home-manager.darwinModules.home-manager
          mac-app-util.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew
          sops-nix.darwinModules.sops

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

          # Platform modules
          ../modules/nixos
          determinate.nixosModules.default

          # Integration modules
          sops-nix.nixosModules.sops
          catppuccin.nixosModules.catppuccin
          niri.nixosModules.niri
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
        ]
        ++ commonModules;
    };
}
