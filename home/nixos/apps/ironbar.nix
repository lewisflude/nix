# Ironbar Desktop Status Bar
# Platform: NixOS (Linux)
# Status bar for Niri compositor with Signal theme colors
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Import all widget definitions
  widgets = {
    workspaces = import ./ironbar/widgets/workspaces.nix { };
    focused = import ./ironbar/widgets/focused.nix { inherit pkgs; };
    niriLayout = import ./ironbar/widgets/niri-layout.nix { inherit pkgs; };
    brightness = import ./ironbar/widgets/brightness.nix { };
    volume = import ./ironbar/widgets/volume.nix { };
    battery = import ./ironbar/widgets/battery.nix { };
    tray = import ./ironbar/widgets/tray.nix { };
    notifications = import ./ironbar/widgets/notifications.nix { };
    clock = import ./ironbar/widgets/clock.nix { };
    power = import ./ironbar/widgets/power.nix { inherit pkgs; };
  };

  # Check if this host has a battery (for conditional battery widget)
  # You can override this per-host if needed
  hasBattery = false; # Set to true for laptop hosts
in
{
  programs.ironbar = {
    enable = true;

    # Import Signal color palette and apply custom styling
    style = pkgs.writeText "ironbar-style.css" ''
      /**
       * IRONBAR STYLESHEET
       * Imports Signal color palette and applies custom styling
       */

      /* Import Signal color definitions from signal-nix */
      @import url("${config.theming.signal.colors.ironbar.cssFile}");

      /* =============================================================================
         BASE STYLES
         ============================================================================= */

      * {
        font-family: monospace;
        font-size: 14px;
      }

      .background {
        background-color: transparent;
      }

      #bar {
        background-color: transparent;
        margin: 12px;
      }

      /* =============================================================================
         WIDGETS & COMPONENTS - Using Signal Colors
         ============================================================================= */

      /* Text Styling */
      label {
        color: @text_primary;
      }

      /* Workspaces */
      .workspaces button {
        color: @text_tertiary;
        background-color: transparent;
        border: none;
        padding: 4px 8px;
        margin: 0 4px;
        border-radius: 12px;
      }

      .workspaces button.focused {
        color: @text_primary;
        border-left: 3px solid @accent_focus;
        border-top-left-radius: 0;
        border-bottom-left-radius: 0;
      }

      .workspaces button:hover {
        color: @text_primary;
      }

      /* Window Title */
      .focused {
        padding: 4px 20px;
      }

      .focused label {
        color: @text_secondary;
      }

      .focused.active {
        border-left: 3px solid @accent_focus;
        border-top-left-radius: 0;
        border-bottom-left-radius: 0;
      }

      .focused.active label {
        color: @text_primary;
      }

      /* Control Buttons */
      button {
        background-color: transparent;
        border: none;
        color: @text_primary;
      }

      button:hover {
        opacity: 1.0;
      }

      /* System Tray */
      .tray .item {
        padding: 4px;
        margin: 0 3px;
        border-radius: 10px;
      }

      /* Battery */
      .battery {
        font-family: monospace;
      }

      .battery.warning {
        color: @accent_warning;
        border-left: 3px solid @accent_warning;
      }

      .battery.critical {
        color: @accent_danger;
        border-left: 3px solid @accent_danger;
      }

      /* Clock */
      .clock {
        font-family: monospace;
        color: @text_primary;
        padding: 0 16px;
      }

      /* Power Button */
      .power {
        color: @accent_danger;
      }

      /* Notifications */
      .notifications {
        padding: 0 8px;
      }

      /* =============================================================================
         LAYOUT (Islands) - Using Signal Surface Colors
         ============================================================================= */

      #bar #start,
      #bar #center,
      #bar #end {
        background-color: @surface_base;
        border: 2px solid @surface_emphasis;
        border-radius: 16px;
        padding: 4px 16px;
      }

      #bar #start {
        margin-right: 16px;
      }

      #bar #center {
        margin: 0 8px;
      }

      #bar #end {
        margin-left: 16px;
      }
    '';

    config = {
      position = "top";
      height = 40;
      layer = "top";
      exclusive_zone = true;
      popup_gap = 10;
      popup_autohide = false;
      start_hidden = false;
      anchor_to_edges = true;
      icon_theme = "Papirus";

      margin = {
        top = 8;
        bottom = 0;
        left = 8;
        right = 8;
      };

      # Floating Modular Bar Layout - "Barbell" Design
      #
      # Three distinct islands implementing Gestalt principles:
      # - Start (Navigation): Workspaces
      # - Center (Focus): Focused Window Title
      # - End (Status): Tray + Controls + Clock + Power

      # Island 1: Navigation - Workspaces for spatial orientation
      start = [
        widgets.workspaces
      ];

      # Island 2: Focus Context - Current window title
      center = [
        widgets.focused
      ];

      # Island 3: System Status
      # Ordered to prevent "jitter" from dynamic tray:
      # Fixed controls (left) → Dynamic tray (middle) → Fixed anchors (right)
      end = [
        widgets.niriLayout # Window state indicator (fixed)
        widgets.brightness # Hardware control (fixed)
        widgets.volume # Hardware control (fixed)
        widgets.tray # Communications: dynamic app indicators (expands here)
      ]
      ++ lib.optionals hasBattery [ widgets.battery ] # Only on laptops
      ++ [
        widgets.notifications # Communications (fixed)
        widgets.clock # Time anchor - visual weight (fixed)
        widgets.power # Destructive action - Fitts's Law corner target (fixed)
      ];
    };
  };
}
