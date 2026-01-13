# Niri Package Configuration
{
  pkgs,
  inputs,
  system,
  ...
}:
[
  pkgs.grimblast
  pkgs.wl-clipboard
  pkgs.wlr-randr
  pkgs.wayland-utils
  pkgs.brightnessctl
  # Note: xdg-utils is handled in core-tooling.nix
  pkgs.xwayland-satellite-unstable
  pkgs.argyllcms
  pkgs.colord-gtk
  pkgs.wl-gammactl
  pkgs.libdrm # Provides modetest for checking DRM/HDR properties
  # X11 compatibility tools
  pkgs.labwc # Nested Wayland compositor for X11 apps that need specific positioning
  pkgs.xsel # X11 clipboard utilities for rootful Xwayland integration
  inputs.awww.packages.${system}.awww
]
