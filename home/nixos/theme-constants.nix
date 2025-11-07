{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
let

  catppuccinPalette =
    if lib.hasAttrByPath [ "catppuccin" "sources" "palette" ] config then

      (pkgs.lib.importJSON (config.catppuccin.sources.palette + "/palette.json"))
      .${config.catppuccin.flavor}.colors
    else if inputs ? catppuccin then

      let
        catppuccinSrc = inputs.catppuccin.src or inputs.catppuccin.outPath or null;
      in
      if catppuccinSrc != null then
        (pkgs.lib.importJSON (catppuccinSrc + "/palette.json")).mocha.colors
      else
        throw "Cannot find catppuccin source (input exists but src/outPath not found)"
    else
      throw "Cannot find catppuccin: input not available and config.catppuccin.sources.palette not set";
in
{
  # Use mkDefault so Scientific theme can override these Catppuccin colors
  niri.colors = {
    focus-ring = {
      active = lib.mkDefault catppuccinPalette.mauve.hex;
      inactive = lib.mkDefault catppuccinPalette.overlay1.hex;
    };
    border = {
      active = lib.mkDefault catppuccinPalette.lavender.hex;
      inactive = lib.mkDefault catppuccinPalette.surface1.hex;
      urgent = lib.mkDefault catppuccinPalette.red.hex;
    };
    shadow = lib.mkDefault "${catppuccinPalette.base.hex}aa";
    tab-indicator = {
      active = lib.mkDefault catppuccinPalette.mauve.hex;
      inactive = lib.mkDefault catppuccinPalette.overlay1.hex;
    };
  };
}
