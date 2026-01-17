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

    # Signal flake provides colors via CSS through theming.signal.ironbar
    # We just configure the layout and widgets here
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

    # CSS styling is provided by Signal flake (theming.signal.ironbar)
    # Signal provides all colors via @define-color variables
    # Don't manually specify colors here - let Signal handle theming
  };
}
