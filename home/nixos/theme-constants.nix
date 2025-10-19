{
  config,
  lib,
  ...
}: let
  # Check if catppuccin palette is available
  hasCatppuccin = lib.hasAttrByPath ["catppuccin" "palette"] config;

  # Use catppuccin palette if available, otherwise use fallback colors
  palette =
    if hasCatppuccin
    then config.catppuccin.palette
    else {
      mauve = "#cba6f7";
      overlay1 = "#7f849c";
      lavender = "#b4befe";
      surface1 = "#45475a";
      red = "#f38ba8";
      base = "#1e1e2e";
    };
in {
  niri.colors = {
    focus-ring = {
      active = palette.mauve;
      inactive = palette.overlay1;
    };
    border = {
      active = palette.lavender;
      inactive = palette.surface1;
      urgent = palette.red;
    };
    shadow = "${palette.base}aa";
    tab-indicator = {
      active = palette.mauve;
      inactive = palette.overlay1;
    };
  };
}
