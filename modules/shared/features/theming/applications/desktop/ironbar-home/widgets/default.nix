# Floating Modular Bar Layout - "Barbell" Design
#
# Three distinct islands implementing Gestalt principles:
# - Start (Navigation): Workspaces
# - Center (Focus): Focused Window Title
# - End (Status): Tray + Controls + Clock + Power
#
# Design Philosophy:
# - Law of Common Region: Widgets grouped by function into islands
# - Asymmetric Balance: Navigation left, Focus center, Status right
# - Visual Hierarchy: Clock as anchor, workspaces for navigation
{
  pkgs,
  lib ? pkgs.lib,
  hasBattery ? false, # Set true for laptop hosts
  ...
}:
let
  # Navigation widgets (Start island)
  workspaces = import ./workspaces.nix { };

  # Focus widget (Center island)
  focused = import ./focused.nix { inherit pkgs; };

  # Status widgets (End island)
  tray = import ./tray.nix { };
  niriLayout = import ./niri-layout.nix { inherit pkgs; };
  brightness = import ./brightness.nix { };
  volume = import ./volume.nix { };
  battery = import ./battery.nix { };
  notifications = import ./notifications.nix { };
  clock = import ./clock.nix { };
  power = import ./power.nix { inherit pkgs; };
in
{
  # Island 1: Navigation
  # Workspaces for spatial orientation
  start = [
    workspaces
  ];

  # Island 2: Focus Context
  # Current window title - the "what am I working on" indicator
  center = [
    focused
  ];

  # Island 3: System Status
  # Ordered to prevent "jitter" from dynamic tray:
  # Fixed controls (left) → Dynamic tray (middle) → Fixed anchors (right)
  # This keeps interactive controls stable while tray expands/contracts harmlessly
  end = [
    niriLayout # Window state indicator (fixed)
    brightness # Hardware control (fixed)
    volume # Hardware control (fixed)
    tray # Communications: dynamic app indicators (expands here)
  ]
  ++ lib.optionals hasBattery [ battery ] # Only on laptops
  ++ [
    notifications # Communications (fixed)
    clock # Time anchor - visual weight (fixed)
    power # Destructive action - Fitts's Law corner target (fixed)
  ];
}
