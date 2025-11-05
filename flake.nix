{
  description = "Lewiss NixOS and Nix-Darwin configuration";

  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
      "ca-derivations"
      "fetch-closure"
      "parse-toml-timestamps"
      "build-time-fetch-tree" # Enables build-time input fetching for inputs marked with buildTime = true
      "blake3-hashes" # Faster hashing algorithm (BLAKE3)
      "verified-fetches" # Verify git commit signatures via fetchGit
      "pipe-operators" # |> and <| operators for cleaner Nix code
      "no-url-literals" # Disallow unquoted URLs (prevents deprecated syntax)
      "git-hashing" # Git hashing for content-addressed store objects
    ];

    # Binary caches for faster builds
    # Note: Order matters - personal cache first for fastest access
    # Note: Determinate Nix v3.6.0+ doesn't require install.determinate.systems cache
    #       (you're on v3.12.0, so this is optional but included for FlakeHub flakes)
    extra-substituters = [
      "https://lewisflude.cachix.org" # Personal cache - highest priority
      "https://aseipp-nix-cache.freetls.fastly.net" # Cache v2 beta (IPv6 + HTTP/2 support, faster TTFB, improved routing)
      # Note: FlakeHub cache removed - requires authentication and isn't needed
      # FlakeHub flakes are downloaded from the API, not the binary cache
      "https://nix-community.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://helix.cachix.org"
      "https://cache.thalheim.io"
      "https://numtide.cachix.org"
      "https://viperml.cachix.org"
      "https://catppuccin.cachix.org"
      "https://niri.cachix.org"
      "https://ghostty.cachix.org"
      "https://zed.cachix.org"
      "https://cache.garnix.io"
      "https://chaotic-nyx.cachix.org" # Bleeding-edge packages (NixOS only)
      "https://ags.cachix.org"
      "https://devenv.cachix.org"
      "https://yazi.cachix.org"
      "https://cuda-maintainers.cachix.org"
    ];

    extra-trusted-public-keys = [
      # Note: FlakeHub cache key removed - cache requires authentication
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      "cache.thalheim.io-1:R7msbosLEZKrxk/lKxf9BTjOOH7Ax3H0Qj0/6wiHOgc="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "viperml.cachix.org-1:qrxbEKGdajQ+s0pzofucGqUKqkjT+N3c5vy7mOML04c="
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
      "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8=" # Bleeding-edge packages
      "lewisflude.cachix.org-1:Y4J8FK/Rb7Es/PnsQxk2ZGPvSLup6ywITz8nimdVWXc=" # Personal cache
      "ags.cachix.org-1:naAvMrz0CuYqeyGNyLgE010iUiuf/qx6kYrUv3NwAJ8="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
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
    # FlakeHub CLI tool for managing flakes (used in home/common/apps/core-tooling.nix)
    flakehub = {
      url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
    };

    # Secrets management with SOPS encryption (used in system-builders.nix for both platforms)
    sops-nix = {
      url = "https://flakehub.com/f/Mic92/sops-nix/*.tar.gz";
    };

    # === macOS Specific ===
    # macOS application utilities - provides mac-app-util modules
    # Used in: lib/system-builders.nix (mkDarwinSystem), home manager modules
    mac-app-util.url = "github:hraban/mac-app-util";

    # Homebrew integration for Nix-Darwin - provides nix-homebrew modules
    # Used in: lib/system-builders.nix (mkDarwinSystem) for Homebrew tap configuration
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Homebrew tap for j178 formulas - used by nix-homebrew during macOS builds
    # Used in: lib/system-builders.nix (mkDarwinSystem) via nix-homebrew taps configuration
    homebrew-j178 = {
      url = "github:j178/homebrew-tap";
      flake = false;
    };

    # === NixOS Desktop Environment ===
    # Niri Wayland compositor (used in system-builders.nix and overlays/default.nix)
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Bleeding-edge packages for NixOS (gaming, desktop, audio)
    # Used in system-builders.nix for chaotic.nixosModules.default
    # Do NOT follow nixpkgs - this breaks their cache
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      # Do NOT follow nixpkgs - this breaks their cache
    };

    # === NixOS Audio ===
    # Real-time audio kernel configuration (used in system-builders.nix)
    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Audio production packages and Bitwig Studio (used in overlays/default.nix)
    audio-nix = {
      url = "github:polygon/audio.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Solaar Logitech device manager (used in system-builders.nix)
    solaar = {
      url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NVIDIA GPU patch for NixOS (used in overlays/default.nix, Linux-only)
    nvidia-patch = {
      url = "github:icewind1991/nvidia-patch-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === Hardware Configuration ===
    # Hardware-specific NixOS modules (used in hosts/*/hardware-configuration.nix)
    # PERFORMANCE NOTE (Tip 11): This input could potentially be marked as build-time-only
    # since hardware-specific modules are typically only needed during realization,
    # not during general evaluation. Research Determinate Nix syntax for this.
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
    };

    # === Cross-Platform Applications ===
    # Catppuccin color scheme (used in system-builders.nix and home manager)
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Ghostty terminal emulator (used in pkgs/ghostty/default.nix and home/nixos/)
    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === Resume ===
    # JSON Resume generator (used in home/common/features/productivity/resume.nix)
    jsonresume-nix = {
      url = "https://flakehub.com/f/TaserudConsulting/jsonresume-nix/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === Development Tools ===
    # Nix User Repository - community packages (used in system-builders.nix)
    nur.url = "github:nix-community/NUR";

    # nh - NixOS helper tool (used via home/common/nh.nix)
    nh = {
      url = "https://flakehub.com/f/nix-community/nh/4.2.0-beta5.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pre-commit hooks for code quality (used in lib/output-builders.nix)
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Code Editors (latest features & fixes)
    # Helix editor (used in overlays/default.nix)
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
    # Rust toolchain overlay (used in overlays/default.nix)
    rust-overlay = {
      url = "https://flakehub.com/f/oxalica/rust-overlay/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Git tools
    # LazyGit terminal UI for Git (used in overlays/default.nix)
    lazygit = {
      url = "github:jesseduffield/lazygit";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === CLI Tools (Latest Features) ===
    # Atuin shell history (used in overlays/default.nix)
    atuin = {
      url = "github:atuinsh/atuin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === Script Tooling ===
    # POG - Nix script framework (used in flake-parts/core.nix and pkgs/pog-scripts/)
    pog = {
      url = "github:jpetrucciani/pog";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === Infrastructure Visualization ===
    # Nix topology visualization (used in flake.nix and system-builders.nix)
    nix-topology = {
      url = "github:oddlama/nix-topology";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === VPN Confinement ===
    # VPN network namespace isolation for qBittorrent (used in system-builders.nix)
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
  };

  outputs = inputs @ {self, ...}:
    inputs.flake-parts.lib.mkFlake {inherit inputs self;} {
      imports = [
        ./flake-parts/core.nix
        inputs.nix-topology.flakeModule
      ];
    };
}
