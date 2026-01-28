{
  description = "Lewiss NixOS and Nix-Darwin configuration";

  # Note: Binary cache configuration is in modules/shared/core.nix
  # not here in nixConfig, as nixConfig requires --accept-flake-config

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
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
    # TEMPORARY: Disabled due to upstream SBCL/GitLab Common Lisp API issue
    # Re-enable once https://gitlab.common-lisp.net/iterate/iterate is fixed
    # mac-app-util = {
    #   url = "github:hraban/mac-app-util";
    # };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-j178 = {
      url = "github:j178/homebrew-tap";
      flake = false;
    };
    niri = {
      url = "github:sodiboo/niri-flake";
    };
    awww = {
      url = "git+https://codeberg.org/LGFae/awww";
    };
    ironbar = {
      url = "github:JakeStanger/ironbar";
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
    # NH is available in nixpkgs - no need for flake input
    # Using nixpkgs version avoids test failures on Darwin
    # nh = {
    #   url = "github:nix-community/nh";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
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
    comfyui = {
      url = "github:utensils/nix-comfyui";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mcp-home-manager = {
      url = "github:lewisflude/mcp-home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    signal = {
      url = "github:lewisflude/signal-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    signal-ironbar = {
      url = "github:lewisflude/signal-ironbar";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.signal-nix.follows = "signal";
    };
    signal-notifications = {
      url = "github:lewisflude/signal-notifications";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.signal-nix.follows = "signal";
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
    rust-docs-mcp = {
      url = "github:snowmead/rust-docs-mcp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprcursor-phinger = {
      url = "github:jappie3/hyprcursor-phinger";
    };
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=latest";
    };
    # nixpkgs-xr removed - using stable versions from nixpkgs instead
    # wivrn, wayvr, and xrizer are all available in nixpkgs
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
    };
  };

  outputs =
    inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs self; } {
      imports = [
        ./flake-parts/core.nix
        # Disabled: causes "unknown flake output 'topology'" warning
        # inputs.nix-topology.flakeModule
      ];
    };
}
