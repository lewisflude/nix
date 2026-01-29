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
  # Use overlay packages to ensure mesa dependencies match system nixpkgs
  inherit (pkgs) niri-unstable;

  # Import consolidated modules
  outputs = import ./outputs.nix { };
  window-rules = import ./window-rules.nix { };
  keybinds = import ./keybinds.nix {
    inherit config pkgs lib;
  };
  unified-config = import ./config.nix {
    inherit pkgs config inputs system;
  };
in
{
  imports = [
    inputs.hyprcursor-phinger.homeManagerModules.hyprcursor-phinger
  ];

  # Packages required for niri compositor functionality
  home.packages = [
    # Screenshot tools
    pkgs.grim # Wayland screenshot utility (used in keybinds)
    pkgs.slurp # Screen area selection (used with grim for area screenshots)

    # Clipboard
    pkgs.wl-clipboard # Wayland clipboard utilities (wl-copy, wl-paste)

    # Display tools
    pkgs.wlr-randr # Display configuration tool
    pkgs.wayland-utils # Wayland debugging utilities
    pkgs.libdrm # Provides modetest for checking DRM/HDR properties

    # Color management
    pkgs.argyllcms # Color calibration (provides dispwin for ICC profiles)
    pkgs.wl-gammactl # Gamma/brightness correction tool

    # X11 compatibility (see niri docs: XWayland.md)
    pkgs.xwayland-satellite-unstable # XWayland satellite >= 0.7 (auto-managed by niri >= 25.08)

    # Wallpaper
    inputs.awww.packages.${system}.awww # "An Answer to your Wayland Wallpaper Woes"

    # Note: xdg-utils is handled in core-tooling.nix
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
        # Note: ELECTRON_OZONE_PLATFORM_HINT is set system-wide in modules/nixos/features/desktop/graphics.nix
        # Note: DISPLAY is automatically managed by niri >= 25.08 for xwayland-satellite
        # Do NOT set DISPLAY here - let niri export it when X11 clients connect
      };

      # Force specific GPU as primary render device on multi-GPU systems
      # Configured per-host via host.hardware.renderDevice
      debug = lib.mkIf (osConfig.host.hardware.renderDevice or null != null) {
        render-drm-device = osConfig.host.hardware.renderDevice;
      };
    }
    // outputs
    // window-rules
    // keybinds
    // unified-config;
  };
}
