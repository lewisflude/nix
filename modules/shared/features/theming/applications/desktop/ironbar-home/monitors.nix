{
  pkgs,
  lib ? pkgs.lib,
  hasBattery ? false, # Set true for laptop hosts
  ...
}:
let
  widgets = import ./widgets/default.nix { inherit pkgs lib hasBattery; };

  # Import design tokens for synchronized values
  tokens = import ./tokens.nix;
  inherit (tokens) niriSync;
  inherit (tokens.sizing) barHeight; # "40px" or "48px"

  # Extract numeric values from token strings
  # barHeight and margin come from the 8pt grid system
  barHeightNum = builtins.fromJSON (builtins.head (builtins.match "([0-9]+)px" barHeight));
  marginNum = niriSync.barMargin; # Already a number from tokens
in
{
  monitors = {
    # Primary monitor (Dell ultrawide)
    "DP-3" = {
      position = "top";
      height = barHeightNum;
      layer = "top";
      exclusive_zone = true;
      popup_gap = marginNum + 2; # Slightly more than margin for visual separation
      popup_autohide = false;
      start_hidden = false;
      anchor_to_edges = true;
      icon_theme = "Papirus";
      margin = {
        top = marginNum;
        bottom = 0;
        left = marginNum;
        right = marginNum;
      };
      inherit (widgets) start center end;
    };

    # Secondary monitor (AOC 4K TV)
    "HDMI-A-4" = {
      position = "top";
      height = barHeightNum;
      layer = "top";
      exclusive_zone = true;
      popup_gap = marginNum + 2;
      popup_autohide = false;
      start_hidden = false;
      anchor_to_edges = true;
      icon_theme = "Papirus";
      margin = {
        top = marginNum;
        bottom = 0;
        left = marginNum;
        right = marginNum;
      };
      inherit (widgets) start center end;
    };
  };
}
