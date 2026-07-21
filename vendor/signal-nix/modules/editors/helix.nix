# Signal Helix Theme Module
#
# This module ONLY applies Signal colors to helix.
# It assumes you have already enabled helix with:
#   programs.helix.enable = true;
#
# The module will not install helix or configure its functional behavior.
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
# CONFIGURATION METHOD: native-theme (Tier 1)
# HOME-MANAGER MODULE: programs.helix.themes
# UPSTREAM SCHEMA: https://docs.helix-editor.com/themes.html
# SCHEMA VERSION: 23.10
# LAST VALIDATED: 2026-01-20
# NOTES: Helix provides native theme support with palette structure. Home-Manager
#        handles theme installation. This is the optimal integration method.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Define colors using semantic bridge
  colors = {
    # Editor UI
    background = semantic.editor "background" themeMode;
    foreground = semantic.editor "foreground" themeMode;
    gutter-bg = semantic.editor "gutter-background" themeMode;
    active-line-bg = semantic.editor "active-line-background" themeMode;
    line-number = semantic.editor "line-number" themeMode;
    active-line-number = semantic.editor "active-line-number" themeMode;
    indent-guide = semantic.editor "indent-guide" themeMode;
    indent-guide-active = semantic.editor "indent-guide-active" themeMode;

    # Core UI
    cursor = semantic.core "cursor" themeMode;
    selection-bg = semantic.core "selection-bg" themeMode;
    selection-fg = semantic.core "selection-fg" themeMode;
    focus = semantic.core "focus" themeMode;

    # Syntax
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

    # Status
    error = semantic.status "error" themeMode;
    warning = semantic.status "warning" themeMode;
    success = semantic.status "success" themeMode;
    info = semantic.status "info" themeMode;
    hint = semantic.status "hint" themeMode;

    # VCS
    added = semantic.vcs "added" themeMode;
    modified = semantic.vcs "modified" themeMode;
    deleted = semantic.vcs "deleted" themeMode;

    # UI components
    panel-bg = semantic.ui "panel-background" themeMode;
    panel-border = semantic.ui "panel-border" themeMode;
    element-hover = semantic.ui "element-hover" themeMode;
    element-active = semantic.ui "element-active" themeMode;
    element-selected = semantic.ui "element-selected" themeMode;

    # Multiplayer colors for rainbow brackets
    player-1 = semantic.multiplayer "player-1" themeMode;
    player-2 = semantic.multiplayer "player-2" themeMode;
    player-3 = semantic.multiplayer "player-3" themeMode;
    player-4 = semantic.multiplayer "player-4" themeMode;
    player-5 = semantic.multiplayer "player-5" themeMode;
    player-6 = semantic.multiplayer "player-6" themeMode;
  };

  # Generate Helix theme with palette structure
  helixTheme = {
    # Syntax highlighting - using semantic bridge
    "attribute" = "attribute";
    "type" = "type";
    "type.enum.variant" = "string";

    "constructor" = "function";

    "constant" = "constant";
    "constant.character" = "string";
    "constant.character.escape" = "preprocessing";

    "string" = "string";
    "string.regexp" = "preprocessing";
    "string.special" = "function";
    "string.special.symbol" = "error";

    "comment" = {
      fg = "comment";
      modifiers = [ "italic" ];
    };

    "variable" = "variable";
    "variable.parameter" = {
      fg = "variable";
      modifiers = [ "italic" ];
    };
    "variable.builtin" = "error";
    "variable.other.member" = "function";

    "label" = "function";

    "punctuation" = "comment";
    "punctuation.special" = "info";

    "keyword" = "keyword";
    "keyword.control.conditional" = {
      fg = "keyword";
      modifiers = [ "italic" ];
    };

    "operator" = "operator";

    "function" = "function";
    "function.macro" = "preprocessing";

    "tag" = "tag";

    "namespace" = {
      fg = "type";
      modifiers = [ "italic" ];
    };

    "special" = "function";

    # Markup
    "markup.heading.1" = "error";
    "markup.heading.2" = "type";
    "markup.heading.3" = "type";
    "markup.heading.4" = "string";
    "markup.heading.5" = "function";
    "markup.heading.6" = "keyword";
    "markup.list" = "string";
    "markup.list.unchecked" = "comment";
    "markup.list.checked" = "string";
    "markup.bold" = {
      fg = "error";
      modifiers = [ "bold" ];
    };
    "markup.italic" = {
      fg = "error";
      modifiers = [ "italic" ];
    };
    "markup.link.url" = {
      fg = "function";
      modifiers = [
        "italic"
        "underlined"
      ];
    };
    "markup.link.text" = "keyword";
    "markup.link.label" = "function";
    "markup.raw" = "string";
    "markup.quote" = "preprocessing";

    # Diff
    "diff.plus" = "added";
    "diff.minus" = "deleted";
    "diff.delta" = "modified";

    # User Interface
    "ui.background" = {
      fg = "foreground";
      bg = "background";
    };

    "ui.linenr" = "line-number";
    "ui.linenr.selected" = "active-line-number";

    "ui.statusline" = {
      fg = "foreground";
      bg = "panel-bg";
    };
    "ui.statusline.inactive" = {
      fg = "comment";
      bg = "panel-bg";
    };
    "ui.statusline.normal" = {
      fg = "background";
      bg = "info";
      modifiers = [ "bold" ];
    };
    "ui.statusline.insert" = {
      fg = "background";
      bg = "success";
      modifiers = [ "bold" ];
    };
    "ui.statusline.select" = {
      fg = "background";
      bg = "keyword";
      modifiers = [ "bold" ];
    };

    "ui.popup" = {
      fg = "foreground";
      bg = "panel-bg";
    };
    "ui.window" = "panel-border";
    "ui.help" = {
      fg = "comment";
      bg = "panel-bg";
    };

    "ui.bufferline" = {
      fg = "comment";
      bg = "panel-bg";
    };
    "ui.bufferline.active" = {
      fg = "keyword";
      bg = "background";
      underline = {
        color = "keyword";
        style = "line";
      };
    };
    "ui.bufferline.background" = {
      bg = "background";
    };

    "ui.text" = "foreground";
    "ui.text.focus" = {
      fg = "foreground";
      bg = "element-selected";
      modifiers = [ "bold" ];
    };
    "ui.text.inactive" = "comment";
    "ui.text.directory" = "function";

    "ui.virtual" = "comment";
    "ui.virtual.ruler" = {
      bg = "active-line-bg";
    };
    "ui.virtual.indent-guide" = "indent-guide";
    "ui.virtual.inlay-hint" = {
      fg = "hint";
      bg = "panel-bg";
    };
    "ui.virtual.jump-label" = {
      fg = "warning";
      modifiers = [ "bold" ];
    };

    "ui.selection" = {
      bg = "selection-bg";
    };

    "ui.cursor" = {
      fg = "background";
      bg = "comment";
    };
    "ui.cursor.primary" = {
      fg = "background";
      bg = "cursor";
    };
    "ui.cursor.match" = {
      fg = "focus";
      modifiers = [ "bold" ];
    };

    "ui.cursor.primary.normal" = {
      fg = "background";
      bg = "cursor";
    };
    "ui.cursor.primary.insert" = {
      fg = "background";
      bg = "success";
    };
    "ui.cursor.primary.select" = {
      fg = "background";
      bg = "keyword";
    };

    "ui.cursor.normal" = {
      fg = "background";
      bg = "comment";
    };
    "ui.cursor.insert" = {
      fg = "background";
      bg = "success";
    };
    "ui.cursor.select" = {
      fg = "background";
      bg = "keyword";
    };

    "ui.cursorline.primary" = {
      bg = "active-line-bg";
    };

    "ui.highlight" = {
      bg = "element-selected";
      modifiers = [ "bold" ];
    };

    "ui.menu" = {
      fg = "foreground";
      bg = "panel-bg";
    };
    "ui.menu.selected" = {
      fg = "foreground";
      bg = "element-selected";
      modifiers = [ "bold" ];
    };

    "diagnostic.error" = {
      underline = {
        color = "error";
        style = "curl";
      };
    };
    "diagnostic.warning" = {
      underline = {
        color = "warning";
        style = "curl";
      };
    };
    "diagnostic.info" = {
      underline = {
        color = "info";
        style = "curl";
      };
    };
    "diagnostic.hint" = {
      underline = {
        color = "hint";
        style = "curl";
      };
    };
    "diagnostic.unnecessary" = {
      modifiers = [ "dim" ];
    };

    error = "error";
    warning = "warning";
    info = "info";
    hint = "hint";

    rainbow = [
      "player-1"
      "player-2"
      "player-3"
      "player-4"
      "player-5"
      "player-6"
    ];

    # Palette - Define all colors used in the theme (using semantic colors)
    palette = {
      # Editor UI
      background = colors.background.hex;
      foreground = colors.foreground.hex;
      gutter-bg = colors.gutter-bg.hex;
      active-line-bg = colors.active-line-bg.hex;
      line-number = colors.line-number.hex;
      active-line-number = colors.active-line-number.hex;
      indent-guide = colors.indent-guide.hex;
      indent-guide-active = colors.indent-guide-active.hex;

      # Core UI
      cursor = colors.cursor.hex;
      selection-bg = colors.selection-bg.hex;
      selection-fg = colors.selection-fg.hex;
      focus = colors.focus.hex;

      # Syntax
      keyword = colors.keyword.hex;
      function = colors.function.hex;
      string = colors.string.hex;
      number = colors.number.hex;
      comment = colors.comment.hex;
      type = colors.type.hex;
      variable = colors.variable.hex;
      constant = colors.constant.hex;
      operator = colors.operator.hex;
      tag = colors.tag.hex;
      attribute = colors.attribute.hex;
      preprocessing = colors.preprocessing.hex;

      # Status
      error = colors.error.hex;
      warning = colors.warning.hex;
      success = colors.success.hex;
      info = colors.info.hex;
      hint = colors.hint.hex;

      # VCS
      added = colors.added.hex;
      modified = colors.modified.hex;
      deleted = colors.deleted.hex;

      # UI Components
      panel-bg = colors.panel-bg.hex;
      panel-border = colors.panel-border.hex;
      element-hover = colors.element-hover.hex;
      element-active = colors.element-active.hex;
      element-selected = colors.element-selected.hex;

      # Rainbow/multiplayer
      player-1 = colors.player-1.hex;
      player-2 = colors.player-2.hex;
      player-3 = colors.player-3.hex;
      player-4 = colors.player-4.hex;
      player-5 = colors.player-5.hex;
      player-6 = colors.player-6.hex;
    };
  };
  # Check if helix should be themed
  # Check if helix should be themed - using centralized helper
  shouldTheme = signalLib.shouldThemeApp "helix" [
    "editors"
    "helix"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.helix = {
      settings = {
        theme = "signal-${themeMode}";
      };

      themes."signal-${themeMode}" = helixTheme;
    };
  };
}
