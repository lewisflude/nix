{
  description = "Lewiss NixOS and Nix-Darwin configuration";

  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
      "ca-derivations"
      "eval-cache" # Cache evaluation results for faster flake evaluation
    ];

    # Binary caches for faster builds
    # Note: Order matters - personal cache first for fastest access
    extra-substituters = [
      "https://lewisflude.cachix.org" # Personal cache - highest priority
      "https://nix-community.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://helix.cachix.org"
      "https://cache.thalheim.io"
      # "https://pre-commit-hooks.cachix.org" # Removed - pre-commit-hooks input not actively used
      "https://numtide.cachix.org"
      "https://viperml.cachix.org"
      "https://catppuccin.cachix.org"
      "https://niri.cachix.org"
      "https://ghostty.cachix.org"
      "https://zed.cachix.org"
      "https://cache.garnix.io"
      "https://chaotic-nyx.cachix.org" # Bleeding-edge packages (NixOS only)
      "https://lewisflude.cachix.org" # Personal binary cache
    ];

    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
      # "pre-commit-hooks.cachix.org-1:Pkk3Panw5AW24TOv6kz3PvLhlH8puAsJTBbOPmVO9Jg=" # Removed with cache
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "viperml.cachix.org-1:qrxbEKGdajQ+s0pzofucGqUKqkjT+N3c5vy7mOML04c="
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
      "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8=" # Bleeding-edge packages
      "lewisflude.cachix.org-1:Y4J8FK/Rb7Es/PnsQxk2ZGPvSLup6ywITz8nimdVWXc=" # Personal cache
    ];
  };

  inputs = {
    # === Core Infrastructure ===
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";
    flake-parts = {
      url = "https://flakehub.com/f/hercules-ci/flake-parts/*";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

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

    # === System Management ===
    flakehub = {
      url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
    };

    sops-nix = {
      url = "https://flakehub.com/f/Mic92/sops-nix/*.tar.gz";
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

    # Bleeding-edge packages for NixOS (gaming, desktop, audio)
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      # Do NOT follow nixpkgs - this breaks their cache
    };

    # waybar and swww removed - using nixpkgs versions instead
    # The flake inputs were not being used, overlays already deleted

    # === NixOS Audio ===
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
      url = "https://flakehub.com/f/TaserudConsulting/jsonresume-nix/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === Development Tools ===
    nur.url = "github:nix-community/NUR";

    nh = {
      url = "https://flakehub.com/f/nix-community/nh/4.2.0-beta5.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Code Editors (latest features & fixes)
    helix = {
      url = "https://flakehub.com/f/helix-editor/helix/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Commented out - using stable version from nixpkgs instead (for cached binaries)
    # zed-editor = {
    #   url = "github:zed-industries/zed";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # Language toolchains
    rust-overlay = {
      url = "https://flakehub.com/f/oxalica/rust-overlay/*.tar.gz";
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

    # === Script Tooling ===
    pog = {
      url = "github:jpetrucciani/pog";
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
