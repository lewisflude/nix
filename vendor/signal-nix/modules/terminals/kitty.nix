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
# CONFIGURATION METHOD: ini-config (Tier 2)
# HOME-MANAGER MODULE: programs.kitty.settings
# UPSTREAM SCHEMA: https://sw.kovidgoyal.net/kitty/conf/
# SCHEMA VERSION: 0.32.0
# LAST VALIDATED: 2026-01-20
# NOTES: Kitty uses INI-style config. Home-Manager provides settings attrset
#        that gets serialized to kitty.conf format.
#        Uses semantic bridge for consistent color mappings.
let
  inherit (lib) mkIf mkDefault;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Core colors using semantic bridge
  colors = {
    background = semantic.core "background" themeMode;
    foreground = semantic.core "foreground" themeMode;
    cursor = semantic.core "cursor" themeMode;
    selection-bg = semantic.core "selection-bg" themeMode;
    selection-fg = semantic.core "selection-fg" themeMode;
  };

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

  # UI colors for tab bars and other UI elements
  uiColors = {
    tab-active-bg = semantic.core "background" themeMode;
    tab-active-fg = semantic.core "foreground" themeMode;
    tab-inactive-bg = semantic.ui "element-disabled" themeMode;
    tab-inactive-fg = semantic.editor "line-number" themeMode;
    border = semantic.ui "panel-border" themeMode;
  };

  # Status colors for marks
  statusColors = {
    warning = semantic.status "warning" themeMode;
    info = semantic.status "info" themeMode;
    success = semantic.status "success" themeMode;
  };

  # Check if kitty should be themed
  shouldTheme = signalLib.shouldThemeApp "kitty" [
    "terminals"
    "kitty"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.kitty.settings = {
      # Basic colors
      foreground = mkDefault colors.foreground.hex;
      background = mkDefault colors.background.hex;

      # Cursor colors
      cursor = mkDefault colors.cursor.hex;
      cursor_text_color = mkDefault colors.background.hex;

      # Selection colors
      selection_foreground = mkDefault colors.selection-fg.hex;
      selection_background = mkDefault colors.selection-bg.hex;

      # URL underline color
      url_color = mkDefault colors.cursor.hex;

      # Tab bar colors
      active_tab_foreground = mkDefault uiColors.tab-active-fg.hex;
      active_tab_background = mkDefault uiColors.tab-active-bg.hex;
      inactive_tab_foreground = mkDefault uiColors.tab-inactive-fg.hex;
      inactive_tab_background = mkDefault uiColors.tab-inactive-bg.hex;

      # Border colors
      active_border_color = mkDefault colors.cursor.hex;
      inactive_border_color = mkDefault uiColors.border.hex;

      # Marks - for highlighting text
      mark1_foreground = mkDefault colors.background.hex;
      mark1_background = mkDefault statusColors.info.hex;
      mark2_foreground = mkDefault colors.background.hex;
      mark2_background = mkDefault statusColors.success.hex;
      mark3_foreground = mkDefault colors.background.hex;
      mark3_background = mkDefault statusColors.warning.hex;

      # The 16 terminal colors

      # Black
      color0 = mkDefault ansiColors.black.hex;
      color8 = mkDefault ansiColors.bright-black.hex;

      # Red
      color1 = mkDefault ansiColors.red.hex;
      color9 = mkDefault ansiColors.bright-red.hex;

      # Green
      color2 = mkDefault ansiColors.green.hex;
      color10 = mkDefault ansiColors.bright-green.hex;

      # Yellow
      color3 = mkDefault ansiColors.yellow.hex;
      color11 = mkDefault ansiColors.bright-yellow.hex;

      # Blue
      color4 = mkDefault ansiColors.blue.hex;
      color12 = mkDefault ansiColors.bright-blue.hex;

      # Magenta
      color5 = mkDefault ansiColors.magenta.hex;
      color13 = mkDefault ansiColors.bright-magenta.hex;

      # Cyan
      color6 = mkDefault ansiColors.cyan.hex;
      color14 = mkDefault ansiColors.bright-cyan.hex;

      # White
      color7 = mkDefault ansiColors.white.hex;
      color15 = mkDefault ansiColors.bright-white.hex;
    };
  };
}
