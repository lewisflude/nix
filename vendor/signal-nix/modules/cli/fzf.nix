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
# CONFIGURATION METHOD: raw-config (Tier 4)
# HOME-MANAGER MODULE: programs.fzf.defaultOptions
# UPSTREAM SCHEMA: https://github.com/junegunn/fzf#color-configuration
# SCHEMA VERSION: 0.47.0
# LAST VALIDATED: 2026-01-17
# NOTES: FZF colors require --color flags with # prefix. Home-Manager's
#        programs.fzf.colors strips the # prefix, causing errors. We use
#        defaultOptions to preserve the # prefix in color values.
let
  inherit (lib) mkIf mkAfter mapAttrsToList;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Define color mappings using semantic bridge
  colorMap = {
    fg = (semantic.text "primary" themeMode).hex;
    bg = (semantic.ui "panel-background" themeMode).hex;
    hl = (semantic.vcs "modified" themeMode).hex;
    "fg+" = (semantic.text "primary" themeMode).hex;
    "bg+" = (semantic.ui "panel-border" themeMode).hex;
    "hl+" = (semantic.vcs "modified" themeMode).hex;
    info = (semantic.vcs "modified" themeMode).hex;
    prompt = (semantic.vcs "modified" themeMode).hex;
    pointer = (semantic.vcs "modified" themeMode).hex;
    marker = (semantic.vcs "added" themeMode).hex;
    spinner = (semantic.vcs "modified" themeMode).hex;
    header = (semantic.text "secondary" themeMode).hex;
  };

  # fzf requires hex colors WITH # prefix in --color options
  # Home Manager's programs.fzf.colors strips the # prefix, which causes errors
  # Solution: Use defaultOptions to set colors directly with # prefix preserved
  fzfColorOptions = mapAttrsToList (key: value: "--color=${key}:${value}") colorMap;

  # Check if fzf should be themed - using centralized helper
  shouldTheme = signalLib.shouldThemeApp "fzf" [
    "cli"
    "fzf"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    # Use defaultOptions to preserve # prefix (programs.fzf.colors strips it)
    programs.fzf.defaultOptions = mkAfter fzfColorOptions;
  };
}
