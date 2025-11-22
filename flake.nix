{
  description = "Lewiss NixOS and Nix-Darwin configuration";

  # Note: Binary cache configuration is in modules/shared/core.nix
  # not here in nixConfig, as nixConfig requires --accept-flake-config

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";
    darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    };
    flakehub = {
      url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
    };
    mac-app-util = {
      url = "github:hraban/mac-app-util";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-j178 = {
      url = "github:j178/homebrew-tap";
      flake = false;
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    awww = {
      url = "git+https://codeberg.org/LGFae/awww";
    };
    ironbar = {
      url = "github:JakeStanger/ironbar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    musnix = {
      url = "github:musnix/musnix";
    };
    solaar = {
      url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    jsonresume-nix = {
      url = "https://flakehub.com/f/TaserudConsulting/jsonresume-nix/*.tar.gz";
    };
    nh = {
      url = "https://flakehub.com/f/nix-community/nh/4.2.0-beta5.tar.gz";
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lazygit = {
      url = "github:jesseduffield/lazygit";
    };
    atuin = {
      url = "github:atuinsh/atuin";
    };
    pog = {
      url = "github:jpetrucciani/pog";
    };
    nix-topology = {
      url = "github:oddlama/nix-topology";
    };
    nix-colorizer = {
      url = "github:nutsalhan87/nix-colorizer";
    };
    devour-flake = {
      url = "github:srid/devour-flake";
      flake = false;
    };
    vpn-confinement = {
      url = "github:Maroka-chan/VPN-Confinement";
    };
    mcps = {
      url = "github:roman/mcps.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    comfyui = {
      url = "github:utensils/nix-comfyui";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs self; } {
      imports = [
        ./flake-parts/core.nix
        inputs.nix-topology.flakeModule
      ];
    };
}
