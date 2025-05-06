{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    mac-app-util.url = "github:hraban/mac-app-util";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, mac-app-util
    , nix-homebrew, homebrew-core, homebrew-cask, catppuccin, }:
    let
      username = "lewisflude";
      useremail = "lewis@lewisflude.com";
      system = "aarch64-darwin";
      hostname = "Lewiss-MacBook-Pro";

      specialArgs = inputs // { inherit username useremail hostname; };
    in {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Lewiss-MacBook-Pro
      darwinConfigurations."${hostname}" = nix-darwin.lib.darwinSystem {
        inherit system specialArgs;

        modules = [
          ./modules/core.nix
          ./modules/users.nix
          ./modules/apps.nix
          ./modules/shell.nix
          ./modules/dev.nix
          ./modules/docker.nix
          ./modules/system.nix
          ./modules/security.nix
          ./modules/environment.nix
          home-manager.darwinModules.home-manager
          mac-app-util.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew

          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = username;
              taps = {
                "homebrew/homebrew-cask" = homebrew-cask;
                "homebrew/homebrew-core" = homebrew-core;
              };
              mutableTaps = false;
            };
          }

          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;
            home-manager.backupFileExtension = "backup";
            home-manager.sharedModules =
              [ mac-app-util.homeManagerModules.default ];
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.users.${username} = import ./home;

          }
        ];
      };
    };
}
