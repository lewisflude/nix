{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: let
  # Use FULL Catppuccin palette - not base16 subset
  # This gives us access to all semantic colors: mauve, lavender, sky, overlay1, surface1, etc.
  # Uses catppuccin.nix module palette when available, falls back to direct input access
  catppuccinPalette =
    if lib.hasAttrByPath ["catppuccin" "sources" "palette"] config
    then
      # Use catppuccin.nix module palette if available
      (pkgs.lib.importJSON (config.catppuccin.sources.palette + "/palette.json"))
      .${config.catppuccin.flavor}.colors
    else
      # Try to get palette directly from catppuccin input
      # catppuccin/nix repository has palette.json at the root
      let
        catppuccinSrc =
          inputs.catppuccin.src or inputs.catppuccin.outPath or (throw "Cannot find catppuccin source");
      in
        (pkgs.lib.importJSON (catppuccinSrc + "/palette.json")).mocha.colors;
in {
  niri.colors = {
    focus-ring = {
      active = catppuccinPalette.mauve.hex; # Mauve (accent color)
      inactive = catppuccinPalette.overlay1.hex; # Overlay 1 (more accurate than base16 base03)
    };
    border = {
      active = catppuccinPalette.lavender.hex; # Lavender (more accurate than sky)
      inactive = catppuccinPalette.surface1.hex; # Surface 1 (semantic naming)
      urgent = catppuccinPalette.red.hex; # Red
    };
    shadow = "${catppuccinPalette.base.hex}aa"; # Base with transparency
    tab-indicator = {
      active = catppuccinPalette.mauve.hex; # Mauve
      inactive = catppuccinPalette.overlay1.hex; # Overlay 1
    };
  };
}
