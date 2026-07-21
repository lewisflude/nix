# Signal Design System - Multi-Machine Example
# Shared Signal configuration across multiple machines

{
  description = "Multi-machine Home Manager configuration with Signal";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    signal.url = "github:lewisflude/signal-nix";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      signal,
      ...
    }:
    let
      # Common configuration shared across all machines
      commonModules = [
        signal.homeManagerModules.default
        ./common/signal.nix # Shared Signal config
        ./common/programs.nix # Common programs
      ];
    in
    {
      homeConfigurations = {
        # Desktop: 4K display, full GUI setup
        "user@desktop" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = commonModules ++ [
            ./hosts/desktop.nix
            {
              home = {
                username = "user";
                homeDirectory = "/home/user";
                stateVersion = "24.11";
              };
            }
          ];
        };

        # Laptop: 1080p display, portable setup
        "user@laptop" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = commonModules ++ [
            ./hosts/laptop.nix
            {
              home = {
                username = "user";
                homeDirectory = "/home/user";
                stateVersion = "24.11";
              };
            }
          ];
        };

        # Work Laptop: 1440p display, work-specific tools
        "user@work" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = commonModules ++ [
            ./hosts/work.nix
            {
              home = {
                username = "user";
                homeDirectory = "/home/user";
                stateVersion = "24.11";
              };
            }
          ];
        };

        # Server: CLI only, no GUI
        "user@server" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = commonModules ++ [
            ./hosts/server.nix
            {
              home = {
                username = "user";
                homeDirectory = "/home/user";
                stateVersion = "24.11";
              };
            }
          ];
        };

        # MacBook: macOS with nix-darwin
        "user@macbook" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          modules = commonModules ++ [
            ./hosts/macbook.nix
            {
              home = {
                username = "user";
                homeDirectory = "/Users/user";
                stateVersion = "24.11";
              };
            }
          ];
        };
      };
    };
}

# ============================================================================
# FILE: common/signal.nix
# Shared Signal configuration across all machines
# ============================================================================
#
# { ... }:
#
# {
#   theming.signal = {
#     enable = true;
#     autoEnable = true;  # Auto-theme all enabled programs
#     mode = "dark";
#
#     # Brand colors consistent across all machines
#     brandGovernance = {
#       policy = "functional-override";
#       decorativeBrandColors = {
#         brand-primary = "#5a7dcf";
#         brand-secondary = "#4a9b6f";
#       };
#     };
#   };
# }

# ============================================================================
# FILE: common/programs.nix
# Programs enabled on most machines
# ============================================================================
#
# { ... }:
#
# {
#   programs = {
#     # Core editor setup (all machines)
#     helix = {
#       enable = true;
#       settings = {
#         # Shared helix settings
#       };
#     };
#
#     # CLI tools (all machines)
#     bat.enable = true;
#     fzf.enable = true;
#     starship.enable = true;
#
#     # Git (all machines)
#     git = {
#       enable = true;
#       # Shared git config
#     };
#   };
# }

# ============================================================================
# FILE: hosts/desktop.nix
# Desktop-specific configuration (4K display, full GUI)
# ============================================================================
#
# { ... }:
#
# {
#   # Desktop has full GUI setup
#   programs = {
#     # Terminal emulator
#     kitty = {
#       enable = true;
#       settings = {
#         font_size = 12; # Larger font for 4K
#       };
#     };
#
#     # GUI apps
#     firefox.enable = true;
#   };
#
#   # GTK theming
#   gtk.enable = true;
#
#   # Wayland compositor
#   wayland.windowManager.hyprland.enable = true;
#
#   # Desktop programs
#   programs.ironbar.enable = true;
#   programs.fuzzel.enable = true;
#
#   # Desktop-specific Signal settings
#   theming.signal = {
#     ironbar = {
#       enable = true;
#       profile = "spacious"; # 4K display
#     };
#     gtk = {
#       enable = true;
#       version = "both";
#     };
#     fuzzel.enable = true;
#   };
# }

# ============================================================================
# FILE: hosts/laptop.nix
# Laptop-specific configuration (1080p, portable)
# ============================================================================
#
# { ... }:
#
# {
#   # Laptop has lighter setup for battery life
#   programs = {
#     # Lighter terminal
#     alacritty = {
#       enable = true;
#       settings = {
#         font.size = 10; # Smaller for 1080p
#       };
#     };
#
#     # Minimal GUI
#     firefox.enable = true;
#   };
#
#   gtk.enable = true;
#
#   # Laptop-specific Signal settings
#   theming.signal = {
#     ironbar = {
#       enable = true;
#       profile = "compact"; # 1080p laptop
#     };
#     gtk.enable = true;
#   };
# }

