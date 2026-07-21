# =============================================================================
# Signal Design System - Tier 3 Module Template (Freeform Settings)
# =============================================================================
#
# TIER 3: Freeform Settings (ACCEPTABLE)
# - Home-Manager has freeform `settings` option
# - Serializes to config format
# - Limited type validation
# - Examples: kitty, ghostty, delta, lazygit, yazi, fuzzel, starship, zellij
#
# USE THIS TIER WHEN:
# - Home-Manager has untyped settings attrset (programs.APP_NAME.settings)
# - No native theme system or structured colors exist
# - Settings are serialized to app's config format
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
  signalColors,
  signalLib,
  ...
}:
# CONFIGURATION METHOD: freeform-settings (Tier 3)
# HOME-MANAGER MODULE: programs.APP_NAME.settings
# UPSTREAM SCHEMA: https://UPSTREAM_DOCUMENTATION_URL
# SCHEMA VERSION: VERSION_NUMBER
# LAST VALIDATED: YYYY-MM-DD
# NOTES: Brief description of the settings serialization.
#        Note the config format (TOML, YAML, INI, etc.)
let
  inherit (lib) mkIf mkDefault;
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

  # Define semantic color mappings for readability
  colors = {
    surface-base = signalColors.tonal."surface-subtle";
    text-primary = signalColors.tonal."text-primary";
    text-secondary = signalColors.tonal."text-secondary";
    divider-primary = signalColors.tonal."divider-primary";
  };

  inherit (signalColors) accent;

  # ANSI color mapping using Signal palette (for terminal apps)
  # Remove this section if your app doesn't need ANSI colors
  ansiColors = {
    # Normal colors
    black = signalColors.tonal."black";
    red = accent.danger.Lc75;
    green = accent.primary.Lc75;
    yellow = accent.warning.Lc75;
    blue = accent.secondary.Lc75;
    magenta = accent.tertiary.Lc75;
    cyan = accent.info.Lc75;
    white = signalColors.tonal."text-secondary";

    # Bright colors
    bright-black = signalColors.tonal."text-tertiary";
    bright-red = accent.danger.Lc75;
    bright-green = accent.primary.Lc75;
    bright-yellow = accent.warning.Lc75;
    bright-blue = accent.secondary.Lc75;
    bright-magenta = accent.tertiary.Lc75;
    bright-cyan = accent.info.Lc75;
    bright-white = signalColors.tonal."text-primary";
  };

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
      settings = {
        # Tier 3: Freeform settings attrset
        # All keys must match the upstream config schema exactly
        # Home-Manager will serialize this to the app's config format

        # IMPORTANT: Wrap all values with mkDefault to allow user overrides!
        # This prevents conflicts when users have their own configuration.

        # Example for terminal apps:
        # foreground = mkDefault colors.text-primary.hex;
        # background = mkDefault colors.surface-base.hex;
        # cursor = mkDefault accent.secondary.Lc75.hex;
        # cursor_text_color = mkDefault colors.surface-base.hex;
        # selection_foreground = mkDefault colors.text-primary.hex;
        # selection_background = mkDefault colors.divider-primary.hex;

        # ANSI colors (for terminals)
        # color0 = mkDefault ansiColors.black.hex;
        # color1 = mkDefault ansiColors.red.hex;
        # color2 = mkDefault ansiColors.green.hex;
        # color3 = mkDefault ansiColors.yellow.hex;
        # color4 = ansiColors.blue.hex;
        # color5 = ansiColors.magenta.hex;
        # color6 = ansiColors.cyan.hex;
        # color7 = ansiColors.white.hex;
        # color8 = ansiColors.bright-black.hex;
        # color9 = ansiColors.bright-red.hex;
        # color10 = ansiColors.bright-green.hex;
        # color11 = ansiColors.bright-yellow.hex;
        # color12 = ansiColors.bright-blue.hex;
        # color13 = ansiColors.bright-magenta.hex;
        # color14 = ansiColors.bright-cyan.hex;
        # color15 = ansiColors.bright-white.hex;

        # YOUR IMPLEMENTATION HERE
        # Replace with actual settings based on upstream schema
        # Key names must match exactly what the app expects
        # Use ${colors.PROPERTY.hex} for hex colors
        # Use ${colors.PROPERTY.rgb} for RGB lists
      };
    };
  };

  # =============================================================================
  # Important Notes for Tier 3
  # =============================================================================
  #
  # 1. Key names must match upstream exactly (e.g., "foreground" not "fg")
  # 2. Limited type checking - wrong keys may cause runtime errors
  # 3. Check upstream docs for exact key names and formats
  # 4. Test thoroughly as errors may not be caught at build time
  #
  # =============================================================================

  # =============================================================================
  # Color Format Notes
  # =============================================================================
  #
  # Most apps accept hex colors: colors.surface-base.hex
  # Some apps need RGB: colors.surface-base.rgb (returns [r g b])
  # Some apps need RGB strings: "${toString colors.surface-base.rgb.r} ${toString colors.surface-base.rgb.g} ${toString colors.surface-base.rgb.b}"
  # Some apps need OKLCH: colors.surface-base.oklch (returns { l = ...; c = ...; h = ...; })
  #
  # Always check upstream documentation for the exact format required!
  #
  # =============================================================================

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
  # [ ] Verify key names match upstream schema exactly
  # [ ] Test the actual app to ensure config is valid
  #
  # =============================================================================
}
