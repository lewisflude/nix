{
  description = "Lewiss NixOS and Nix-Darwin configuration";

  # Note: Binary cache configuration is in modules/core/nix.nix
  # not here in nixConfig, as nixConfig requires --accept-flake-config

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # TEMPORARY: Disabled due to upstream SBCL/GitLab Common Lisp API issue
    # Re-enable once https://gitlab.common-lisp.net/iterate/iterate is fixed
    # mac-app-util = {
    #   url = "github:hraban/mac-app-util";
    # };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    awww = {
      url = "git+https://codeberg.org/LGFae/awww";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms-plugin-registry = {
      url = "github:AvengeMedia/dms-plugin-registry";
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

    # NH is available in nixpkgs - no need for flake input
    # Using nixpkgs version avoids test failures on Darwin
    # nh = {
    #   url = "github:nix-community/nh";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
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
    signal-nix = {
      url = "github:lewisflude/signal-nix";
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
    comfyui = {
      url = "github:utensils/nix-comfyui";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    audio-nix = {
      url = "github:polygon/audio.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # yknotify-rs: Disabled - upstream flake has build issues on macOS
    # Missing darwin.apple_sdk.frameworks in buildInputs
    # Use manual install instead: go install github.com/noperator/yknotify@latest
    # yknotify-rs = {
    #   url = "github:reo101/yknotify-rs";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
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
    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
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
    claude-desktop-linux = {
      url = "github:k3d3/claude-desktop-linux-flake";
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
