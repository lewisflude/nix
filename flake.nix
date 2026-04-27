{
  description = "Lewiss NixOS and Nix-Darwin configuration";

  # Note: Binary cache configuration is in modules/core/nix.nix
  # not here in nixConfig, as nixConfig requires --accept-flake-config

  inputs = {
    # nixos-unstable-small: same source as nixos-unstable but advances daily
    # (smaller required-pass set on Hydra). Trade-off vs FlakeHub's `0.1`:
    # gives up some FlakeHub Cache substitution overlap with the determinate
    # input, but `0.1` actually resolves to the 25.05 stable line, not
    # unstable. Switch to `nixos-unstable` if cache coverage matters more
    # than freshness.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";
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
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
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
      url = "github:AvengeMedia/DankMaterialShell/bcf41ed5caff19e5750f3ef0594088492ecbadbe";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry/9bc138ff4d250300337ea5563edc3a0a79d3c4c9";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    danksearch = {
      url = "github:AvengeMedia/danksearch";
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
    # Pinned by rev — bump deliberately to control when expensive rebuilds happen.
    signal-nix = {
      url = "github:lewisflude/signal-nix/2c7a7746597d12ce56a85725ba653e424aff5cb7";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
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
      url = "github:polygon/audio.nix/0c1b594b941dd46b29da107f03dfc91b34d820dd";
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
