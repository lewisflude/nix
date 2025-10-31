{
  pkgs,
  inputs,
  system,
  ...
}: let
  # Use FULL Catppuccin palette - not base16 subset
  # This gives us access to all semantic colors: mauve, lavender, sky, overlay1, surface1, etc.
  catppuccinPalette =
    pkgs.lib.importJSON
    (
      inputs.catppuccin.packages.${system}.catppuccin-gtk-theme.src + "/palette.json"
    ).mocha.colors;
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
