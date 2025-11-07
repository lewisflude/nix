{
  config,
  lib,
  pkgs,
  scientificPalette ? null,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.scientific;
  theme = scientificPalette;
in
{
  config = mkIf (cfg.enable && cfg.applications.bat.enable && theme != null) {
    programs.bat = {
      config = {
        # Bat uses predefined themes, so we'll select an appropriate one based on mode
        # In the future, we could generate a custom theme file
        theme = if cfg.mode == "light" then "GitHub" else "Monokai Extended";
        italic-text = "always";
        style = "numbers,changes,header";
      };
    };
  };
}
