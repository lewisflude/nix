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
# HOME-MANAGER MODULE: xdg.configFile (programs.tig doesn't exist)
# UPSTREAM SCHEMA: https://github.com/jonas/tig
# SCHEMA VERSION: 2.5.8
# LAST VALIDATED: 2026-01-17
# NOTES: tig uses custom config format stored in ~/.config/tig/config.
#        home-manager doesn't have a programs.tig module, so we use xdg.configFile.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # tig uses color names or 'color<N>' or '#RRGGBB'
  # It also uses terminal color names: black, red, green, yellow, blue, magenta, cyan, white
  # We'll use hex colors for precision

  # Generate tig color config using semantic bridge
  tigConfig =
    let
      bg = (semantic.ui "panel-background" themeMode).hex;
    in
    ''
      # Signal theme for tig

      # General UI
      color default        ${(semantic.text "primary" themeMode).hex} ${bg}
      color cursor         ${bg} ${(semantic.vcs "modified" themeMode).hex} bold
      color title-focus    ${(semantic.text "primary" themeMode).hex} ${bg} bold
      color title-blur     ${(semantic.text "secondary" themeMode).hex} ${bg}

      # Line numbers
      color line-number    ${(semantic.text "disabled" themeMode).hex} ${bg}

      # Diff colors
      color diff-header    ${(semantic.vcs "modified" themeMode).hex} ${bg} bold
      color diff-index     ${(semantic.vcs "modified" themeMode).hex} ${bg}
      color diff-chunk     ${(semantic.vcs "modified" themeMode).hex} ${bg} bold
      color diff-add       ${(semantic.vcs "added" themeMode).hex} ${bg}
      color diff-del       ${(semantic.vcs "deleted" themeMode).hex} ${bg}
      color diff-oldmode   ${(semantic.status "warning" themeMode).hex} ${bg}
      color diff-newmode   ${(semantic.status "warning" themeMode).hex} ${bg}
      color diff-copy-from ${(semantic.vcs "modified" themeMode).hex} ${bg}
      color diff-copy-to   ${(semantic.vcs "modified" themeMode).hex} ${bg}
      color diff-rename-from ${(semantic.vcs "renamed" themeMode).hex} ${bg}
      color diff-rename-to ${(semantic.vcs "renamed" themeMode).hex} ${bg}
      color diff-similarity ${(semantic.vcs "modified" themeMode).hex} ${bg}

      # Status
      color status         ${(semantic.text "primary" themeMode).hex} ${bg}
      color stat-staged    ${(semantic.vcs "added" themeMode).hex} ${bg}
      color stat-unstaged  ${(semantic.status "warning" themeMode).hex} ${bg}
      color stat-untracked ${(semantic.vcs "deleted" themeMode).hex} ${bg}

      # Main view
      color main-commit    ${(semantic.text "primary" themeMode).hex} ${bg}
      color main-tag       ${(semantic.status "warning" themeMode).hex} ${bg} bold
      color main-local-tag ${(semantic.status "warning" themeMode).hex} ${bg}
      color main-remote    ${(semantic.vcs "modified" themeMode).hex} ${bg}
      color main-tracked   ${(semantic.vcs "added" themeMode).hex} ${bg}
      color main-ref       ${(semantic.vcs "modified" themeMode).hex} ${bg}
      color main-head      ${(semantic.vcs "modified" themeMode).hex} ${bg} bold

      # Tree view
      color tree.directory ${(semantic.vcs "modified" themeMode).hex} ${bg}

      # Author colors
      color author         ${(semantic.syntax "keyword" themeMode).hex} ${bg}

      # Commit message
      color commit         ${(semantic.text "primary" themeMode).hex} ${bg}

      # Dates
      color date           ${(semantic.text "secondary" themeMode).hex} ${bg}

      # Graph
      color graph-commit   ${(semantic.vcs "modified" themeMode).hex} ${bg}
    '';

  # Check if tig should be themed
  shouldTheme = cfg.cli.tig.enable or false || cfg.autoEnable;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    # tig configuration is stored in ~/.config/tig/config
    # home-manager doesn't have a programs.tig module, so we use xdg.configFile
    xdg.configFile."tig/config".text = tigConfig;
  };
}
