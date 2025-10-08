{
  config,
  pkgs,
  ...
}: let
  # Dynamic Catppuccin color palette access
  # Based on solution from https://github.com/catppuccin/nix/issues/285
  palette = (pkgs.lib.importJSON (config.catppuccin.sources.palette + "/palette.json")).${config.catppuccin.flavor}.colors;
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
