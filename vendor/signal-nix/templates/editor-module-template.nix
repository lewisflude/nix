# Signal-Nix Editor Module Template
#
# This template shows how to create an editor module using the semantic bridge.
# Copy this file and adapt it for your editor.
#
# CONFIGURATION METHOD: structured-colors (Tier 2)
# LAST UPDATED: 2026-01-20
{
  config,
  lib,

  signalLib,
  semantic,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;

  # Resolve theme mode (converts "auto" to "dark" or "light")
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # ============================================================================
  # Color Definitions using Semantic Bridge
  # ============================================================================

  # Editor-specific colors
  editor = {
    background = semantic.editor "background" themeMode;
    foreground = semantic.editor "foreground" themeMode;
    gutter-bg = semantic.editor "gutter-background" themeMode;
    active-line-bg = semantic.editor "active-line-background" themeMode;
    line-number = semantic.editor "line-number" themeMode;
    active-line-number = semantic.editor "active-line-number" themeMode;
    indent-guide = semantic.editor "indent-guide" themeMode;
    indent-guide-active = semantic.editor "indent-guide-active" themeMode;
  };

  # Core UI colors
  ui = {
    cursor = semantic.core "cursor" themeMode;
    selection-bg = semantic.core "selection-bg" themeMode;
    selection-fg = semantic.core "selection-fg" themeMode;
    focus = semantic.core "focus" themeMode;
  };

  # Syntax highlighting colors
  syntax = {
    keyword = semantic.syntax "keyword" themeMode;
    function = semantic.syntax "function" themeMode;
    string = semantic.syntax "string" themeMode;
    number = semantic.syntax "number" themeMode;
    comment = semantic.syntax "comment" themeMode;
    type = semantic.syntax "type" themeMode;
    variable = semantic.syntax "variable" themeMode;
    constant = semantic.syntax "constant" themeMode;
    operator = semantic.syntax "operator" themeMode;
    tag = semantic.syntax "tag" themeMode;
    attribute = semantic.syntax "attribute" themeMode;
    preprocessing = semantic.syntax "preprocessing" themeMode;
  };

  # Status indicators
  status = {
    error = semantic.status "error" themeMode;
    warning = semantic.status "warning" themeMode;
    success = semantic.status "success" themeMode;
    info = semantic.status "info" themeMode;
    hint = semantic.status "hint" themeMode;
  };

  # Version control colors
  vcs = {
    added = semantic.vcs "added" themeMode;
    modified = semantic.vcs "modified" themeMode;
    deleted = semantic.vcs "deleted" themeMode;
    renamed = semantic.vcs "renamed" themeMode;
    conflict = semantic.vcs "conflict" themeMode;
    ignored = semantic.vcs "ignored" themeMode;
  };

  # ============================================================================
  # Theme Activation Logic
  # ============================================================================
  # Replace "myEditor" with your editor's name (e.g., "helix", "vim", "emacs")
  shouldTheme = signalLib.shouldThemeApp "myEditor" [
    "editors"
    "myEditor"
  ] cfg config;
in
{
  # ============================================================================
  # Home Manager Configuration
  # ============================================================================
  config = mkIf (cfg.enable && shouldTheme) {
    # Replace with your editor's Home Manager module path
    # Examples:
    #   programs.helix.settings.theme = "signal-${themeMode}";
    #   programs.neovim.colorscheme = "signal-${themeMode}";
    #   programs.vim.extraConfig = ''colorscheme signal-${themeMode}'';

    programs.myEditor = {
      # Example: Create a theme file or inline theme configuration
      # Each editor has its own format - consult the editor's documentation

      settings = {
        theme = {
          # Editor UI
          "ui.background" = editor.background.hex;
          "ui.text" = editor.foreground.hex;
          "ui.gutter" = editor.gutter-bg.hex;
          "ui.linenr" = editor.line-number.hex;
          "ui.linenr.selected" = editor.active-line-number.hex;
          "ui.cursorline" = editor.active-line-bg.hex;
          "ui.cursor" = ui.cursor.hex;
          "ui.selection" = ui.selection-bg.hex;

          # Syntax highlighting
          "keyword" = syntax.keyword.hex;
          "function" = syntax.function.hex;
          "string" = syntax.string.hex;
          "number" = syntax.number.hex;
          "comment" = syntax.comment.hex;
          "type" = syntax.type.hex;
          "variable" = syntax.variable.hex;
          "constant" = syntax.constant.hex;
          "operator" = syntax.operator.hex;

          # Diagnostics
          "error" = status.error.hex;
          "warning" = status.warning.hex;
          "info" = status.info.hex;
          "hint" = status.hint.hex;

          # VCS/Git
          "diff.plus" = vcs.added.hex;
          "diff.delta" = vcs.modified.hex;
          "diff.minus" = vcs.deleted.hex;
        };
      };
    };
  };
}

# ============================================================================
# Tips for Editor Modules
# ============================================================================
#
# 1. Use semantic.editor for editor-specific UI elements
# 2. Use semantic.syntax for code highlighting
# 3. Use semantic.status for diagnostics/linting
# 4. Use semantic.vcs for git/version control indicators
# 5. Always access colors with .hex (or .rgb, .l, .c, .h as needed)
# 6. Test both light and dark modes
# 7. Consult signal-palette/docs/semantic-bridge.md for complete mappings
#
# For complete reference, see: docs/QUICK_REFERENCE.md
