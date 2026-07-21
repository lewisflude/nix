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
# CONFIGURATION METHOD: structured-settings (Tier 2)
# HOME-MANAGER MODULE: programs.swaylock.settings
# UPSTREAM SCHEMA: https://github.com/swaywm/swaylock/blob/master/swaylock.1.scd
# SCHEMA VERSION: 1.8.4
# LAST VALIDATED: 2026-01-18
# NOTES: Swaylock uses hex colors WITHOUT # prefix (e.g., "RRGGBB" not "#RRGGBB").
#        Colors are mapped to authentication states: normal, clear, verify, wrong.
#        The indicator ring provides visual feedback during password entry.
let
  inherit (lib) mkIf mkDefault removePrefix;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # =============================================================================
  # Color Definitions
  # =============================================================================
  #
  # Swaylock has multiple states that need distinct colors:
  # - Normal: idle state, waiting for input
  # - Clear: after clearing input (backspace to empty)
  # - Verify: checking password with PAM
  # - Wrong: authentication failed
  # - Caps Lock: caps lock is active
  #
  # We use Signal's semantic colors to create good UX for these states.
  # =============================================================================

  # Use semantic bridge for color resolution
  colors = {
    surface-base = semantic.core "background" themeMode;
    surface-subtle = semantic.ui "panel-background" themeMode;
    surface-hover = semantic.ui "element-hover" themeMode;
    text-primary = semantic.core "foreground" themeMode;
    text-secondary = semantic.text "secondary" themeMode;
    text-tertiary = semantic.text "tertiary" themeMode;
    divider-primary = semantic.ui "panel-border" themeMode;
  };

  # Accent colors for states
  accent = {
    secondary = semantic.core "focus" themeMode;
    warning = semantic.status "warning" themeMode;
    primary = semantic.status "success" themeMode;
    danger = semantic.status "error" themeMode;
  };

  # Helper to strip # from hex colors since swaylock uses bare hex
  stripHash = color: removePrefix "#" color.hex;

  # Check if swaylock should be themed
  shouldTheme = signalLib.shouldThemeApp "swaylock" [
    "desktop"
    "swaylock"
  ] cfg config;

  # Platform guard - Swaylock is Linux-only (Wayland screen locker)
  platformOk = signalLib.platform.guard pkgs "swaylock";
in
{
  # =============================================================================
  # Configuration
  # =============================================================================
  config = mkIf (cfg.enable && shouldTheme && platformOk) {
    programs.swaylock.settings = {
      # Background color
      color = mkDefault (stripHash colors.surface-base);

      # Indicator appearance
      indicator-radius = mkDefault 100;
      indicator-thickness = mkDefault 10;

      # =======================================================================
      # Ring colors (outer circle of indicator)
      # =======================================================================
      # Normal: neutral blue when idle/typing
      ring-color = mkDefault (stripHash accent.secondary);

      # Clear: subtle when input is cleared
      ring-clear-color = mkDefault (stripHash colors.divider-primary);

      # Caps Lock: warning yellow when caps lock is on
      ring-caps-lock-color = mkDefault (stripHash accent.warning);

      # Verify: primary green when verifying password
      ring-ver-color = mkDefault (stripHash accent.primary);

      # Wrong: danger red when password is incorrect
      ring-wrong-color = mkDefault (stripHash accent.danger);

      # =======================================================================
      # Inside colors (inner circle of indicator)
      # =======================================================================
      # Normal: slightly raised surface
      inside-color = mkDefault (stripHash colors.surface-subtle);

      # Clear: same as normal (subtle feedback)
      inside-clear-color = mkDefault (stripHash colors.surface-subtle);

      # Caps Lock: subtle warning background
      inside-caps-lock-color = mkDefault (stripHash colors.surface-hover);

      # Verify: slight green tint using surface color
      inside-ver-color = mkDefault (stripHash colors.surface-hover);

      # Wrong: slight red tint using surface color
      inside-wrong-color = mkDefault (stripHash colors.surface-hover);

      # =======================================================================
      # Line colors (separator between inside and ring)
      # =======================================================================
      # Use ring colors for consistency
      line-uses-ring = mkDefault true;

      # =======================================================================
      # Text colors (password dots and messages)
      # =======================================================================
      # Normal: primary text
      text-color = mkDefault (stripHash colors.text-primary);

      # Clear: secondary text
      text-clear-color = mkDefault (stripHash colors.text-secondary);

      # Caps Lock: warning text
      text-caps-lock-color = mkDefault (stripHash accent.warning);

      # Verify: primary green text
      text-ver-color = mkDefault (stripHash accent.primary);

      # Wrong: danger red text
      text-wrong-color = mkDefault (stripHash accent.danger);

      # =======================================================================
      # Key highlight colors (visual feedback when typing)
      # =======================================================================
      # Normal key press: accent secondary
      key-hl-color = mkDefault (stripHash accent.secondary);

      # Backspace highlight: subtle
      bs-hl-color = mkDefault (stripHash colors.divider-primary);

      # Caps lock key press: warning
      caps-lock-key-hl-color = mkDefault (stripHash accent.warning);

      # Caps lock backspace: warning (use same as regular caps lock)
      caps-lock-bs-hl-color = mkDefault (stripHash accent.warning);

      # =======================================================================
      # Layout indicator colors (keyboard layout display)
      # =======================================================================
      layout-bg-color = mkDefault (stripHash colors.surface-hover);
      layout-border-color = mkDefault (stripHash colors.divider-primary);
      layout-text-color = mkDefault (stripHash colors.text-primary);

      # Separator between highlight segments
      separator-color = mkDefault (stripHash colors.divider-primary);

      # Show failed attempts for security feedback
      show-failed-attempts = mkDefault true;

      # Show keyboard layout if configured
      show-keyboard-layout = mkDefault true;
    };
  };
}
