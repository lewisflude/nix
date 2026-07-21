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
# HOME-MANAGER MODULE: programs.tofi.settings
# UPSTREAM SCHEMA: https://github.com/philj56/tofi
# SCHEMA VERSION: 0.9.1
# LAST VALIDATED: 2026-01-17
# NOTES: tofi uses INI config. Home-Manager provides settings attrset.
#        Minimalist launcher with excellent performance.
let
  inherit (lib) mkIf mkDefault;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for color resolution
  colors = {
    surface-base = semantic.ui "panel-background" themeMode;
    surface-raised = semantic.ui "element-hover" themeMode;
    text-primary = semantic.core "foreground" themeMode;
    text-secondary = semantic.text "secondary" themeMode;
    divider = semantic.ui "panel-border" themeMode;
    selected = semantic.core "focus" themeMode;
  };

  # tofi uses hex colors without #
  toTofiColor = color: lib.removePrefix "#" color.hex;

  # Check if tofi should be themed
  shouldTheme = signalLib.shouldThemeApp "tofi" [
    "desktop"
    "launchers"
    "tofi"
  ] cfg config;

  # Platform guard - Tofi is Linux-only (Wayland launcher)
  platformOk = signalLib.platform.guard pkgs "tofi";
in
{
  config = mkIf (cfg.enable && shouldTheme && platformOk) {
    programs.tofi.settings = {
      # Background
      background-color = mkDefault (toTofiColor colors.surface-base);

      # Text colors
      text-color = mkDefault (toTofiColor colors.text-primary);
      prompt-color = mkDefault (toTofiColor colors.selected);
      placeholder-color = mkDefault (toTofiColor colors.text-secondary);

      # Input
      input-color = mkDefault (toTofiColor colors.text-primary);
      default-result-color = mkDefault (toTofiColor colors.text-secondary);

      # Selection
      selection-color = mkDefault (toTofiColor colors.selected);
      selection-background = mkDefault (toTofiColor colors.surface-raised);

      # Border
      border-color = mkDefault (toTofiColor colors.divider);

      # Outline (for selected item)

      # Corner radius

      # Padding

      # Font (user can override)
    };
  };
}
