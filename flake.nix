{
  description = "Lewis's NixOS and Nix-Darwin configuration";

  # Note: Binary cache configuration is in modules/nix.nix
  # not here in nixConfig, as nixConfig requires --accept-flake-config

  inputs = {
    # Regular unstable has better binary cache coverage than
    # nixos-unstable-small, which matters for expensive packages like Chromium.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
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
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Per Determinate's guidance, do NOT make this follow our nixpkgs —
    # it would lose FlakeHub Cache coverage for Determinate's own artifacts.
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      # Override nix-homebrew's pinned brew (5.1.14), whose macOS detection
      # returns ":dunno" on this Darwin build and aborts `brew bundle` during
      # darwin activation. 6.0.0+ adds support for newer macOS versions.
      inputs.brew-src.follows = "brew-src";
    };
    brew-src = {
      url = "github:Homebrew/brew/6.0.2";
      flake = false;
    };
    homebrew-core = {
      url = "github:Homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:Homebrew/homebrew-cask";
      flake = false;
    };
    homebrew-bundle = {
      url = "github:Homebrew/homebrew-bundle";
      flake = false;
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned by rev — bump deliberately to control when expensive rebuilds happen.
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/eb5afcdc40ea5446c27e18552ff4a19f9daf9484";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry/fde8456bb08af0715041451592c461af66709b70";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    danksearch = {
      # Pinned to last-good rev: HEAD (ef9b768, 2026-07-14 "migrate to dankgo
      # common modules") ships an inconsistent vendor/modules.txt and fails to
      # build. This rev's upstream vendorHash matches the override in modules/dms.nix.
      url = "github:AvengeMedia/danksearch/1269b4688cc9";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    solaar = {
      url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Bleeding-edge XR/VR packages (wivrn, wayvr, monado, opencomposite, ...).
    # Tracks upstream git, published to nix-community.cachix.org (already
    # trusted via constants.binaryCaches), so no source-build penalty.
    nixpkgs-xr = {
      url = "github:nix-community/nixpkgs-xr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pog = {
      url = "github:jpetrucciani/pog";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # signal-nix is vendored locally under ./vendor/signal-nix (see modules/signal.nix).
    # These are its two runtime dependencies, pinned to the revs it was locked against.
    signal-palette = {
      url = "github:lewisflude/signal-palette/398cafbf15772892350a3cc822e285842e292388";
    };
    nix-colorizer = {
      url = "github:nutsalhan87/nix-colorizer/c9ce6c710f4ed749f773104a8092a3e542dd1d7c";
    };
    devour-flake = {
      url = "github:srid/devour-flake";
      flake = false;
    };
    vpn-confinement = {
      url = "github:Maroka-chan/VPN-Confinement";
    };
    # Pinned by rev — bump deliberately to control when expensive rebuilds happen.
    comfyui = {
      url = "github:utensils/nix-comfyui/8a90889efc8fae81a8e03b8d9a8406c9f8ff425b";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned by rev — bump deliberately to control when expensive rebuilds happen.
    audio-nix = {
      url = "github:polygon/audio.nix/d2a8d0ae02658b688b93e18c6f8c4e88f576db69";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprcursor-phinger = {
      url = "github:jappie3/hyprcursor-phinger";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=latest";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ia-get = {
      url = "github:wimpysworld/ia-get";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    photogimp = {
      url = "github:Diolinux/PhotoGIMP";
      flake = false;
    };
    # Pinned by rev — bump deliberately to control when expensive rebuilds happen.
    claude-desktop-linux = {
      url = "github:k3d3/claude-desktop-linux-flake/b2b040cb68231d2118906507d9cc8fd181ca6308";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs self; } {
      imports = [
        # Dendritic pattern: auto-import all modules
        # This replaces flake-parts/core.nix - all per-system and flake outputs are in modules/
        (inputs.import-tree ./modules)
        # Process-compose needs explicit import (external flake module)
        inputs.process-compose-flake.flakeModule
      ];
    };
}
