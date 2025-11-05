{
  description = "Lewiss NixOS and Nix-Darwin configuration";

  nixConfig = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Binary caches for faster builds
    # Best practice: Order matters - fastest/most reliable caches first to minimize query delays
    # Best practice: Limit to 3-8 caches to reduce sequential query time
    # Note: Determinate Nix v3.6.0+ doesn't require install.determinate.systems cache
    #       (you're on v3.12.0, so this is optional but included for FlakeHub flakes)
    #
    # Priority Optimization: Using ?priority=xxx query parameters to control cache query order
    # Lower numbers = higher priority (queried first). This prevents Nix from querying
    # slow/unreliable caches first, which can cause significant delays when a cache times out
    # (5s timeout per cache ? number of caches = potential delay).
    # Reference: https://brianmcgee.uk/posts/2023/12/13/how-to-optimise-substitutions-in-nix/
    extra-substituters = [
      # === Tier 1: Most Reliable General-Purpose Caches (Highest Priority) ===
      # Order: Most comprehensive and reliable caches first to minimize query delays
      # These caches have the highest hit rate for most packages
      "https://nix-community.cachix.org?priority=1" # General community packages (most comprehensive, highest reliability)
      "https://lewisflude.cachix.org?priority=2" # Personal cache (fast if available, but may not have all packages due to frequent updates)
      "https://nixpkgs-wayland.cachix.org?priority=3" # Wayland packages (common in NixOS)
      "https://numtide.cachix.org?priority=4" # General cache (backup for common packages)
      "https://chaotic-nyx.cachix.org?priority=5" # Bleeding-edge packages (NixOS only, but general-purpose)
      "https://nixpkgs-python.cachix.org?priority=6" # Pre-built Python 3.13 packages (only for Home Assistant, not needed for most builds)

      # === Tier 2: Application-Specific Caches (Only queried when specific apps are needed) ===
      # Order: Most commonly used applications first
      "https://niri.cachix.org?priority=7" # Niri compositor
      "https://helix.cachix.org?priority=8" # Helix editor
      "https://ghostty.cachix.org?priority=9" # Ghostty terminal
      "https://yazi.cachix.org?priority=10" # Yazi file manager
      "https://ags.cachix.org?priority=11" # AGS (Aylur's GTK Shell)

      # === Tier 3: Specialized/Optional Caches (Least commonly used) ===
      # Only queried when specific specialized packages are needed
      "https://zed.cachix.org?priority=12" # Zed editor (if used)
      "https://catppuccin.cachix.org?priority=13" # Catppuccin themes (if used)
      "https://devenv.cachix.org?priority=14" # Devenv (if used)
      "https://viperml.cachix.org?priority=15" # ViperML (if used)
      "https://cuda-maintainers.cachix.org?priority=16" # CUDA packages (if used)

      # === Removed Caches (No longer valid/unreachable) ===
      # Note: aseipp-nix-cache removed - HTTP 400 errors, cache no longer valid
      # Note: FlakeHub cache removed - requires authentication and isn't needed
      #       FlakeHub flakes are downloaded from the API, not the binary cache
      # Note: cache.thalheim.io removed - connection failed
      # Note: cache.garnix.io removed - connection failed
    ];

    extra-trusted-public-keys = [
      # Note: FlakeHub cache key removed - cache requires authentication
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU=" # Python packages cache
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      # Note: cache.thalheim.io key removed - cache connection failed
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "viperml.cachix.org-1:qrxbEKGdajQ+s0pzofucGqUKqkjT+N3c5vy7mOML04c="
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
      "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
      "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
      # Note: cache.garnix.io key removed - cache connection failed
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
    nixpkgs-python.url = "github:cachix/nixpkgs-python";
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
    # NOTE: Helix is now provided via chaotic-packages overlay (bleeding-edge helix_git)
    # This input is kept for backward compatibility but may be removed in future
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

  outputs =
    inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs self; } {
      imports = [
        ./flake-parts/core.nix
        inputs.nix-topology.flakeModule
      ];
    };
}
