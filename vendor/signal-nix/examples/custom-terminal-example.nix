# Custom Terminal Example
#
# This example shows how to integrate a custom terminal emulator with Signal theming.
# It demonstrates best practices for using the semantic bridge.
#
# To use this example:
# 1. Copy this file to your modules directory
# 2. Replace "myTerminal" with your terminal's name
# 3. Adjust the color mappings to match your terminal's config format
# 4. Add to your imports in configuration.nix or home.nix
#
# See also:
# - templates/terminal-module-template.nix - Blank template to start from
# - modules/terminals/alacritty.nix - Real-world example
# - docs/QUICK_REFERENCE.md - All available semantic colors
{
  config,
  lib,
  pkgs,
  signalLib,
  semantic,
  ...
}:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.theming.signal;

  # ============================================================================
  # Step 1: Resolve Theme Mode
  # ============================================================================
  # Convert "auto" to "dark" or "light" based on system settings
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # ============================================================================
  # Step 2: Define Colors Using Semantic Bridge
  # ============================================================================
  # Group related colors for better organization

  # Core terminal colors
  colors = {
    background = semantic.core "background" themeMode;
    foreground = semantic.core "foreground" themeMode;
    cursor = semantic.core "cursor" themeMode;
    selection-bg = semantic.core "selection-bg" themeMode;
    selection-fg = semantic.core "selection-fg" themeMode;
  };

  # UI elements (if your terminal has tabs, panels, etc.)
  ui = {
    panel-bg = semantic.ui "panel-background" themeMode;
    border = semantic.ui "panel-border" themeMode;
    hover = semantic.ui "element-hover" themeMode;
    active = semantic.ui "element-active" themeMode;
  };

  # Status/notification colors
  status = {
    error = semantic.status "error" themeMode;
    warning = semantic.status "warning" themeMode;
    success = semantic.status "success" themeMode;
    info = semantic.status "info" themeMode;
  };

  # Standard 16-color ANSI palette
  ansi = {
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
  # Step 3: Determine if Terminal Should Be Themed
  # ============================================================================
  # This respects both global enable and per-app enable options
  shouldTheme = signalLib.shouldThemeApp "myTerminal" [
    "terminals"
    "myTerminal"
  ] cfg config;
in
{
  # ============================================================================
  # Step 4: Apply Configuration
  # ============================================================================
  config = mkIf (cfg.enable && shouldTheme) {
    # Replace with your terminal's Home Manager module
    # Common patterns:
    #   - programs.kitty.settings.colors = { ... };
    #   - programs.wezterm.colorSchemes."signal-${themeMode}" = { ... };
    #   - programs.alacritty.settings.colors = { ... };
    #   - programs.foot.settings.colors = { ... };

    programs.myTerminal = {
      enable = true;

      # Example 1: Structured color settings (most common)
      settings = {
        colors = {
          # Primary colors
          background = colors.background.hex; # "#1a1b1e" in dark mode
          foreground = colors.foreground.hex; # "#cbd2d9" in dark mode

          # Cursor
          cursor = colors.cursor.hex;
          cursor_text = colors.background.hex; # Inverted for visibility

          # Selection
          selection_background = colors.selection-bg.hex;
          selection_foreground = colors.selection-fg.hex;

          # Normal ANSI colors (0-7)
          color0 = ansi.black.hex;
          color1 = ansi.red.hex;
          color2 = ansi.green.hex;
          color3 = ansi.yellow.hex;
          color4 = ansi.blue.hex;
          color5 = ansi.magenta.hex;
          color6 = ansi.cyan.hex;
          color7 = ansi.white.hex;

          # Bright ANSI colors (8-15)
          color8 = ansi.bright-black.hex;
          color9 = ansi.bright-red.hex;
          color10 = ansi.bright-green.hex;
          color11 = ansi.bright-yellow.hex;
          color12 = ansi.bright-blue.hex;
          color13 = ansi.bright-magenta.hex;
          color14 = ansi.bright-cyan.hex;
          color15 = ansi.bright-white.hex;
        };

        # Example: UI elements (if supported)
        ui = {
          tab_bar_background = ui.panel-bg.hex;
          tab_bar_border = ui.border.hex;
          active_tab_background = ui.active.hex;
          inactive_tab_background = ui.panel-bg.hex;
        };
      };

      # Example 2: RGB format (some terminals need this)
      # Use .rgb property instead of .hex
      # rgb-colors = {
      #   background = colors.background.rgb;  # "26, 27, 30"
      #   foreground = colors.foreground.rgb;  # "203, 210, 217"
      # };

      # Example 3: Individual RGB components (rare)
      # Use .l, .c, .h for OKLCH components if needed
      # oklch-colors = {
      #   bg-lightness = colors.background.l;  # 0.15
      #   bg-chroma = colors.background.c;     # 0.01
      #   bg-hue = colors.background.h;        # 240
      # };
    };
  };
}

# ============================================================================
# Tips and Best Practices
# ============================================================================
#
# 1. Always use semantic bridge, never hardcode colors
#    ✅ DO:   semantic.core "background" mode
#    ❌ DON'T: "#1a1b1e"
#
# 2. Group related colors for organization
#    ✅ DO:   colors = { bg = ...; fg = ...; };
#    ❌ DON'T: Flat list of all colors
#
# 3. Use descriptive variable names
#    ✅ DO:   activeLine = semantic.editor "active-line-background" mode;
#    ❌ DON'T: al = semantic.editor "active-line-background" mode;
#
# 4. Comment non-obvious mappings
#    # Terminal's "dim" color → secondary text
#    dim = semantic.text "secondary" mode;
#
# 5. Test both light and dark modes
#    nix build .#homeConfigurations.test-user.activationPackage
#
# 6. Validate no hardcoded colors
#    nix flake check
#
# ============================================================================
# Common Issues and Solutions
# ============================================================================
#
# Issue: Colors don't match other Signal apps
# Solution: Ensure you're using the correct semantic category
#           Terminal backgrounds should use semantic.core "background"
#           Not semantic.editor "background" (editor-specific)
#
# Issue: "Semantic reference not found" error
# Solution: Check spelling of category and name
#           See docs/QUICK_REFERENCE.md for all available names
#
# Issue: Terminal not being themed
# Solution: Check that shouldTheme is true
#           Verify app name matches in shouldThemeApp call
#           Check that cfg.enable is true
#
# Issue: Need a color not in semantic bridge
# Solution: 1. Check if existing category fits your need
#           2. If not, add to lib/semantic.nix
#           3. Document in docs/QUICK_REFERENCE.md
#
# ============================================================================
# Next Steps
# ============================================================================
#
# 1. Test your module:
#    nix build .#homeConfigurations.test-user.activationPackage
#
# 2. Validate no hardcoded colors:
#    nix flake check
#
# 3. Add to signal-nix:
#    - Place in modules/terminals/yourTerminal.nix
#    - Add to modules/common/default.nix imports
#    - Add enable option to modules/common/default.nix
#    - Test with both light and dark modes
#    - Submit PR!
#
# See CONTRIBUTING.md for full contribution guidelines.
