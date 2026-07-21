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
# HOME-MANAGER MODULE: programs.zellij.settings.themes
# UPSTREAM SCHEMA: https://zellij.dev/documentation/themes.html
# SCHEMA VERSION: 0.39.0
# LAST VALIDATED: 2026-01-17
# NOTES: Home-Manager provides freeform settings that serialize to KDL format.
#        Zellij themes require hex color values (e.g., "#6b87c8").
#        Theme structure must match Zellij's component-based schema exactly.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for color resolution
  colors = {
    surface-base = semantic.ui "panel-background" themeMode;
    text-primary = semantic.core "foreground" themeMode;
    text-secondary = semantic.text "secondary" themeMode;
    text-tertiary = semantic.text "tertiary" themeMode;

    # Accent colors for zellij components
    accent-secondary = semantic.core "focus" themeMode;
    accent-primary = semantic.status "success" themeMode;
    accent-warning = semantic.status "warning" themeMode;
    accent-danger = semantic.status "error" themeMode;
    accent-tertiary = semantic.syntax "keyword" themeMode;
    accent-info = semantic.status "info" themeMode;

    # Categorical colors for multiplayer
    player-7 = semantic.multiplayer "player-7" themeMode;
    player-8 = semantic.multiplayer "player-8" themeMode;
  };

  # Extract hex color strings for Zellij theme format
  # Home Manager serializes to KDL format which expects hex colors
  toZellijColor = signalLib.toHex;

  # Check if zellij should be themed - using centralized helper
  shouldTheme = signalLib.shouldThemeApp "zellij" [
    "multiplexers"
    "zellij"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.zellij = {
      # Zellij theme in KDL format
      settings = {
        themes.signal = {
          # Text components
          text_unselected = {
            base = toZellijColor colors.text-primary;
            background = toZellijColor colors.surface-base;
            emphasis_0 = toZellijColor colors.accent-secondary;
            emphasis_1 = toZellijColor colors.accent-secondary;
            emphasis_2 = toZellijColor colors.accent-primary;
            emphasis_3 = toZellijColor colors.accent-warning;
          };

          text_selected = {
            base = toZellijColor colors.text-primary;
            background = toZellijColor colors.accent-secondary;
            emphasis_0 = toZellijColor colors.surface-base;
            emphasis_1 = toZellijColor colors.text-primary;
            emphasis_2 = toZellijColor colors.accent-primary;
            emphasis_3 = toZellijColor colors.accent-warning;
          };

          # Ribbon components (tabs, status bar)
          ribbon_unselected = {
            base = toZellijColor colors.text-secondary;
            background = toZellijColor colors.surface-base;
            emphasis_0 = toZellijColor colors.accent-danger;
            emphasis_1 = toZellijColor colors.accent-warning;
            emphasis_2 = toZellijColor colors.accent-secondary;
            emphasis_3 = toZellijColor colors.accent-secondary;
          };

          ribbon_selected = {
            base = toZellijColor colors.text-primary;
            background = toZellijColor colors.accent-secondary;
            emphasis_0 = toZellijColor colors.surface-base;
            emphasis_1 = toZellijColor colors.text-primary;
            emphasis_2 = toZellijColor colors.accent-primary;
            emphasis_3 = toZellijColor colors.accent-secondary;
          };

          # Table components
          table_title = {
            base = toZellijColor colors.text-primary;
            background = toZellijColor colors.surface-base;
            emphasis_0 = toZellijColor colors.accent-secondary;
            emphasis_1 = toZellijColor colors.accent-secondary;
            emphasis_2 = toZellijColor colors.accent-primary;
            emphasis_3 = toZellijColor colors.accent-warning;
          };

          table_cell_unselected = {
            base = toZellijColor colors.text-secondary;
            background = toZellijColor colors.surface-base;
            emphasis_0 = toZellijColor colors.accent-secondary;
            emphasis_1 = toZellijColor colors.accent-secondary;
            emphasis_2 = toZellijColor colors.accent-primary;
            emphasis_3 = toZellijColor colors.accent-warning;
          };

          table_cell_selected = {
            base = toZellijColor colors.text-primary;
            background = toZellijColor colors.accent-secondary;
            emphasis_0 = toZellijColor colors.surface-base;
            emphasis_1 = toZellijColor colors.text-primary;
            emphasis_2 = toZellijColor colors.accent-primary;
            emphasis_3 = toZellijColor colors.accent-warning;
          };

          # List components
          list_unselected = {
            base = toZellijColor colors.text-secondary;
            background = toZellijColor colors.surface-base;
            emphasis_0 = toZellijColor colors.accent-secondary;
            emphasis_1 = toZellijColor colors.accent-secondary;
            emphasis_2 = toZellijColor colors.accent-primary;
            emphasis_3 = toZellijColor colors.accent-warning;
          };

          list_selected = {
            base = toZellijColor colors.text-primary;
            background = toZellijColor colors.accent-secondary;
            emphasis_0 = toZellijColor colors.surface-base;
            emphasis_1 = toZellijColor colors.text-primary;
            emphasis_2 = toZellijColor colors.accent-primary;
            emphasis_3 = toZellijColor colors.accent-warning;
          };

          # Frame (pane borders)
          frame_unselected = {
            base = toZellijColor colors.text-tertiary;
            background = toZellijColor colors.surface-base;
            emphasis_0 = toZellijColor colors.accent-secondary;
            emphasis_1 = toZellijColor colors.accent-secondary;
            emphasis_2 = toZellijColor colors.accent-primary;
            emphasis_3 = toZellijColor colors.accent-warning;
          };

          frame_selected = {
            base = toZellijColor colors.accent-secondary;
            background = toZellijColor colors.surface-base;
            emphasis_0 = toZellijColor colors.accent-secondary;
            emphasis_1 = toZellijColor colors.accent-secondary;
            emphasis_2 = toZellijColor colors.accent-primary;
            emphasis_3 = toZellijColor colors.accent-warning;
          };

          frame_highlight = {
            base = toZellijColor colors.accent-tertiary;
            background = toZellijColor colors.surface-base;
            emphasis_0 = toZellijColor colors.accent-tertiary;
            emphasis_1 = toZellijColor colors.accent-secondary;
            emphasis_2 = toZellijColor colors.accent-primary;
            emphasis_3 = toZellijColor colors.accent-warning;
          };

          # Exit codes
          exit_code_success = {
            base = toZellijColor colors.accent-primary;
            background = toZellijColor colors.surface-base;
            emphasis_0 = toZellijColor colors.accent-primary;
            emphasis_1 = toZellijColor colors.accent-primary;
            emphasis_2 = toZellijColor colors.accent-primary;
            emphasis_3 = toZellijColor colors.accent-primary;
          };

          exit_code_error = {
            base = toZellijColor colors.accent-danger;
            background = toZellijColor colors.surface-base;
            emphasis_0 = toZellijColor colors.accent-danger;
            emphasis_1 = toZellijColor colors.accent-danger;
            emphasis_2 = toZellijColor colors.accent-danger;
            emphasis_3 = toZellijColor colors.accent-danger;
          };

          # Multiplayer user colors
          multiplayer_user_colors = [
            (toZellijColor colors.accent-secondary) # Player 1
            (toZellijColor colors.accent-secondary) # Player 2
            (toZellijColor colors.accent-primary) # Player 3
            (toZellijColor colors.accent-warning) # Player 4
            (toZellijColor colors.accent-tertiary) # Player 5
            (toZellijColor colors.accent-danger) # Player 6
            (toZellijColor colors.player-7) # Player 7
            (toZellijColor colors.player-8) # Player 8
            (toZellijColor (semantic.multiplayer "player-1" themeMode)) # Player 9
            (toZellijColor colors.text-primary) # Player 10
          ];
        };

        # Use Signal theme
        theme = "signal";
      };
    };
  };
}
