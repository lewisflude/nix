{
  pkgs,
  config,
  lib,
  ...
}: let
  # Assert that catppuccin is configured - fail fast with clear error
  hasCatppuccin = lib.hasAttrByPath ["catppuccin" "sources" "palette"] config;

  palette = assert lib.assertMsg hasCatppuccin
  ''
    Catppuccin theme is not configured!
    Make sure you have enabled catppuccin in your configuration:
      catppuccin.enable = true;
      catppuccin.flavor = "mocha"; # or your preferred flavor
  '';
    (pkgs.lib.importJSON (config.catppuccin.sources.palette + "/palette.json")).${config.catppuccin.flavor}.colors;
in {
  niri.colors = {
    focus-ring = {
      active = palette.mauve.hex;
      inactive = palette.overlay1.hex;
    };
    border = {
      active = palette.lavender.hex;
      inactive = palette.surface1.hex;
      urgent = palette.red.hex;
    };
    shadow = "${palette.base.hex}aa";
    tab-indicator = {
      active = palette.mauve.hex;
      inactive = palette.overlay1.hex;
    };
  };
}
