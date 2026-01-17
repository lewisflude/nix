# Niri Compositor Configuration - Main File
# Combines all niri configuration modules
{
  pkgs,
  config,
  lib,
  inputs,
  system,
  osConfig,
  ...
}:
let
  # Unified theme helper with all theme imports and conveniences
  theme = import ./lib/theme.nix { inherit lib; };

  # Use overlay packages to ensure mesa dependencies match system nixpkgs
  inherit (pkgs) niri-unstable;

  packagesList = import ./packages.nix {
    inherit pkgs inputs system;
  };
  input = import ./input.nix { };
  outputs = import ./outputs.nix { };
  layout = import ./layout.nix {
    inherit lib;
    inherit (theme)
      niriSync
      ;
  };
  window-rules = import ./window-rules.nix {
    inherit lib;
    inherit (theme)
      cornerRadius
      ;
  };
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

  imports = [
    inputs.hyprcursor-phinger.homeManagerModules.hyprcursor-phinger
  ];

  # Configure cursor theme using phinger-cursors package
  home.pointerCursor = {
    name = "phinger-cursors-light";
    package = pkgs.phinger-cursors;
    size = 32;
    gtk.enable = true;
    x11.enable = true; # Enable for XWayland apps (Discord, Slack, Electron)
  };

  # Enable hyprcursor-phinger theme for Wayland
  programs.hyprcursor-phinger.enable = true;

  programs.niri = {
    package = niri-unstable;
    settings = {
      # Prefer server-side decorations (no CSD)
      # This makes Niri draw borders/focus rings around windows instead of behind them
      # Fixes borders showing through semitransparent windows
      prefer-no-csd = true;

      # Hide the "Important Hotkeys" popup at startup
      # Can still be shown with Mod+Shift+Slash
      hotkey-overlay.skip-at-startup = true;

      # Overview settings 
      overview = {
        # Note: backdrop-color disabled until signal-nix provides colors
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
        # Note: NIXOS_OZONE_WL is set system-wide in modules/nixos/features/desktop/graphics.nix
        # Note: DISPLAY is automatically managed by niri >= 25.08 for xwayland-satellite
        # Do NOT set DISPLAY here - let niri export it when X11 clients connect
      };
      # Force specific GPU as primary render device on multi-GPU systems
      # Configured per-host via host.hardware.renderDevice
      debug = lib.mkIf (osConfig.host.hardware.renderDevice or null != null) {
        render-drm-device = osConfig.host.hardware.renderDevice;
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
