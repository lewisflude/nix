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
  config = mkIf (cfg.enable && cfg.local.applications.satty.enable && theme != null) {
    # Satty theme configuration
    # Satty uses TOML configuration with hex color values
    xdg.configFile."satty/config.toml".text = ''
      [general]
      fullscreen = true
      early-exit = true
      corner-roundness = 12
      initial-tool = "brush"
      copy-command = "wl-copy"
      annotation-size-factor = 2
      output-filename = "${config.home.homeDirectory}/Pictures/Screenshots/satty-%Y%m%d-%H%M%S.png"
      save-after-copy = false
      default-hide-toolbars = false
      focus-toggles-toolbars = false
      default-fill-shapes = false
      primary-highlighter = "block"
      disable-notifications = false
      no-window-decoration = true
      brush-smooth-history-size = 10

      # Actions on keyboard shortcuts
      actions-on-enter = ["save-to-clipboard"]
      actions-on-escape = ["exit"]

      [keybinds]
      pointer = "p"
      crop = "c"
      brush = "b"
      line = "i"
      arrow = "z"
      rectangle = "r"
      ellipse = "e"
      text = "t"
      marker = "m"
      blur = "u"
      highlight = "g"

      [font]
      family = "Roboto"
      style = "Regular"

      [color-palette]
      palette = [
        "${theme.colors."accent-focus".hex}",
        "${theme.colors."text-primary".hex}",
        "${theme.colors."surface-base".hex}",
        "#FF0000",
        "#00FF00",
        "#FFD700",
      ]

      custom = [
        "${theme.colors."accent-focus".hex}",
        "${theme.colors."text-primary".hex}",
        "${theme.colors."surface-base".hex}",
        "#FF0000",
        "#00FF00",
        "#FFD700",
      ]
    '';
  };
}
