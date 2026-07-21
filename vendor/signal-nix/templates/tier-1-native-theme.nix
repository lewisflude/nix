# =============================================================================
# Signal Design System - Tier 1 Module Template (Native Theme Options)
# =============================================================================
#
# TIER 1: Native Theme Options (BEST)
# - Home-Manager provides dedicated theme options
# - Full type safety and validation
# - Forward-compatible
# - Examples: bat, helix
#
# USE THIS TIER WHEN:
# - Home-Manager has dedicated theme/color options (like programs.bat.themes)
# - The upstream application has a standard theme format
# - You want maximum type safety and validation
#
# INSTRUCTIONS:
# 1. Copy this template to modules/<category>/<app-name>.nix
# 2. Replace all UPPERCASE_PLACEHOLDER text with actual values
# 3. Update the metadata comment block with correct information
# 4. Implement your color mapping using signalColors and signalLib
# 5. Test both light and dark modes
# 6. Add module import to modules/common/default.nix
# 7. Run `nix flake check` to verify
#
# =============================================================================

{
  config,
  lib,
  pkgs,
  signalColors,
  signalLib,
  ...
}:
# CONFIGURATION METHOD: native-theme (Tier 1)
# HOME-MANAGER MODULE: programs.APP_NAME.THEME_OPTION
# UPSTREAM SCHEMA: https://UPSTREAM_DOCUMENTATION_URL
# SCHEMA VERSION: VERSION_NUMBER
# LAST VALIDATED: YYYY-MM-DD
# NOTES: Brief description of the theme integration approach.
#        Explain any special considerations or quirks.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;

  # =============================================================================
  # Color Definitions
  # =============================================================================
  #
  # Define color mappings using Signal's semantic color system.
  # Use signalColors.tonal for UI elements and signalColors.accent for highlights.
  #
  # Available tonal colors:
  # - surface-base, surface-subtle, surface-hover
  # - text-primary, text-secondary, text-tertiary
  # - divider-primary, divider-strong
  # - black (for ANSI colors only)
  #
  # Available accent colors:
  # - accent.primary.Lc60, accent.primary.Lc75 (green/success)
  # - accent.secondary.Lc60, accent.secondary.Lc75 (blue)
  # - accent.tertiary.Lc60, accent.tertiary.Lc75 (purple)
  # - accent.danger.Lc60, accent.danger.Lc75 (red)
  # - accent.warning.Lc60, accent.warning.Lc75 (yellow)
  # - accent.info.Lc60, accent.info.Lc75 (cyan)
  #
  # Each color object has: .hex, .rgb (list), .oklch (attrset)
  # =============================================================================

  # For Tier 1, you may need to generate theme files in the upstream format
  # Example: XML, JSON, YAML, TOML, etc.
  generateThemeFile =
    mode:
    let
      # Use centralized syntax color definitions if available
      # Otherwise define your own color mappings
      colors = signalLib.getSyntaxColors mode;
      # OR define custom colors:
      # colors = {
      #   background = if mode == "dark"
      #     then signalColors.tonal."surface-base".hex
      #     else signalColors.tonal."surface-subtle".hex;
      #   foreground = signalColors.tonal."text-primary".hex;
      #   # ... more colors ...
      # };
    in
    pkgs.writeText "signal-${mode}.THEME_EXTENSION" ''
      # Theme file content here
      # Use ${colors.PROPERTY} for interpolation
      # Example (for JSON):
      # {
      #   "name": "Signal ${lib.toUpper (builtins.substring 0 1 mode)}${builtins.substring 1 (-1) mode}",
      #   "colors": {
      #     "background": "${colors.background}",
      #     "foreground": "${colors.foreground}"
      #   }
      # }
    '';

  # Generate both dark and light themes
  darkThemeFile = generateThemeFile "dark";
  lightThemeFile = generateThemeFile "light";

  # Package theme files if needed
  themePackage = pkgs.runCommand "APP_NAME-signal-themes" { } ''
    mkdir -p $out
    cp ${darkThemeFile} "$out/signal-dark.THEME_EXTENSION"
    cp ${lightThemeFile} "$out/signal-light.THEME_EXTENSION"
  '';

  # Resolved mode for static theme selection
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # =============================================================================
  # Theme Activation Check
  # =============================================================================
  #
  # Use the centralized helper to determine if this app should be themed.
  # This checks:
  # - If the app is enabled (programs.APP_NAME.enable)
  # - If category targeting is active (cfg.CATEGORY.enable)
  # - If app-specific targeting is active (cfg.CATEGORY.APP_NAME.enable)
  #
  # Replace "APP_NAME" with the actual app name (lowercase)
  # Replace "CATEGORY" with the category (e.g., terminals, editors, cli)
  # =============================================================================
  shouldTheme = signalLib.shouldThemeApp "APP_NAME" [
    "CATEGORY"
    "APP_NAME"
  ] cfg config;
in
{
  # =============================================================================
  # Configuration
  # =============================================================================
  config = mkIf (cfg.enable && shouldTheme) {
    programs.APP_NAME = {
      # Tier 1: Use native theme options
      # Example for bat:
      # themes = {
      #   signal-dark = {
      #     src = themePackage;
      #     file = "signal-dark.tmTheme";
      #   };
      #   signal-light = {
      #     src = themePackage;
      #     file = "signal-light.tmTheme";
      #   };
      # };
      #
      # config = {
      #   theme = if cfg.mode == "auto" then "auto" else "signal-${themeMode}";
      #   theme-dark = "signal-dark";
      #   theme-light = "signal-light";
      # };

      # YOUR IMPLEMENTATION HERE
      # Replace with actual theme option configuration
    };
  };

  # =============================================================================
  # Testing Checklist
  # =============================================================================
  #
  # Before submitting:
  # [ ] Test in light mode (theming.signal.mode = "light")
  # [ ] Test in dark mode (theming.signal.mode = "dark")
  # [ ] Test in auto mode (theming.signal.mode = "auto")
  # [ ] Verify colors match Signal design system
  # [ ] Run `nix flake check`
  # [ ] Check that app works without Signal theming enabled
  # [ ] Verify app-specific targeting works (cfg.CATEGORY.APP_NAME.enable = false)
  #
  # =============================================================================
}
