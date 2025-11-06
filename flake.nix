{
  description = "Lewiss NixOS and Nix-Darwin configuration";

  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    extra-substituters = [
      "https://nix-community.cachix.org?priority=1"
      "https://nixpkgs-wayland.cachix.org?priority=2"
      "https://numtide.cachix.org?priority=3"
      "https://nixpkgs-python.cachix.org?priority=4"
      "https://lewisflude.cachix.org?priority=5"
      "https://niri.cachix.org?priority=6"
      "https://ghostty.cachix.org?priority=7"
      "https://yazi.cachix.org?priority=8"
      "https://ags.cachix.org?priority=9"
      "https://zed.cachix.org?priority=10"
      "https://catppuccin.cachix.org?priority=11"
      "https://devenv.cachix.org?priority=12"
      "https://viperml.cachix.org?priority=13"
      "https://cuda-maintainers.cachix.org?priority=14"
      "https://chaotic-nyx.cachix.org?priority=20"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "viperml.cachix.org-1:qrxbEKGdajQ+s0pzofucGqUKqkjT+N3c5vy7mOML04c="
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
      "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
      "lewisflude.cachix.org-1:Y4J8FK/Rb7Es/PnsQxk2ZGPvSLup6ywITz8nimdVWXc="
      "ags.cachix.org-1:naAvMrz0CuYqeyGNyLgE010iUiuf/qx6kYrUv3NwAJ8="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    darwin = {
      url = "github:nix-darwin/nix-darwin/master";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
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
    };
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    musnix = {
      url = "github:musnix/musnix";
    };
    solaar = {
      url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    catppuccin = {
      url = "github:catppuccin/nix";
    };
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
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
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
