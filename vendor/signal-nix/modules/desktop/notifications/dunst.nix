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
# HOME-MANAGER MODULE: services.dunst.settings
# UPSTREAM SCHEMA: https://dunst-project.org/documentation/
# SCHEMA VERSION: 1.11.0
# LAST VALIDATED: 2026-01-17
# NOTES: Dunst uses an INI-style config format. Home Manager provides a settings
#        attrset that gets serialized to dunstrc. We theme ONLY colors.
#        Users configure fonts, frame_width, timeouts, etc. in their own config.
#        For complete styling (colors + padding + spacing + animations), use
#        signal-notifications: https://github.com/lewisflude/signal-notifications
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Check if dunst should be themed
  # NOTE: Dunst is a service, not a program, so we check services.dunst.enable
  shouldTheme =
    cfg.desktop.notifications.dunst.enable
    || (cfg.autoEnable && (config.services.dunst.enable or false));

  # Platform guard - Dunst is Linux-only (X11/Wayland notification daemon)
  platformOk = signalLib.platform.guard pkgs "dunst";
in
{
  config = mkIf (cfg.enable && shouldTheme && platformOk) {
    services.dunst.settings = {
      global = {
        # Frame (border) color - using semantic bridge
        frame_color = (semantic.core "focus" themeMode).hex;

        # Separator between notifications color
        separator_color = "frame";
      };

      # Low urgency notifications (informational) - using semantic bridge
      urgency_low = {
        background = (semantic.ui "panel-background" themeMode).hex;
        foreground = (semantic.text "secondary" themeMode).hex;
        frame_color = (semantic.status "info" themeMode).hex;
      };

      # Normal urgency notifications (default) - using semantic bridge
      urgency_normal = {
        background = (semantic.ui "element-hover" themeMode).hex;
        foreground = (semantic.text "primary" themeMode).hex;
        frame_color = (semantic.core "focus" themeMode).hex;
      };

      # Critical urgency notifications (important) - using semantic bridge
      urgency_critical = {
        background = (semantic.status "error" themeMode).hex;
        foreground = (semantic.ui "panel-background" themeMode).hex;
        frame_color = (semantic.status "error" themeMode).hex;
      };
    };
  };
}
