{
  description = "Example nix-darwin system flake";

  # Settings that are picked up automatically by every `nix` invocation that
  # touches this flake (requires `nix --accept-flake-config` the first time).
  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:nix-darwin/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
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
    homebrew-nx = {
      url = "github:nrwl/homebrew-nx";
      flake = false;
    };
    homebrew-j178 = {
      url = "github:j178/homebrew-tap";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      darwin,
      nixpkgs,
      home-manager,
      mac-app-util,
      nix-homebrew,
      homebrew-core,
      homebrew-cask,
      homebrew-nx,
      homebrew-j178,
      catppuccin,
    }:
    let
      username = "lewisflude";
      useremail = "lewis@lewisflude.com";
      system = "aarch64-darwin";
      hostname = "Lewiss-MacBook-Pro";

      specialArgs = inputs // {
        inherit username useremail hostname;
      };
    in
    {
      # Provide a formatter so `nix fmt` works
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;

      # Developer shell with common tools
      devShells.${system}.default = nixpkgs.legacyPackages.${system}.mkShell {
        packages = with nixpkgs.legacyPackages.${system}; [
          nixfmt-rfc-style
          jq
          yq
          git
          gh
          direnv
          nix-direnv
        ];
      };

      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Lewiss-MacBook-Pro
      darwinConfigurations."${hostname}" = darwin.lib.darwinSystem {
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
          ./modules/backup.nix
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
                "nrwl/homebrew-nx" = homebrew-nx;
                "j178/homebrew-tap" = homebrew-j178;
              };
              mutableTaps = false;
            };
          }

          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;
            home-manager.backupFileExtension = "backup";
            home-manager.sharedModules = [ mac-app-util.homeManagerModules.default ];
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.users.${username} = import ./home;

          }
        ];
      };
    };
}
