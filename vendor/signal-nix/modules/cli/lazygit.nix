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
# HOME-MANAGER MODULE: programs.lazygit.settings
# UPSTREAM SCHEMA: https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md
# SCHEMA VERSION: 0.40.2
# LAST VALIDATED: 2026-01-17
# NOTES: Home-Manager provides freeform settings that serialize to YAML config.
#        Theme colors go under gui.theme attrset. Must match lazygit schema.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Check if lazygit should be themed - using centralized helper
  shouldTheme = signalLib.shouldThemeApp "lazygit" [
    "cli"
    "lazygit"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.lazygit.settings = {
      gui = {
        theme = {
          # Border colors - using semantic bridge
          activeBorderColor = [
            (semantic.vcs "modified" themeMode).hex
            "bold"
          ];
          inactiveBorderColor = [ (semantic.ui "panel-border" themeMode).hex ];
          searchingActiveBorderColor = [
            (semantic.vcs "modified" themeMode).hex
            "bold"
          ];

          # Options/help text
          optionsTextColor = [ (semantic.vcs "modified" themeMode).hex ];

          # Selected line colors
          selectedLineBgColor = [ (semantic.ui "panel-border" themeMode).hex ];
          selectedRangeBgColor = [ (semantic.ui "element-hover" themeMode).hex ];
          inactiveViewSelectedLineBgColor = [ (semantic.ui "panel-border" themeMode).hex ];

          # Cherry-picked commit colors
          cherryPickedCommitFgColor = [ (semantic.vcs "modified" themeMode).hex ];
          cherryPickedCommitBgColor = [ (semantic.ui "element-hover" themeMode).hex ];

          # Marked base commit colors (for rebase)
          markedBaseCommitFgColor = [ (semantic.status "warning" themeMode).hex ];
          markedBaseCommitBgColor = [ (semantic.ui "element-hover" themeMode).hex ];

          # File status colors
          unstagedChangesColor = [ (semantic.vcs "deleted" themeMode).hex ];

          # Default text color
          defaultFgColor = [ (semantic.text "primary" themeMode).hex ];
        };
      };
    };
  };
}
