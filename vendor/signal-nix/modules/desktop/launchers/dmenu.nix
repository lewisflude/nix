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
# CONFIGURATION METHOD: command-flags (Tier 5)
# HOME-MANAGER MODULE: xdg.configFile wrapper script
# UPSTREAM SCHEMA: https://tools.suckless.org/dmenu/
# SCHEMA VERSION: 5.2
# LAST VALIDATED: 2026-01-17
# NOTES: dmenu is configured via command-line flags. No config file.
#        We create a wrapper script with Signal colors.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;

  # Resolve theme mode
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for color resolution
  colors = {
    surface-base = semantic.ui "panel-background" themeMode;
    surface-raised = semantic.ui "element-hover" themeMode;
    text-primary = semantic.core "foreground" themeMode;
    selected = semantic.core "focus" themeMode;
  };

  # dmenu wrapper script with Signal colors
  dmenuWrapper = ''
    #!/usr/bin/env bash
    # Signal-themed dmenu wrapper

    exec dmenu \
      -nb "${colors.surface-base.hex}" \
      -nf "${colors.text-primary.hex}" \
      -sb "${colors.surface-raised.hex}" \
      -sf "${colors.selected.hex}" \
      -fn "Inter-14" \
      "$@"
  '';

  # Check if dmenu should be themed
  shouldTheme = signalLib.shouldThemeApp "dmenu" [
    "desktop"
    "launchers"
    "dmenu"
  ] cfg config;

  # Platform guard - dmenu is Linux-only (X11 launcher)
  platformOk = signalLib.platform.guard pkgs "dmenu";
in
{
  config = mkIf (cfg.enable && shouldTheme && platformOk) {
    home = {
      # Create wrapper script
      file.".local/bin/dmenu-signal" = {
        text = dmenuWrapper;
        executable = true;
      };

      # Add to PATH
      sessionPath = [ "$HOME/.local/bin" ];

      # Create alias for convenience
      shellAliases = mkIf shouldTheme {
        dmenu = "dmenu-signal";
      };
    };
  };
}
