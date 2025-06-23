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

    # NixOS-specific inputs
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
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
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-mozilla = {
      url = "github:mozilla/nixpkgs-mozilla";
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
    cursor.url = "github:omarcresp/cursor-flake/main";

    # macOS-specific homebrew inputs
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
      hyprland,
      hyprland-plugins,
      astal,
      sops-nix,
      waybar,
      ghostty,
      musnix,
      nixpkgs-mozilla,
      yazi,
      nixos-hardware,
      solaar,
      nvidia-patch,
      cursor,
      ...
    }:
    let
      # Import host configurations
      hosts = {
        "Lewiss-MacBook-Pro" = import ./hosts/Lewiss-MacBook-Pro;
        jupiter = import ./hosts/jupiter;
      };

      # Helper function to create Darwin system
      mkDarwinSystem =
        hostName: hostConfig:
        darwin.lib.darwinSystem {
          system = hostConfig.system;
          specialArgs = inputs // hostConfig;
          modules = [
            ./hosts/${hostName}/configuration.nix

            # Common modules (cross-platform)
            ./modules/common

            # Darwin-specific modules
            ./modules/darwin
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
              home-manager.sharedModules = [
                mac-app-util.homeManagerModules.default
                catppuccin.homeModules.catppuccin
              ];
              home-manager.extraSpecialArgs = inputs // hostConfig;
              home-manager.users.${hostConfig.username} = import ./home;
            }
          ];
        };

      # Helper function to create NixOS system
      mkNixosSystem =
        hostName: hostConfig:
        nixpkgs.lib.nixosSystem {
          system = hostConfig.system;
          specialArgs =
            inputs
            // hostConfig
            // {
              configVars = import ./config-vars.nix;
              keysDirectory = "${self}/keys";
            };
          modules = [
            # Host-specific configuration
            ./hosts/${hostName}/configuration.nix

            # Common and NixOS modules
            ./modules/common
            ./modules/nixos

            # Desktop environment (conditionally loaded)
            ./modules/nixos/hyprland.nix

            # External modules
            sops-nix.nixosModules.sops
            catppuccin.nixosModules.catppuccin
            musnix.nixosModules.musnix
            solaar.nixosModules.default

            # Make inputs available to all modules
            { _module.args = { inherit inputs; }; }

            # Home Manager integration
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.verbose = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs =
                inputs
                // hostConfig
                // {
                  configVars = import ./config-vars.nix;
                };
              home-manager.sharedModules = [
                sops-nix.homeManagerModules.sops
                catppuccin.homeModules.catppuccin
              ];
              home-manager.users.${hostConfig.username} = import ./home;
            }
          ];
        };
    in
    {
      # Provide formatters for all systems
      formatter = nixpkgs.lib.genAttrs (builtins.attrValues (
        builtins.mapAttrs (name: host: host.system) hosts
      )) (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      # Developer shells for all systems
      devShells = builtins.listToAttrs (
        builtins.map (hostConfig: {
          name = hostConfig.system;
          value =
            let
              pkgs = nixpkgs.legacyPackages.${hostConfig.system};
              shellsConfig = import ./shells {
                inherit pkgs;
                lib = pkgs.lib;
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

      # Darwin configurations
      darwinConfigurations = builtins.mapAttrs (name: hostConfig: mkDarwinSystem name hostConfig) (
        nixpkgs.lib.filterAttrs (
          name: host: host.system == "aarch64-darwin" || host.system == "x86_64-darwin"
        ) hosts
      );

      # NixOS configurations
      nixosConfigurations = builtins.mapAttrs (name: hostConfig: mkNixosSystem name hostConfig) (
        nixpkgs.lib.filterAttrs (
          name: host: host.system == "x86_64-linux" || host.system == "aarch64-linux"
        ) hosts
      );

      # Standalone home-manager configurations
      homeConfigurations = builtins.mapAttrs (
        name: hostConfig:
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${hostConfig.system};
          extraSpecialArgs =
            inputs
            // hostConfig
            // {
              configVars = import ./config-vars.nix;
            };
          modules = [
            ./home
            sops-nix.homeManagerModules.sops
            catppuccin.homeModules.catppuccin
          ];
        }
      ) hosts;
    };
}
