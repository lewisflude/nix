# Niri Package Configuration
# Packages required for niri compositor functionality
# Note: satty (screenshot annotation) is in home/nixos/apps/satty.nix
{
  pkgs,
  inputs,
  system,
  ...
}:
[
  # Screenshot tools
  pkgs.grim # Wayland screenshot utility (used in keybinds)
  pkgs.slurp # Screen area selection (used with grim for area screenshots)
  pkgs.hyprpicker # Color picker (used in Mod+Shift+C keybind)

  # Clipboard
  pkgs.wl-clipboard # Wayland clipboard utilities (wl-copy, wl-paste)

  # Display tools
  pkgs.wlr-randr # Display configuration tool
  pkgs.wayland-utils # Wayland debugging utilities
  pkgs.libdrm # Provides modetest for checking DRM/HDR properties
  pkgs.brightnessctl # Screen brightness control

  # Color management
  pkgs.argyllcms # Color calibration (provides dispwin for ICC profiles)
  pkgs.colord-gtk # Color daemon GTK integration
  pkgs.wl-gammactl # Gamma/brightness correction tool

  # X11 compatibility
  pkgs.xwayland-satellite-unstable # XWayland satellite (auto-managed by niri >= 25.08)
  pkgs.labwc # Nested Wayland compositor for X11 apps needing specific positioning
  pkgs.xsel # X11 clipboard utilities for rootful Xwayland integration

  # Window management
  inputs.awww.packages.${system}.awww # Auto window width/height daemon

  # Note: xdg-utils is handled in core-tooling.nix
]
