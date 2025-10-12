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
in {
  mkDarwinSystem = hostName: hostConfig: {homebrew-j178}:
    darwin.lib.darwinSystem {
      inherit (hostConfig) system;
      specialArgs = inputs // hostConfig;
      modules = [
        ../hosts/${hostName}/configuration.nix
        ../modules/shared
        ../modules/darwin
        home-manager.darwinModules.home-manager
        mac-app-util.darwinModules.default
        nix-homebrew.darwinModules.nix-homebrew
        sops-nix.darwinModules.sops
        {_module.args = {inherit inputs;};}
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "lewisflude";
            autoMigrate = true;
            taps = {
              "j178/homebrew-tap" = homebrew-j178;
            };
            mutableTaps = false;
          };
        }
        {
          home-manager = {
            useGlobalPkgs = true;
            verbose = true;
            sharedModules = [
              sops-nix.homeManagerModules.sops
              mac-app-util.homeManagerModules.default
              catppuccin.homeModules.catppuccin
            ];
            extraSpecialArgs =
              inputs
              // hostConfig
              // {
                inherit inputs;
              };
            users.${hostConfig.username} = import ../home;
          };
        }
      ];
    };
  mkNixosSystem = hostName: hostConfig: {self}:
    nixpkgs.lib.nixosSystem {
      inherit (hostConfig) system;
      specialArgs =
        inputs
        // hostConfig
        // {
          keysDirectory = "${self}/keys";
        };
      modules = [
        determinate.nixosModules.default
        ../hosts/${hostName}/configuration.nix
        ../modules/shared
        ../modules/nixos
        sops-nix.nixosModules.sops
        catppuccin.nixosModules.catppuccin
        niri.nixosModules.niri
        musnix.nixosModules.musnix
        nur.modules.nixos.default
        solaar.nixosModules.default
        {_module.args = {inherit inputs;};}
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            verbose = true;
            backupFileExtension = "backup";
            extraSpecialArgs = inputs // hostConfig;
            sharedModules = [
              catppuccin.homeModules.catppuccin
              inputs.sops-nix.homeManagerModules.sops
              {_module.args = {inherit inputs;};}
            ];
            users.${hostConfig.username} = import ../home;
          };
        }
      ];
    };
}