# ============================================================================
# FILE: hosts/work.nix
# Work laptop configuration (1440p, work tools)
# ============================================================================
#
# { ... }:
#
# {
#   programs = {
#     # Work terminal
#     ghostty = {
#       enable = true;
#       settings = {
#         font-size = 11;
#       };
#     };
#
#     # Work-specific tools
#     slack.enable = true;
#     teams.enable = true;
#
#     # Development tools
#     vscode.enable = true;
#   };
#
#   gtk.enable = true;
#
#   # Work-specific Signal settings
#   theming.signal = {
#     ironbar = {
#       enable = true;
#       profile = "relaxed"; # 1440p work laptop
#     };
#     gtk.enable = true;
#   };
# }

# ============================================================================
# FILE: hosts/server.nix
# Server configuration (CLI only, no GUI)
# ============================================================================
#
# { ... }:
#
# {
#   # Server: CLI tools only
#   programs = {
#     # Terminal multiplexer for remote sessions
#     tmux = {
#       enable = true;
#       # Tmux config
#     };
#
#     # Server monitoring
#     btop.enable = true;
#
#     # No GUI applications
#   };
#
#   # Server-specific Signal settings
#   theming.signal = {
#     # Theme CLI tools only
#     multiplexers.tmux.enable = true;
#     monitors.btop.enable = true;
#
#     # No GUI theming
#     ironbar.enable = false;
#     gtk.enable = false;
#   };
# }

# ============================================================================
# FILE: hosts/macbook.nix
# macOS configuration (Apple Silicon)
# ============================================================================
#
# { ... }:
#
# {
#   # macOS-specific programs
#   programs = {
#     # Terminal
#     alacritty.enable = true;
#
#     # macOS apps
#     # ...
#   };
#
#   # macOS-specific Signal settings
#   theming.signal = {
#     # Most programs work the same on macOS
#     # Ironbar is Linux-only, so it won't be available
#   };
# }

# ============================================================================
# REBUILD SPECIFIC MACHINES
# ============================================================================
#
# Desktop:
#   home-manager switch --flake .#user@desktop
#
# Laptop:
#   home-manager switch --flake .#user@laptop
#
# Work:
#   home-manager switch --flake .#user@work
#
# Server:
#   home-manager switch --flake .#user@server
#
# MacBook:
#   home-manager switch --flake .#user@macbook

# ============================================================================
# AUTOMATIC MACHINE DETECTION
# ============================================================================
#
# You can detect the current machine and apply configs automatically:
#
# let
#   hostname = builtins.readFile /etc/hostname;
#
#   isDesktop = hostname == "desktop\n";
#   isLaptop = hostname == "laptop\n";
#   isWork = hostname == "work\n";
#
#   # Automatic ironbar profile based on hostname
#   ironbarProfile =
#     if isDesktop then "spacious"
#     else if isWork then "relaxed"
#     else "compact";
# in
# {
#   theming.signal.ironbar.profile = ironbarProfile;
# }

# ============================================================================
# SYNCING CHANGES ACROSS MACHINES
# ============================================================================
#
# Workflow for updating all machines:
#
# 1. Make changes to common files (common/signal.nix, etc.)
# 2. Commit and push to git
# 3. On each machine:
#    cd ~/.config/home-manager
#    git pull
#    home-manager switch --flake .#user@$(hostname -s)
#
# Or use a script:
#
# #!/usr/bin/env bash
# # sync-config.sh
# cd ~/.config/home-manager
# git pull
# home-manager switch --flake .#user@$(hostname -s)

# ============================================================================
# CONDITIONAL FEATURES BY MACHINE TYPE
# ============================================================================
#
# { config, lib, ... }:
#
# let
#   # Detect machine characteristics
#   isLinux = config.home.os == "linux";
#   isDarwin = config.home.os == "darwin";
#
#   # Detect if running on server (no display)
#   hasDisplay = builtins.getEnv "DISPLAY" != "";
#
#   # Enable GUI only on machines with displays
#   enableGUI = hasDisplay && isLinux;
# in
# {
#   theming.signal = {
#     enable = true;
#     autoEnable = true;
#
#     # GUI theming only on machines with displays
#     ironbar.enable = enableGUI;
#     gtk.enable = enableGUI;
#     fuzzel.enable = enableGUI;
#   };
# }

# ============================================================================
# TIPS FOR MULTI-MACHINE SETUPS
# ============================================================================
#
# 1. Use shared config for Signal mode:
#    All machines use the same light/dark mode
#
# 2. Per-machine ironbar profiles:
#    Adjust based on display resolution
#
# 3. Conditional program enablement:
#    Servers: CLI only
#    Laptops: Lightweight programs
#    Desktop: Full featured
#
# 4. Shared brand colors:
#    Consistent identity across all machines
#
# 5. Version control:
#    Keep config in git for easy sync
#
# 6. Test changes on one machine first:
#    home-manager switch --flake .#user@laptop
#    If good, roll out to others
