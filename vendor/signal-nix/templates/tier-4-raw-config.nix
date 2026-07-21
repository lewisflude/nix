# =============================================================================
# Signal Design System - Tier 4 Module Template (Raw Config)
# =============================================================================
#
# TIER 4: Raw Config (LAST RESORT)
# - Manual config string generation
# - No type safety or validation
# - Only use when no better option exists
# - Examples: wezterm, eza, fzf, neovim, zsh, btop, tmux, gtk
#
# USE THIS TIER WHEN:
# - No native theme, structured colors, or freeform settings exist
# - Home-Manager only provides extraConfig/extraCss/similar string options
# - You must generate raw config text manually
#
# INSTRUCTIONS:
# 1. Copy this template to modules/<category>/<app-name>.nix
# 2. Replace all UPPERCASE_PLACEHOLDER text with actual values
# 3. Update the metadata comment block with correct information
# 4. Implement your config string generation using signalColors and signalLib
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
# CONFIGURATION METHOD: raw-config (Tier 4)
# HOME-MANAGER MODULE: programs.APP_NAME.extraConfig (or similar)
# UPSTREAM SCHEMA: https://UPSTREAM_DOCUMENTATION_URL
# SCHEMA VERSION: VERSION_NUMBER
# LAST VALIDATED: YYYY-MM-DD
# NOTES: Brief description of why Tier 4 is required.
#        Explain the config format and any special syntax.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;

  # Get resolved theme mode (light/dark)
  themeMode = signalLib.resolveThemeMode cfg.mode;

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

  # For Tier 4, you may need mode-specific color mappings
  colors =
    if themeMode == "light" then
      {
        # Light mode colors
        background = signalColors.tonal."surface-subtle".hex;
        foreground = signalColors.tonal."text-primary".hex;
        # ... more colors ...
      }
    else
      {
        # Dark mode colors
        background = signalColors.tonal."surface-base".hex;
        foreground = signalColors.tonal."text-primary".hex;
        # ... more colors ...
      };

  inherit (signalColors) accent;

  # =============================================================================
  # Config String Generation
  # =============================================================================
  #
  # Generate the raw config string in the format the app expects.
  # Common formats:
  # - Shell script syntax (zsh, bash)
  # - Lua (neovim, wezterm)
  # - CSS (GTK)
  # - INI-like (tmux)
  # - Custom syntax (fzf, btop)
  #
  # Use ${variable} for interpolation
  # Use '' for multi-line strings (Nix's indented string syntax)
  # Escape special characters as needed
  # =============================================================================

  configText = ''
    # Signal Design System Colors
    # Generated for ${themeMode} mode

    # Example for shell syntax:
    # FOREGROUND="${colors.foreground}"
    # BACKGROUND="${colors.background}"

    # Example for Lua syntax:
    # config.colors = {
    #   foreground = "${colors.foreground}",
    #   background = "${colors.background}",
    # }

    # Example for CSS syntax:
    # @define-color foreground_color ${colors.foreground};
    # @define-color background_color ${colors.background};

    # Example for INI syntax:
    # foreground = ${colors.foreground}
    # background = ${colors.background}

    # YOUR IMPLEMENTATION HERE
    # Replace with actual config syntax
  '';

  # =============================================================================
  # Theme Activation Check
  # =============================================================================
  #
  # Use the centralized helper to determine if this app should be themed.
  # This checks:
  # - If the app is enabled (programs.APP_NAME.enable or config.APP_NAME.enable)
  # - If category targeting is active (cfg.CATEGORY.enable)
  # - If app-specific targeting is active (cfg.CATEGORY.APP_NAME.enable)
  #
  # Replace "APP_NAME" with the actual app name (lowercase)
  # Replace "CATEGORY" with the category (e.g., terminals, editors, cli)
  #
  # Note: Some apps use config.APP_NAME.enable instead of programs.APP_NAME.enable
  # (e.g., GTK uses config.gtk.enable). Adjust accordingly.
  # =============================================================================
  shouldTheme = signalLib.shouldThemeApp "APP_NAME" [
    "CATEGORY"
    "APP_NAME"
  ] cfg config;

  # Alternative for non-programs apps (like GTK):
  # shouldTheme = cfg.CATEGORY.enable || (cfg.autoEnable && (config.APP_NAME.enable or false));
in
{
  # =============================================================================
  # Configuration
  # =============================================================================
  config = mkIf (cfg.enable && shouldTheme) {
    programs.APP_NAME = {
      # Tier 4: Raw config string
      # Common option names:
      # - extraConfig (tmux, zsh, neovim)
      # - extraCss (gtk)
      # - initExtra (zsh, bash)
      # - plugins with color config (fzf)

      # YOUR IMPLEMENTATION HERE
      # Replace with actual Home-Manager option
      # extraConfig = configText;
    };

    # Or for non-programs apps:
    # APP_NAME = {
    #   extraCss = configText;
    # };
  };

  # =============================================================================
  # Important Notes for Tier 4
  # =============================================================================
  #
  # 1. No validation - syntax errors will cause runtime failures
  # 2. Must know exact config format and syntax
  # 3. Careful with string escaping (quotes, backslashes, etc.)
  # 4. Test thoroughly in the actual app
  # 5. Consider if the app could be upgraded to a better tier
  #
  # =============================================================================

  # =============================================================================
  # Config Format Tips
  # =============================================================================
  #
  # Shell scripts:
  # - Use export for env vars
  # - Single quotes for literal strings
  # - Watch out for variable expansion
  #
  # Lua:
  # - Use proper table syntax
  # - Strings need quotes
  # - Comments use --
  #
  # CSS:
  # - Use @define-color for variables
  # - Watch semicolons and braces
  # - Comments use /* */
  #
  # INI-like:
  # - key = value format
  # - No quotes usually
  # - Comments use # or ;
  #
  # =============================================================================

  # =============================================================================
  # Testing Checklist
  # =============================================================================
  #
  # Before submitting:
  # [ ] Test in light mode (theming.signal.mode = "light")
  # [ ] Test in dark mode (theming.signal.mode = "dark")
  # [ ] Test in auto mode if supported (theming.signal.mode = "auto")
  # [ ] Verify colors match Signal design system
  # [ ] Run `nix flake check`
  # [ ] Check that app works without Signal theming enabled
  # [ ] Verify app-specific targeting works (cfg.CATEGORY.APP_NAME.enable = false)
  # [ ] Test the actual app to ensure config is valid
  # [ ] Check for syntax errors in generated config
  # [ ] Verify string escaping is correct
  # [ ] Test edge cases (special characters in config)
  #
  # =============================================================================
}
