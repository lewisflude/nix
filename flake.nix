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
      # Import host configurations
      hosts = {
        macbook-pro = import ./hosts/macbook-pro;
      };

      # Helper function to create Darwin system
      mkDarwinSystem = hostName: hostConfig: darwin.lib.darwinSystem {
        system = hostConfig.system;
        specialArgs = inputs // hostConfig;
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
          ./modules/nix-optimization.nix
          home-manager.darwinModules.home-manager
          mac-app-util.darwinModules.default
          nix-homebrew.darwinModules.nix-homebrew

          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = hostConfig.username;
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
            home-manager.extraSpecialArgs = inputs // hostConfig;
            home-manager.users.${hostConfig.username} = import ./home;
          }
        ];
      };
    in
    {
      # Provide formatters for all systems
      formatter = nixpkgs.lib.genAttrs 
        (builtins.attrValues (builtins.mapAttrs (name: host: host.system) hosts))
        (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      # Developer shells for all systems
      devShells = builtins.listToAttrs (
        builtins.map (hostConfig: {
          name = hostConfig.system;
          value = {
            default = nixpkgs.legacyPackages.${hostConfig.system}.mkShell {
              packages = with nixpkgs.legacyPackages.${hostConfig.system}; [
                nixfmt-rfc-style
                jq
                yq
                git
                gh
                direnv
                nix-direnv
              ];
            };
          };
        }) (builtins.attrValues hosts)
      );

      # Darwin configurations
      darwinConfigurations = builtins.mapAttrs 
        (name: hostConfig: mkDarwinSystem name hostConfig)
        (nixpkgs.lib.filterAttrs (name: host: host.system == "aarch64-darwin" || host.system == "x86_64-darwin") hosts);
    };
}
