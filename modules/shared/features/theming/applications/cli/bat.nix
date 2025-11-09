{
  config,
  lib,
  pkgs,
  themeContext ? null,
  signalPalette ? null, # Backward compatibility
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  # Use themeContext if available, otherwise fall back to signalPalette for backward compatibility
  theme = themeContext.theme or signalPalette;
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
