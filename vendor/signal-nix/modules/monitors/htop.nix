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
# HOME-MANAGER MODULE: programs.htop.settings
# UPSTREAM SCHEMA: https://github.com/htop-dev/htop
# SCHEMA VERSION: 3.3.0
# LAST VALIDATED: 2026-01-17
# NOTES: htop uses numeric color codes (0-255) in its config. Home-Manager provides
#        a settings attrset. We need to map Signal colors to the closest terminal
#        colors since htop doesn't support true color.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for color resolution
  # htop color codes (0-7 are standard ANSI)
  # We use the standard ANSI colors which will be themed by the terminal
  htopColors = {
    black = 0;
    red = 1;
    green = 2;
    yellow = 3;
    blue = 4;
    magenta = 5;
    cyan = 6;
    white = 7;
  };

  # Check if htop should be themed
  shouldTheme = signalLib.shouldThemeApp "htop" [
    "monitors"
    "htop"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.htop.settings = {
      # Color scheme (0 = default, 1 = monochrome, 2 = blacknight, 3 = breeze, etc.)
      # We use 0 (default) but customize individual colors
      color_scheme = 0;

      # Enable colors
      highlight_base_name = 1;
      highlight_deleted_exe = 1;
      highlight_megabytes = 1;
      highlight_threads = 1;

      # Color customization
      # Format: element_color=foreground,background
      # Using ANSI color codes that will be themed by the terminal

      # We rely on the terminal's ANSI colors being themed by Signal
      # (via kitty, alacritty, etc.) rather than trying to specify colors here
      # htop will use the terminal's color palette
    };
  };
}
