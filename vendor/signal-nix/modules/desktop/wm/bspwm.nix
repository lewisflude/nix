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
# CONFIGURATION METHOD: freeform-settings (Tier 3)
# HOME-MANAGER MODULE: xsession.windowManager.bspwm.settings
# UPSTREAM SCHEMA: https://github.com/baskerville/bspwm
# SCHEMA VERSION: 0.9.10
# LAST VALIDATED: 2026-01-17
# NOTES: bspwm uses shell commands for config. Home-Manager provides settings
#        attrset that gets serialized to bspwmrc. We set color options.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # bspwm uses hex colors with #
  # Check if bspwm should be themed
  shouldTheme = signalLib.shouldThemeApp "bspwm" [
    "desktop"
    "wm"
    "bspwm"
  ] cfg config;

  # Platform guard - bspwm is Linux-only (X11 window manager)
  platformOk = signalLib.platform.guard pkgs "bspwm";
in
{
  config = mkIf (cfg.enable && shouldTheme && platformOk) {
    xsession.windowManager.bspwm.settings = {
      # Border colors - using semantic bridge
      normal_border_color = (semantic.ui "panel-border" themeMode).hex;
      active_border_color = (semantic.ui "element-active" themeMode).hex;
      focused_border_color = (semantic.vcs "modified" themeMode).hex;
      presel_feedback_color = (semantic.vcs "modified" themeMode).hex;

      # Border width (user can override)
      border_width = lib.mkDefault 2;

      # Gap size (user can override)
      window_gap = lib.mkDefault 8;
    };
  };
}
