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
# HOME-MANAGER MODULE: programs.lazydocker.settings
# UPSTREAM SCHEMA: https://github.com/jesseduffield/lazydocker
# SCHEMA VERSION: 0.23.1
# LAST VALIDATED: 2026-01-17
# NOTES: Home-Manager now has a lazydocker module with settings support (as of 2025).
#        Previously disabled due to conflict between xdg.configFile and home.file,
#        but the upstream module now properly uses home.file to avoid conflicts.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Check if lazydocker should be themed
  shouldTheme = signalLib.shouldThemeApp "lazydocker" [
    "cli"
    "lazydocker"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.lazydocker = {
      settings = {
        gui = {
          theme = {
            lightTheme = cfg.mode == "light";
            activeBorderColor = [
              (semantic.vcs "modified" themeMode).hex
              "bold"
            ];
            inactiveBorderColor = [ (semantic.ui "panel-border" themeMode).hex ];
            searchingActiveBorderColor = [
              (semantic.status "warning" themeMode).hex
              "bold"
            ];
            optionsTextColor = [ (semantic.vcs "modified" themeMode).hex ];
            selectedLineBgColor = [ (semantic.ui "element-hover" themeMode).hex ];
            selectedRangeBgColor = [ (semantic.ui "element-hover" themeMode).hex ];
            cherryPickedCommitBgColor = [ (semantic.vcs "modified" themeMode).hex ];
            cherryPickedCommitFgColor = [ (semantic.ui "panel-background" themeMode).hex ];
            unstagedChangesColor = [ (semantic.vcs "deleted" themeMode).hex ];
            defaultFgColor = [ (semantic.text "primary" themeMode).hex ];
          };
        };
        reporting = {
          containerStatusHealthy = (semantic.status "success" themeMode).hex;
          containerStatusUnhealthy = (semantic.status "error" themeMode).hex;
          containerStatusExited = (semantic.text "disabled" themeMode).hex;
          containerStatusRunning = (semantic.vcs "modified" themeMode).hex;
          containerStatusPaused = (semantic.status "warning" themeMode).hex;
        };
      };
    };
  };
}
