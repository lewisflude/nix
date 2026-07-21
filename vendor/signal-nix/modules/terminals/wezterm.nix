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
# CONFIGURATION METHOD: raw-config (Tier 4)
# HOME-MANAGER MODULE: programs.wezterm.extraConfig
# UPSTREAM SCHEMA: https://wezfurlong.org/wezterm/config/appearance.html
# SCHEMA VERSION: 20230712-072601-f4abf8fd
# LAST VALIDATED: 2026-01-17
# NOTES: WezTerm uses Lua configuration. Home-Manager's wezterm module only
#        provides extraConfig for Lua code generation. No structured options exist.
#        We generate a Lua table that matches WezTerm's color scheme structure.
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
    divider = semantic.ui "panel-border" themeMode;
  };

  # UI colors for tab bar
  uiColors = {
    surface-base = semantic.core "background" themeMode;
    text-primary = semantic.core "foreground" themeMode;
    text-secondary = semantic.editor "line-number" themeMode;
    divider-primary = semantic.ui "panel-border" themeMode;
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

  # Check if wezterm should be themed - using centralized helper
  shouldTheme = signalLib.shouldThemeApp "wezterm" [
    "terminals"
    "wezterm"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.wezterm = {
      # Wezterm config in Lua
      extraConfig = ''
        -- Signal Theme for WezTerm
        local signal_theme = {
          -- Terminal colors
          foreground = "${colors.foreground.hex}",
          background = "${colors.background.hex}",

          -- Cursor
          cursor_bg = "${colors.cursor.hex}",
          cursor_fg = "${colors.background.hex}",
          cursor_border = "${colors.cursor.hex}",

          -- Selection
          selection_fg = "${colors.selection-fg.hex}",
          selection_bg = "${colors.selection-bg.hex}",

          -- Scrollbar
          scrollbar_thumb = "${colors.divider.hex}",

          -- Split separators
          split = "${colors.divider.hex}",

          -- ANSI colors
          ansi = {
            "${ansiColors.black.hex}",
            "${ansiColors.red.hex}",
            "${ansiColors.green.hex}",
            "${ansiColors.yellow.hex}",
            "${ansiColors.blue.hex}",
            "${ansiColors.magenta.hex}",
            "${ansiColors.cyan.hex}",
            "${ansiColors.white.hex}",
          },

          brights = {
            "${ansiColors.bright-black.hex}",
            "${ansiColors.bright-red.hex}",
            "${ansiColors.bright-green.hex}",
            "${ansiColors.bright-yellow.hex}",
            "${ansiColors.bright-blue.hex}",
            "${ansiColors.bright-magenta.hex}",
            "${ansiColors.bright-cyan.hex}",
            "${ansiColors.bright-white.hex}",
          },

          -- Tab bar
          tab_bar = {
            background = "${uiColors.surface-base.hex}",
            active_tab = {
              bg_color = "${uiColors.surface-base.hex}",
              fg_color = "${uiColors.text-primary.hex}",
            },
            inactive_tab = {
              bg_color = "${uiColors.divider-primary.hex}",
              fg_color = "${uiColors.text-secondary.hex}",
            },
            inactive_tab_hover = {
              bg_color = "${uiColors.divider-primary.hex}",
              fg_color = "${uiColors.text-primary.hex}",
            },
            new_tab = {
              bg_color = "${uiColors.divider-primary.hex}",
              fg_color = "${uiColors.text-secondary.hex}",
            },
            new_tab_hover = {
              bg_color = "${uiColors.divider-primary.hex}",
              fg_color = "${uiColors.text-primary.hex}",
            },
          },
        }

        return {
          colors = signal_theme,
        }
      '';
    };
  };
}
