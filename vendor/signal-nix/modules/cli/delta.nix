# Signal Delta Theme Module
#
# This module ONLY applies Signal colors to delta.
# It assumes you have already enabled delta with:
#   programs.delta.enable = true;
#
# The module will not install delta or configure its functional behavior.
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
# HOME-MANAGER MODULE: programs.delta.options
# UPSTREAM SCHEMA: https://dandavison.github.io/delta/configuration.html
# SCHEMA VERSION: 0.16.5
# LAST VALIDATED: 2026-01-17
# NOTES: Home-Manager provides freeform options attrset that serializes to gitconfig
#        format. All option names must match delta's configuration schema exactly.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Define color mappings using semantic bridge
  deltaColors = {
    # Diff backgrounds - use emphasis colors for highlighted changes
    # Note: Delta uses "syntax" prefix for some styles
    minus-style = "syntax ${(semantic.ui "element-hover" themeMode).hex}";
    minus-emph-style = "syntax ${(semantic.vcs "deleted" themeMode).hex}";
    minus-non-emph-style = "syntax ${(semantic.ui "element-hover" themeMode).hex}";
    plus-style = "syntax ${(semantic.ui "element-hover" themeMode).hex}";
    plus-emph-style = "syntax ${(semantic.vcs "added" themeMode).hex}";
    plus-non-emph-style = "syntax ${(semantic.ui "element-hover" themeMode).hex}";

    # Line numbers
    line-numbers-minus-style = (semantic.vcs "deleted" themeMode).hex;
    line-numbers-plus-style = (semantic.vcs "added" themeMode).hex;
    line-numbers-zero-style = (semantic.text "disabled" themeMode).hex;
    line-numbers-left-style = (semantic.text "disabled" themeMode).hex;
    line-numbers-right-style = (semantic.text "disabled" themeMode).hex;

    # File decoration
    file-style = (semantic.vcs "modified" themeMode).hex;
    file-decoration-style = "${(semantic.vcs "modified" themeMode).hex} ul";

    # Commit decoration
    commit-decoration-style = "${(semantic.syntax "keyword" themeMode).hex} box";
    commit-style = (semantic.syntax "keyword" themeMode).hex;

    # Hunk header
    hunk-header-style = "syntax ${(semantic.ui "panel-border" themeMode).hex}";
    hunk-header-decoration-style = "${(semantic.vcs "modified" themeMode).hex} box";
    hunk-header-file-style = (semantic.vcs "modified" themeMode).hex;
    hunk-header-line-number-style = (semantic.text "secondary" themeMode).hex;

    # Blame - use categorical colors for distinct visualization
    blame-palette = "${(semantic.multiplayer "player-1" themeMode).hex} ${(semantic.multiplayer "player-2" themeMode).hex} ${(semantic.multiplayer "player-3" themeMode).hex} ${(semantic.multiplayer "player-4" themeMode).hex} ${(semantic.multiplayer "player-5" themeMode).hex} ${(semantic.multiplayer "player-6" themeMode).hex}";

    # Merge conflict
    merge-conflict-begin-symbol = "▼";
    merge-conflict-end-symbol = "▲";
    merge-conflict-ours-diff-header-style = "${(semantic.status "warning" themeMode).hex} bold";
    merge-conflict-theirs-diff-header-style = "${(semantic.vcs "modified" themeMode).hex} bold";
  };

  # Check if delta should be themed
  # Check if delta should be themed - using centralized helper
  shouldTheme = signalLib.shouldThemeApp "delta" [
    "cli"
    "delta"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    # Assumes user has already set programs.delta.enable = true
    programs.delta.options = {
      # Syntax highlighting theme
      # Delta uses bat's themes, so we use the Signal theme we created for bat
      syntax-theme =
        if cfg.mode == "auto" then "auto" else "signal-${signalLib.resolveThemeMode cfg.mode}";

      # Apply Signal colors
      inherit (deltaColors)
        minus-style
        minus-emph-style
        minus-non-emph-style
        plus-style
        plus-emph-style
        plus-non-emph-style

        # Line numbers
        line-numbers-minus-style
        line-numbers-plus-style
        line-numbers-zero-style
        line-numbers-left-style
        line-numbers-right-style

        # File decoration
        file-style
        file-decoration-style

        # Commit decoration
        commit-decoration-style
        commit-style

        # Hunk header
        hunk-header-style
        hunk-header-decoration-style
        hunk-header-file-style
        hunk-header-line-number-style

        # Blame
        blame-palette

        # Merge conflict
        merge-conflict-begin-symbol
        merge-conflict-end-symbol
        merge-conflict-ours-diff-header-style
        merge-conflict-theirs-diff-header-style
        ;
    };
  };
}
