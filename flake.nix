{
  description = "Lewiss NixOS and Nix-Darwin configuration";

  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    lazy-trees = true;
  };

  inputs = {
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # System frameworks
    darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS utilities
    mac-app-util.url = "github:hraban/mac-app-util";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Themes and styling
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Desktop environment and UI
    waybar = {
      url = "github:Alexays/Waybar/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    swww = {
      url = "github:LGFae/swww";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Security and secrets
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Audio and multimedia
    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Development and packages
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    yazi = {
      url = "github:sxyazi/yazi";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # System and hardware
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };
    solaar = {
      url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvidia-patch = {
      url = "github:icewind1991/nvidia-patch-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Tools and utilities
    nh = {
      url = "github:nix-community/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Development and CI
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    homebrew-j178 = {
      url = "github:j178/homebrew-tap";
      flake = false;
    };
  };

  outputs = inputs @ {self, ...}: let
    # Import host configurations and utilities
    hostsConfig = import ./lib/hosts.nix {inherit (inputs.nixpkgs) lib;};
    inherit (hostsConfig) hosts;

    # Import system builders
    systemBuilders = import ./lib/system-builders.nix {inherit inputs;};

    # Import output builders with necessary context
    outputBuilders = import ./lib/output-builders.nix {
      inputs =
        inputs
        // {
          inherit self;
        };
      inherit hosts;
    };

    # Darwin system builder with homebrew inputs
    mkDarwinSystem = hostName: hostConfig:
      systemBuilders.mkDarwinSystem hostName hostConfig {
        inherit
          (inputs)
          homebrew-j178
          ;
      };

    # NixOS system builder with self reference
    mkNixosSystem = hostName: hostConfig: systemBuilders.mkNixosSystem hostName hostConfig {inherit self;};
  in {
    # Development and formatting outputs
    formatter = outputBuilders.mkFormatters;
    checks = outputBuilders.mkChecks;
    devShells = outputBuilders.mkDevShells;

    # System configurations
    darwinConfigurations = builtins.mapAttrs mkDarwinSystem (hostsConfig.getDarwinHosts hosts);
    nixosConfigurations =
      builtins.mapAttrs mkNixosSystem
      (inputs.nixpkgs.lib.filterAttrs (name: hostConfig: hostConfig.system == "x86_64-linux")
        (hostsConfig.getNixosHosts hosts));
    homeConfigurations = outputBuilders.mkHomeConfigurations;
  };
}
