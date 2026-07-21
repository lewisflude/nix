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
# CONFIGURATION METHOD: structured-colors (Tier 2)
# HOME-MANAGER MODULE: programs.alacritty.settings.colors
# UPSTREAM SCHEMA: https://alacritty.org/config-alacritty.html
# SCHEMA VERSION: 0.13.0
# LAST VALIDATED: 2026-01-17
# NOTES: Home-Manager provides structured color options within settings.colors.
#        This is well-typed and validates the color structure properly.
#        Uses semantic bridge for consistent color mappings.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Core colors using semantic bridge
  colors = {
    background = semantic.core "background" themeMode;
    foreground = semantic.core "foreground" themeMode;
    cursor = semantic.core "cursor" themeMode;
    selection-bg = semantic.core "selection-bg" themeMode;
    selection-fg = semantic.core "selection-fg" themeMode;
    panel-bg = semantic.ui "panel-background" themeMode;
    divider = semantic.ui "panel-border" themeMode;
  };

  # Status colors
  status = {
    warning = semantic.status "warning" themeMode;
    info = semantic.status "info" themeMode;
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

  # Check if alacritty should be themed - using centralized helper
  shouldTheme = signalLib.shouldThemeApp "alacritty" [
    "terminals"
    "alacritty"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.alacritty = {
      settings = {
        colors = {
          # Primary colors
          primary = {
            background = colors.background.hex;
            foreground = colors.foreground.hex;
          };

          # Cursor colors
          cursor = {
            text = colors.background.hex;
            cursor = colors.cursor.hex;
          };

          # Vi mode cursor colors
          vi_mode_cursor = {
            text = colors.background.hex;
            cursor = status.info.hex;
          };

          # Search colors
          search = {
            matches = {
              foreground = colors.background.hex;
              background = status.warning.hex;
            };
            focused_match = {
              foreground = colors.background.hex;
              background = status.info.hex;
            };
          };

          # Hints
          hints = {
            start = {
              foreground = colors.background.hex;
              background = status.warning.hex;
            };
            end = {
              foreground = colors.background.hex;
              background = status.info.hex;
            };
          };

          # Line indicator
          line_indicator = {
            foreground = "None";
            background = "None";
          };

          # Footer bar
          footer_bar = {
            foreground = colors.background.hex;
            background = colors.foreground.hex;
          };

          # Selection colors
          selection = {
            text = colors.selection-fg.hex;
            background = colors.selection-bg.hex;
          };

          # Normal colors
          normal = {
            black = ansiColors.black.hex;
            red = ansiColors.red.hex;
            green = ansiColors.green.hex;
            yellow = ansiColors.yellow.hex;
            blue = ansiColors.blue.hex;
            magenta = ansiColors.magenta.hex;
            cyan = ansiColors.cyan.hex;
            white = ansiColors.white.hex;
          };

          # Bright colors
          bright = {
            black = ansiColors.bright-black.hex;
            red = ansiColors.bright-red.hex;
            green = ansiColors.bright-green.hex;
            yellow = ansiColors.bright-yellow.hex;
            blue = ansiColors.bright-blue.hex;
            magenta = ansiColors.bright-magenta.hex;
            cyan = ansiColors.bright-cyan.hex;
            white = ansiColors.bright-white.hex;
          };

          # Dim colors (automatically calculated if not set)
          # We'll let alacritty calculate these

          # Transparent background colors
          transparent_background_colors = false;

          # Draw bold text with bright colors
          draw_bold_text_with_bright_colors = false;
        };
      };
    };
  };
}
