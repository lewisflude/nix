{
  config,
  lib,
  themeContext ? null,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  inherit (themeContext) theme;
in
{
  config = mkIf (cfg.enable && cfg.applications.swappy.enable && theme != null) {
    # Swappy theme configuration
    # Swappy uses INI-style configuration with hex color values
    xdg.configFile."swappy/config".text = ''
      [Default]
      # Fill color with 50% opacity (80 in hex = 128/255 ≈ 50%)
      fill_color=${theme.colors."surface-base".hex}80
      # Line color with full opacity
      line_color=${theme.colors."accent-focus".hex}ff
      # Text color with full opacity
      text_color=${theme.colors."text-primary".hex}ff
    '';
  };
}
