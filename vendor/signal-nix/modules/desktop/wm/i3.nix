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
# CONFIGURATION METHOD: structured-config (Tier 2)
# HOME-MANAGER MODULE: xsession.windowManager.i3.config.colors
# UPSTREAM SCHEMA: https://i3wm.org/docs/userguide.html#_changing_colors
# SCHEMA VERSION: 4.23
# LAST VALIDATED: 2026-01-17
# NOTES: i3 uses the same color scheme format as Sway (Sway is i3-compatible).
#        Colors are defined with border, background, text, indicator, and childBorder.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for all colors
  colors = {
    surface-base = semantic.ui "panel-background" themeMode;
    surface-raised = semantic.ui "element-hover" themeMode;
    text-primary = semantic.text "primary" themeMode;
    text-secondary = semantic.text "secondary" themeMode;
    divider-primary = semantic.ui "panel-border" themeMode;
    divider-secondary = semantic.ui "element-active" themeMode;
  };

  # Check if i3 should be themed
  shouldTheme = signalLib.shouldThemeApp "i3" [
    "desktop"
    "wm"
    "i3"
  ] cfg config;

  # Platform guard - i3 is Linux-only (X11 window manager)
  platformOk = signalLib.platform.guard pkgs "i3";
in
{
  config = mkIf (cfg.enable && shouldTheme && platformOk) {
    xsession.windowManager.i3.config.colors = {
      # Focused window (active)
      focused = {
        border = (semantic.vcs "modified" themeMode).hex;
        background = colors.surface-raised.hex;
        text = colors.text-primary.hex;
        indicator = (semantic.vcs "modified" themeMode).hex;
        childBorder = (semantic.vcs "modified" themeMode).hex;
      };

      # Focused window (inactive - in multi-monitor setup)
      focusedInactive = {
        border = colors.divider-secondary.hex;
        background = colors.surface-base.hex;
        text = colors.text-secondary.hex;
        indicator = colors.divider-secondary.hex;
        childBorder = colors.divider-secondary.hex;
      };

      # Unfocused window
      unfocused = {
        border = colors.divider-primary.hex;
        background = colors.surface-base.hex;
        text = colors.text-secondary.hex;
        indicator = colors.divider-primary.hex;
        childBorder = colors.divider-primary.hex;
      };

      # Urgent window (demands attention)
      urgent = {
        border = (semantic.status "error" themeMode).hex;
        background = (semantic.status "error" themeMode).hex;
        text = colors.surface-base.hex;
        indicator = (semantic.status "error" themeMode).hex;
        childBorder = (semantic.status "error" themeMode).hex;
      };

      # Placeholder (rare)
      placeholder = {
        border = colors.divider-primary.hex;
        background = colors.surface-base.hex;
        text = colors.text-secondary.hex;
        indicator = colors.divider-primary.hex;
        childBorder = colors.divider-primary.hex;
      };

      # Status bar colors
      background = colors.surface-base.hex;
    };
  };
}
