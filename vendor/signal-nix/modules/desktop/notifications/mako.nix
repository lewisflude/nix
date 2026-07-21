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
# HOME-MANAGER MODULE: services.mako (via programs.mako in newer HM)
# UPSTREAM SCHEMA: https://github.com/emersion/mako
# SCHEMA VERSION: 1.8.0
# LAST VALIDATED: 2026-01-17
# NOTES: mako uses INI-like config. Home Manager provides extraConfig or
#        direct configuration options.
#        Signal ONLY sets colors - users configure fonts, spacing, timeouts, etc.
#        For complete styling (colors + padding + spacing + animations), use
#        signal-notifications: https://github.com/lewisflude/signal-notifications
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # mako uses hex colors without #
  toMakoColor = color: lib.removePrefix "#" color;

  # Generate mako config using semantic bridge - COLORS ONLY
  makoConfig = ''
    # Signal theme for mako - COLORS ONLY
    # Configure fonts, spacing, timeouts, etc. in your own mako config

    # Default notification colors
    background-color=${toMakoColor (semantic.ui "element-hover" themeMode).hex}
    text-color=${toMakoColor (semantic.text "primary" themeMode).hex}
    border-color=${toMakoColor (semantic.ui "panel-border" themeMode).hex}

    # Progress bar color
    progress-color=${toMakoColor (semantic.core "focus" themeMode).hex}

    # Low urgency colors
    [urgency=low]
    background-color=${toMakoColor (semantic.ui "element-hover" themeMode).hex}
    border-color=${toMakoColor (semantic.status "info" themeMode).hex}
    text-color=${toMakoColor (semantic.text "secondary" themeMode).hex}

    # Normal urgency colors
    [urgency=normal]
    background-color=${toMakoColor (semantic.ui "element-hover" themeMode).hex}
    border-color=${toMakoColor (semantic.core "focus" themeMode).hex}
    text-color=${toMakoColor (semantic.text "primary" themeMode).hex}

    # Critical urgency colors
    [urgency=critical]
    background-color=${toMakoColor (semantic.ui "element-hover" themeMode).hex}
    border-color=${toMakoColor (semantic.status "error" themeMode).hex}
    text-color=${toMakoColor (semantic.text "primary" themeMode).hex}
  '';

  # Check if mako should be themed
  # NOTE: Mako can be a service OR a program depending on Home Manager version
  # Check both services.mako.enable and programs.mako.enable
  shouldTheme =
    cfg.desktop.notifications.mako.enable
    || (
      cfg.autoEnable && ((config.services.mako.enable or false) || (config.programs.mako.enable or false))
    );

  # Platform guard - Mako is Linux-only (Wayland notification daemon)
  platformOk = signalLib.platform.guard pkgs "mako";
in
{
  config = mkIf (cfg.enable && shouldTheme && platformOk) {
    # mako can be configured via services.mako or programs.mako
    # We use xdg.configFile for maximum compatibility
    xdg.configFile."mako/config".text = makoConfig;
  };
}
