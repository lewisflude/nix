# Niri Compositor Configuration - Main File
# Combines all niri configuration modules
{
  pkgs,
  config,
  lib,
  inputs,
  system,
  themeLib,
  ...
}:
let
  themeConstants = import ../theme-constants.nix {
    inherit lib themeLib;
  };
  # Use overlay packages to ensure mesa dependencies match system nixpkgs
  inherit (pkgs) niri-unstable;

  packagesList = import ./packages.nix {
    inherit pkgs inputs system;
  };
  input = import ./input.nix { };
  outputs = import ./outputs.nix { };
  layout = import ./layout.nix { inherit themeConstants; };
  window-rules = import ./window-rules.nix { };
  animations = import ./animations.nix { };
  startup = import ./startup.nix {
    inherit
      config
      pkgs
      inputs
      system
      ;
  };
  binds = import ./keybinds/default.nix {
    inherit config pkgs lib;
  };
in
{
  home.packages = packagesList;

  # Make workspace creation script available
  home.file.".local/bin/create-niri-workspaces" = {
    source = ../scripts/create-niri-workspaces.sh;
    executable = true;
  };
  imports = [
  ];
  programs.niri = {
    package = niri-unstable;
    settings = {
      # Prefer server-side decorations (no CSD)
      # This makes Niri draw borders/focus rings around windows instead of behind them
      # Fixes borders showing through semitransparent windows
      prefer-no-csd = true;

      # Overview settings for premium look
      overview = {
        backdrop-color = themeConstants.niri.colors.shadow;
        zoom = 0.5; # Balanced zoom level for good visibility
      };

      # Gestures - optimized for productivity
      gestures = {
        # Hot corners to toggle overview (top-left corner)
        hot-corners.enable = true;

        # Edge scrolling while dragging windows
        dnd-edge-view-scroll = {
          delay-ms = 200;
          trigger-width = 48;
          max-speed = 1000;
        };

        # Workspace switching in overview
        dnd-edge-workspace-switch = {
          delay-ms = 200;
          trigger-height = 48;
          max-speed = 1000;
        };
      };

      # XWayland compatibility layer (auto-detected from PATH)
      xwayland-satellite.enable = true;

      # Screenshots saved to ~/Pictures/Screenshots with timestamp
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

      # Cursor theme and size
      cursor = {
        theme = "phinger-cursors-light";
        size = 32;
      };

      # Environment variables for niri-spawned processes
      environment = {
        # Force Qt apps to use Wayland
        QT_QPA_PLATFORM = "wayland";
        # Remove DISPLAY to prevent X11 fallback
        DISPLAY = null;
        # Enable Wayland for Electron/Chromium apps
        NIXOS_OZONE_WL = "1";
      };
      # Force NVIDIA RTX 4090 as the primary render device
      # Use renderD128 (render node) for optimal performance on multi-GPU systems
      # This ensures Niri doesn't try to use the Intel iGPU for rendering
      debug = {
        render-drm-device = "/dev/dri/renderD128";
      };
    }
    // input
    // outputs
    // layout
    // window-rules
    // animations
    // startup
    // {
      inherit binds;
    };
  };
}
