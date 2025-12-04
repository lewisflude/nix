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
  config = mkIf (cfg.enable && cfg.applications.satty.enable && theme != null) {
    # Satty theme configuration
    # Satty uses TOML configuration with hex color values
    xdg.configFile."satty/config.toml".text = ''
      [general]
      early-exit = true
      initial-tool = "brush"
      copy-command = "wl-copy"
      annotation-size-factor = 2
      output-filename = "${config.home.homeDirectory}/Pictures/Screenshots/satty-%Y%m%d-%H%M%S.png"
      save-after-copy = false
      default-hide-toolbars = false

      [color-palette]
      first = "${theme.colors."accent-focus".hex}"
      second = "${theme.colors."text-primary".hex}"
      third = "${theme.colors."surface-base".hex}"
      fourth = "#FF0000"
      fifth = "#00FF00"
      custom = "${theme.colors."accent-focus".hex}"
    '';
  };
}
