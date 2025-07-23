{
  description = "Example nix-darwin system flake";

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
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    waybar.url = "github:Alexays/Waybar/master";
    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-mozilla = {
      url = "github:mozilla/nixpkgs-mozilla";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    yazi.url = "github:sxyazi/yazi";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    solaar = {
      url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvidia-patch = {
      url = "github:icewind1991/nvidia-patch-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nh = {
      url = "github:nix-community/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cursor.url = "github:omarcresp/cursor-flake/main";
    mcp-hub.url = "github:ravitemer/mcp-hub";
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
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    niri-unstable = {
      url = "github:sodiboo/niri-flake";
    };
    swww = {
      url = "github:LGFae/swww";
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
      sops-nix,
      musnix,
      nur,
      solaar,
      niri-unstable,
      nh,
      ...
    }:
    let
      hosts = {
        "Lewiss-MacBook-Pro" = import ./hosts/Lewiss-MacBook-Pro;
        jupiter = import ./hosts/jupiter;
      };

      mkDarwinSystem =
        hostName: hostConfig:

        darwin.lib.darwinSystem {
          system = hostConfig.system;
          specialArgs = inputs // hostConfig;
          modules = [
            ./hosts/${hostName}/configuration.nix
            ./modules/common
            ./modules/darwin
            home-manager.darwinModules.home-manager
            mac-app-util.darwinModules.default
            nix-homebrew.darwinModules.nix-homebrew
            sops-nix.darwinModules.sops
            { _module.args = { inherit inputs; }; }
            {
              nix-homebrew = {
                enable = true;
                enableRosetta = true;
                user = hostConfig.username;
                autoMigrate = true;
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
              home-manager.verbose = true;
              home-manager.sharedModules = [
                sops-nix.homeManagerModules.sops
                mac-app-util.homeManagerModules.default
                catppuccin.homeModules.catppuccin
              ];
              home-manager.extraSpecialArgs = inputs // hostConfig;
              home-manager.users.${hostConfig.username} = import ./home;
            }
          ];
        };

      mkNixosSystem =
        hostName: hostConfig:

        nixpkgs.lib.nixosSystem {
          system = hostConfig.system;
          specialArgs =
            inputs
            // hostConfig
            // {
              keysDirectory = "${self}/keys";
            };
          modules = [
            # Apply overlays first
            ./hosts/${hostName}/configuration.nix
            ./modules/common
            ./modules/nixos
            sops-nix.nixosModules.sops
            catppuccin.nixosModules.catppuccin
            niri-unstable.nixosModules.niri
            musnix.nixosModules.musnix
            nur.modules.nixos.default
            solaar.nixosModules.default
            { _module.args = { inherit inputs; }; }
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.verbose = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = inputs // hostConfig;

              home-manager.sharedModules = [
                catppuccin.homeModules.catppuccin
                inputs.sops-nix.homeManagerModules.sops
              ];
              home-manager.users.${hostConfig.username} = import ./home;
            }
          ];
        };
    in
    {
      formatter = nixpkgs.lib.genAttrs (builtins.attrValues (
        builtins.mapAttrs (_name: host: host.system) hosts
      )) (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      devShells = builtins.listToAttrs (
        builtins.map (hostConfig: {
          name = hostConfig.system;
          value =
            let
              pkgs = nixpkgs.legacyPackages.${hostConfig.system};
              shellsConfig = import ./shells {
                inherit pkgs;
                lib = pkgs.lib;
                system = hostConfig.system;
              };
            in
            shellsConfig.devShells
            // {
              default = pkgs.mkShell {
                packages = with pkgs; [
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

      darwinConfigurations = builtins.mapAttrs (name: hostConfig: mkDarwinSystem name hostConfig) (
        nixpkgs.lib.filterAttrs (
          _name: host: host.system == "aarch64-darwin" || host.system == "x86_64-darwin"
        ) hosts
      );

      nixosConfigurations = builtins.mapAttrs (name: hostConfig: mkNixosSystem name hostConfig) (
        nixpkgs.lib.filterAttrs (
          _name: host: host.system == "x86_64-linux" || host.system == "aarch64-linux"
        ) hosts
      );

      homeConfigurations = builtins.mapAttrs (
        _name: hostConfig:
        let
          pkgs = import nixpkgs {
            system = hostConfig.system;
          };
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = inputs // hostConfig;

          modules = [
            ./home
            catppuccin.homeModules.catppuccin
          ];
        }
      ) hosts;
    };
}
