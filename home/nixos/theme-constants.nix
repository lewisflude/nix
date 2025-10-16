{
  config,
  lib,
  ...
}: let
  # The module already gives you the correct flavor's palette!
  inherit (config.catppuccin) palette;
in
  lib.mkIf (lib.hasAttrByPath ["catppuccin" "palette"] config) {
    niri.colors = {
      focus-ring = {
        # The structure is slightly different, but more direct
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
