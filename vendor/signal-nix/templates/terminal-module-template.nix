# Signal-Nix Terminal Module Template
#
# This template shows how to create a terminal emulator module using the semantic bridge.
# Copy this file and adapt it for your terminal emulator.
#
# CONFIGURATION METHOD: structured-colors (Tier 2)
# LAST UPDATED: 2026-01-20
{
  config,
  lib,

  signalLib,
  semantic,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;

  # Resolve theme mode (converts "auto" to "dark" or "light")
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # ============================================================================
  # Color Definitions using Semantic Bridge
  # ============================================================================
  # The semantic bridge provides consistent color mappings across all modules.
  # Use semantic.{category} "{name}" themeMode to access colors.

  # Core UI colors - fundamental colors used everywhere
  colors = {
    background = semantic.core "background" themeMode;
    foreground = semantic.core "foreground" themeMode;
    cursor = semantic.core "cursor" themeMode;
    selection-bg = semantic.core "selection-bg" themeMode;
    selection-fg = semantic.core "selection-fg" themeMode;
  };

  # Status colors - for warnings, errors, info messages
  status = {
    error = semantic.status "error" themeMode;
    warning = semantic.status "warning" themeMode;
    success = semantic.status "success" themeMode;
    info = semantic.status "info" themeMode;
  };

  # ANSI colors - standard 16-color terminal palette
  # These use the semantic terminal mappings for consistency across all terminals
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

  # ============================================================================
  # Theme Activation Logic
  # ============================================================================
  # Determine if this terminal should be themed
  # Replace "myTerminal" with your terminal's name (e.g., "kitty", "wezterm")
  shouldTheme = signalLib.shouldThemeApp "myTerminal" [
    "terminals"
    "myTerminal"
  ] cfg config;
in
{
  # ============================================================================
  # Home Manager Configuration
  # ============================================================================
  # Apply theming only when Signal is enabled and this terminal should be themed
  config = mkIf (cfg.enable && shouldTheme) {
    # Replace with your terminal's Home Manager module path
    # Examples:
    #   programs.kitty.settings.colors = { ... };
    #   programs.wezterm.colorSchemes."signal-${themeMode}" = { ... };
    #   programs.foot.settings.colors = { ... };

    programs.myTerminal = {
      # Example: Map colors to your terminal's config format
      # Each terminal has its own format - consult the terminal's documentation

      settings = {
        colors = {
          # Primary colors
          primary = {
            background = colors.background.hex;
            foreground = colors.foreground.hex;
          };

          # Cursor
          cursor = {
            text = colors.background.hex;
            cursor = colors.cursor.hex;
          };

          # Selection
          selection = {
            text = colors.selection-fg.hex;
            background = colors.selection-bg.hex;
          };

          # Normal ANSI colors (0-7)
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

          # Bright ANSI colors (8-15)
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
        };
      };
    };
  };
}

# ============================================================================
# Available Semantic Categories
# ============================================================================
#
# semantic.core - Core UI elements
#   - background, foreground, cursor, selection-bg, selection-fg, focus
#
# semantic.terminal - ANSI terminal colors
#   - ansi-black, ansi-red, ansi-green, ansi-yellow, ansi-blue, ansi-magenta, ansi-cyan, ansi-white
#   - ansi-bright-black, ansi-bright-red, ansi-bright-green, ansi-bright-yellow,
#     ansi-bright-blue, ansi-bright-magenta, ansi-bright-cyan, ansi-bright-white
#
# semantic.ui - UI components
#   - panel-background, panel-border, element-hover, element-active,
#     element-selected, element-disabled
#
# semantic.text - Text hierarchy
#   - primary, secondary, disabled, placeholder, link, link-hover
#
# semantic.status - Status indicators
#   - error, warning, success, info, hint
#
# semantic.vcs - Version control
#   - added, modified, deleted, renamed, conflict, ignored
#
# semantic.editor - Editor-specific
#   - background, foreground, gutter-background, active-line-background,
#     line-number, active-line-number, indent-guide, indent-guide-active
#
# semantic.syntax - Syntax highlighting
#   - keyword, function, string, number, comment, type, variable,
#     constant, operator, tag, attribute, preprocessing
#
# For complete reference, see: docs/QUICK_REFERENCE.md
