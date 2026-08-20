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

    # Signal Design System — the user's own OKLCH + APCA theming framework.
    # Provides consistent, perceptually-uniform colours across ~95 app modules.
    # signal-palette is pulled transitively; follows dedupe the shared inputs.
    # Pinned by rev — bump deliberately (it's actively developed upstream).
    signal-nix = {
      url = "github:lewisflude/signal-nix/cd11e720feffd2ab1668ec0e2c8eae9dd037ceb9";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.flake-parts.follows = "flake-parts";
      inputs.import-tree.follows = "import-tree";
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
      # Must track the homebrew-core/cask taps below: newer formulae use DSL
      # features (Homebrew::InstallSteps::DSL#run, Resource::Patch#type) that
      # older brew can't parse, making formulae "unreadable" during activation.
      url = "github:Homebrew/brew/6.0.18";
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
      # Pinned off main nixpkgs: niri-flake HEAD (9ee3e13) still asserts
      # `libdisplay-info_0_2.version == "0.2.0"`, but nixpkgs removed that
      # package (throw alias) on 2026-08-04. Follow the last-good nixpkgs
      # (241313f, which still ships libdisplay-info_0_2 0.2.0) until
      # niri-flake switches to libdisplay-info_0_3/libdisplay-info upstream.
      inputs.nixpkgs.follows = "nixpkgs-niri";
    };
    nixpkgs-niri.url = "github:NixOS/nixpkgs/241313f4e8e508cb9b13278c2b0fa25b9ca27163";
    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned by rev — bump deliberately to control when expensive rebuilds happen.
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/fde8bb64871f5cfd0175145eca5cc5ee66c887c6";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry/422e564cf9a3e1b03f69e4ad5d8743fb70de76fd";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    danksearch = {
      # Pinned by rev — bump deliberately. Upstream fixed the broken
      # vendor/modules.txt in 4b4905e (2026-07-19); keep the vendorHash
      # override in modules/dms.nix in sync when bumping.
      url = "github:AvengeMedia/danksearch/632c2909bb1bb534b574c22c1347de0e6521e58a";
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
    # devenv releases faster than nixos-unstable channel bumps (2.2.3 upstream
    # vs 2.2.1 in the channel). Upstream builds against its own pinned nixpkgs
    # and patched Nix, published to devenv.cachix.org (trusted via
    # constants.binaryCaches), so inputs are deliberately NOT followed --
    # overriding them would forfeit every cache hit and rebuild from source.
    devenv.url = "github:cachix/devenv";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pog = {
      url = "github:jpetrucciani/pog";
      inputs.nixpkgs.follows = "nixpkgs";
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
      url = "github:utensils/nix-comfyui/328374fa65e767378bc09fba9a2fa23b7b8536c1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pinned by rev — bump deliberately to control when expensive rebuilds happen.
    audio-nix = {
      url = "github:polygon/audio.nix/5f5bf980572d476f5ff6b3ae12c4e4da7e6b3d3e";
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
    # KiCAD MCP server (Node/TypeScript, not published to npm or in nixpkgs).
    # Built from source via pkgs/kicad-mcp.nix; consumed by modules/kicad-mcp.nix.
    kicad-mcp-server = {
      url = "github:mixelpixx/KiCAD-MCP-Server";
      flake = false;
    };
  };

  outputs =
    inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs self; } {
      imports = [
        # Dendritic pattern: auto-import all modules
        # This replaces flake-parts/core.nix - all per-system and flake outputs are in modules/
        (inputs.import-tree ./modules)
      ];
    };
}
