{
  signalLib,
  signalPalette,
  semantic,
  nix-colorizer,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
# CONFIGURATION METHOD: freeform-settings (Tier 3)
# HOME-MANAGER MODULE: programs.ghostty.settings
# UPSTREAM SCHEMA: https://ghostty.org/docs/config
# SCHEMA VERSION: 1.0.0
# LAST VALIDATED: 2026-01-17
# NOTES: Ghostty is a newer terminal. Home-Manager provides freeform settings
#        that serialize to Ghostty's config format. Keys must match schema exactly.
#        The window-theme option accepts "auto", "light", "dark", or "ghostty".
#        Uses semantic bridge for consistent color mappings.
let
  inherit (lib) mkIf removePrefix;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Core colors using semantic bridge
  colors = {
    background = semantic.core "background" themeMode;
    foreground = semantic.core "foreground" themeMode;
    cursor = semantic.core "cursor" themeMode;
    selection-bg = semantic.core "selection-bg" themeMode;
    selection-fg = semantic.core "selection-fg" themeMode;
    divider = semantic.ui "panel-border" themeMode;
  };

  # Helper to get hex without # prefix
  hexRaw = color: removePrefix "#" color.hex;

  # ANSI colors using semantic terminal mappings
  ansiColors = {
    # Normal colors (0-7)
    black = semantic.terminal "ansi-black" themeMode;
    red = semantic.terminal "ansi-red" themeMode;
    green = semantic.terminal "ansi-green" themeMode;
    yellow = semantic.terminal "ansi-yellow" themeMode;
    blue = semantic.terminal "ansi-blue" themeMode;
    magenta = semantic.terminal "ansi-magenta" themeMode;
    cyan = semantic.terminal "ansi-cyan" themeMode;
    white = semantic.terminal "ansi-white" themeMode;

    # Bright colors (8-15)
    bright-black = semantic.terminal "ansi-bright-black" themeMode;
    bright-red = semantic.terminal "ansi-bright-red" themeMode;
    bright-green = semantic.terminal "ansi-bright-green" themeMode;
    bright-yellow = semantic.terminal "ansi-bright-yellow" themeMode;
    bright-blue = semantic.terminal "ansi-bright-blue" themeMode;
    bright-magenta = semantic.terminal "ansi-bright-magenta" themeMode;
    bright-cyan = semantic.terminal "ansi-bright-cyan" themeMode;
    bright-white = semantic.terminal "ansi-bright-white" themeMode;
  };

  # Check if ghostty should be themed - using centralized helper
  shouldTheme = signalLib.shouldThemeApp "ghostty" [
    "terminals"
    "ghostty"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.ghostty = {
      settings = {
        # Window theme (GTK) - uses system theme for titlebar
        "window-theme" = "ghostty";

        # Background and foreground
        background = hexRaw colors.background;
        foreground = hexRaw colors.foreground;

        # Cursor colors
        "cursor-color" = hexRaw colors.cursor;
        "cursor-text" = hexRaw colors.background;

        # Selection colors
        "selection-background" = hexRaw colors.selection-bg;
        "selection-foreground" = hexRaw colors.selection-fg;

        # Split divider color
        "split-divider-color" = hexRaw colors.divider;

        # ANSI color palette
        palette = [
          "0=${ansiColors.black.hex}"
          "1=${ansiColors.red.hex}"
          "2=${ansiColors.green.hex}"
          "3=${ansiColors.yellow.hex}"
          "4=${ansiColors.blue.hex}"
          "5=${ansiColors.magenta.hex}"
          "6=${ansiColors.cyan.hex}"
          "7=${ansiColors.white.hex}"
          # Bright colors (8-15)
          "8=${ansiColors.bright-black.hex}"
          "9=${ansiColors.bright-red.hex}"
          "10=${ansiColors.bright-green.hex}"
          "11=${ansiColors.bright-yellow.hex}"
          "12=${ansiColors.bright-blue.hex}"
          "13=${ansiColors.bright-magenta.hex}"
          "14=${ansiColors.bright-cyan.hex}"
          "15=${ansiColors.bright-white.hex}"
        ];
      };
    };
  };
}
