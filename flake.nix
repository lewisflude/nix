{
  description = "Lewiss NixOS and Nix-Darwin configuration";

  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Enable evaluation caching for faster rebuilds
    eval-cache = true;

    # Use lazy tree evaluation for better performance
    lazy-trees = true;

    # Binary caches for faster builds
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://helix.cachix.org"
      "https://cache.thalheim.io"
      "https://pre-commit-hooks.cachix.org"
      "https://numtide.cachix.org"
      "https://viperml.cachix.org"
      "https://catppuccin.cachix.org"
      "https://niri.cachix.org"
      "https://ghostty.cachix.org"
      "https://zed.cachix.org"
      "https://cache.garnix.io"
      # Add your custom cache here:
      # "https://your-cache.cachix.org"
    ];

    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
      "pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmVO9Jg="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "viperml.cachix.org-1:qrxbEKGdajQ+s0pzofucGqUKqkjT+N3c5vy7mOML04c="
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
      "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      # Add your custom cache key here:
      # "your-cache.cachix.org-1:YourPublicKey"
    ];
  };

  inputs = {
    # === Core Infrastructure ===
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # System configuration frameworks
    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === System Management ===
    flakehub = {
      url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === macOS Specific ===
    mac-app-util.url = "github:hraban/mac-app-util";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-j178 = {
      url = "github:j178/homebrew-tap";
      flake = false;
    };

    # === NixOS Desktop Environment ===
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    waybar = {
      url = "github:Alexays/Waybar";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    swww = {
      url = "github:LGFae/swww";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === NixOS Hardware & Audio ===
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    audio-nix = {
      url = "github:polygon/audio.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    solaar = {
      url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvidia-patch = {
      url = "github:icewind1991/nvidia-patch-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === Cross-Platform Applications ===
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === Resume ===
    jsonresume-nix = {
      url = "github:TaserudConsulting/jsonresume-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === Development Tools ===
    nur.url = "github:nix-community/NUR";

    nh = {
      url = "github:nix-community/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Code Editors (latest features & fixes)
    helix = {
      url = "github:helix-editor/helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Commented out - using stable version from nixpkgs instead (for cached binaries)
    # zed-editor = {
    #   url = "github:zed-industries/zed";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Language toolchains
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Git tools
    lazygit = {
      url = "github:jesseduffield/lazygit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === CLI Tools (Latest Features) ===
    atuin = {
      url = "github:atuinsh/atuin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {self, ...}:
    inputs.flake-parts.lib.mkFlake {inherit inputs self;} {
      imports = [
        ./flake-parts/core.nix
      ];
    };
}
