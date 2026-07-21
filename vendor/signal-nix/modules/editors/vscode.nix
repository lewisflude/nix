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
# CONFIGURATION METHOD: json-settings (Tier 2)
# HOME-MANAGER MODULE: programs.vscode.profiles.default.userSettings
# UPSTREAM SCHEMA: https://code.visualstudio.com/docs/getstarted/themes
# SCHEMA VERSION: 1.95.0
# LAST VALIDATED: 2026-01-20
# NOTES: VS Code uses a JSON settings file. Home-Manager provides userSettings
#        attrset. We define workbench colors and editor token colors.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Define colors using semantic bridge
  colors = {
    # Editor UI
    bg = semantic.editor "background" themeMode;
    bg-alt = semantic.editor "active-line-background" themeMode;
    fg = semantic.editor "foreground" themeMode;
    fg-alt = semantic.editor "line-number" themeMode;
    fg-dim = semantic.syntax "comment" themeMode;
    border = semantic.ui "panel-border" themeMode;

    # Core UI
    cursor = semantic.core "cursor" themeMode;
    selection = semantic.core "selection-bg" themeMode;
    focus = semantic.core "focus" themeMode;

    # Syntax colors
    keyword = semantic.syntax "keyword" themeMode;
    function = semantic.syntax "function" themeMode;
    string = semantic.syntax "string" themeMode;
    number = semantic.syntax "number" themeMode;
    type = semantic.syntax "type" themeMode;
    constant = semantic.syntax "constant" themeMode;
    operator = semantic.syntax "operator" themeMode;
    tag = semantic.syntax "tag" themeMode;
    preprocessing = semantic.syntax "preprocessing" themeMode;

    # Status colors
    error = semantic.status "error" themeMode;
    warning = semantic.status "warning" themeMode;
    success = semantic.status "success" themeMode;
    info = semantic.status "info" themeMode;

    # VCS colors
    added = semantic.vcs "added" themeMode;
    modified = semantic.vcs "modified" themeMode;
    deleted = semantic.vcs "deleted" themeMode;

    # UI Components
    panel-bg = semantic.ui "panel-background" themeMode;
    element-hover = semantic.ui "element-hover" themeMode;
    element-active = semantic.ui "element-active" themeMode;
    element-selected = semantic.ui "element-selected" themeMode;
  };

  # Check if vscode should be themed
  # Only theme if the program is actually enabled
  vscodeEnabled = config.programs.vscode.enable or false;

  shouldTheme =
    vscodeEnabled
    && (signalLib.shouldThemeApp "vscode" [
      "editors"
      "vscode"
    ] cfg config);

  vscodeSettings = {
    "workbench.colorTheme" = "Signal";
    "workbench.colorCustomizations" = {
      # Editor colors
      "editor.background" = colors.bg.hex;
      "editor.foreground" = colors.fg.hex;
      "editor.lineHighlightBackground" = colors.bg-alt.hex;
      "editor.selectionBackground" = colors.selection.hex;
      "editor.selectionHighlightBackground" = "${colors.selection.hex}80";
      "editor.wordHighlightBackground" = "${colors.selection.hex}60";
      "editor.wordHighlightStrongBackground" = "${colors.selection.hex}80";
      "editor.findMatchBackground" = "${colors.warning.hex}60";
      "editor.findMatchHighlightBackground" = "${colors.warning.hex}40";
      "editor.hoverHighlightBackground" = colors.bg-alt.hex;
      "editor.lineHighlightBorder" = colors.selection.hex;

      # Cursor
      "editorCursor.foreground" = colors.cursor.hex;

      # Line numbers
      "editorLineNumber.foreground" = colors.fg-dim.hex;
      "editorLineNumber.activeForeground" = colors.fg-alt.hex;

      # Gutter
      "editorGutter.background" = colors.bg.hex;
      "editorGutter.addedBackground" = colors.added.hex;
      "editorGutter.modifiedBackground" = colors.cursor.hex;
      "editorGutter.deletedBackground" = colors.error.hex;

      # Sidebar
      "sideBar.background" = colors.bg.hex;
      "sideBar.foreground" = colors.fg-alt.hex;
      "sideBar.border" = colors.selection.hex;
      "sideBarTitle.foreground" = colors.fg.hex;
      "sideBarSectionHeader.background" = colors.bg-alt.hex;

      # Activity bar
      "activityBar.background" = colors.bg.hex;
      "activityBar.foreground" = colors.fg.hex;
      "activityBar.inactiveForeground" = colors.fg-dim.hex;
      "activityBar.border" = colors.selection.hex;
      "activityBarBadge.background" = colors.cursor.hex;
      "activityBarBadge.foreground" = colors.bg.hex;

      # Status bar
      "statusBar.background" = colors.bg-alt.hex;
      "statusBar.foreground" = colors.fg.hex;
      "statusBar.border" = colors.selection.hex;
      "statusBar.debuggingBackground" = colors.warning.hex;
      "statusBar.debuggingForeground" = colors.bg.hex;
      "statusBar.noFolderBackground" = colors.bg-alt.hex;

      # Title bar
      "titleBar.activeBackground" = colors.bg.hex;
      "titleBar.activeForeground" = colors.fg.hex;
      "titleBar.inactiveBackground" = colors.bg.hex;
      "titleBar.inactiveForeground" = colors.fg-dim.hex;
      "titleBar.border" = colors.selection.hex;

      # Tabs
      "tab.activeBackground" = colors.bg-alt.hex;
      "tab.activeForeground" = colors.fg.hex;
      "tab.inactiveBackground" = colors.bg.hex;
      "tab.inactiveForeground" = colors.fg-alt.hex;
      "tab.border" = colors.selection.hex;
      "tab.activeBorder" = colors.cursor.hex;

      # Panel
      "panel.background" = colors.bg.hex;
      "panel.border" = colors.selection.hex;
      "panelTitle.activeBorder" = colors.cursor.hex;
      "panelTitle.activeForeground" = colors.fg.hex;
      "panelTitle.inactiveForeground" = colors.fg-alt.hex;

      # Terminal
      "terminal.background" = colors.bg.hex;
      "terminal.foreground" = colors.fg.hex;
      "terminal.ansiBlack" = semantic.terminal "ansi-black" themeMode;
      "terminal.ansiRed" = colors.error.hex;
      "terminal.ansiGreen" = colors.added.hex;
      "terminal.ansiYellow" = colors.warning.hex;
      "terminal.ansiBlue" = colors.cursor.hex;
      "terminal.ansiMagenta" = semantic.terminal "ansi-magenta" themeMode;
      "terminal.ansiCyan" = colors.cursor.hex;
      "terminal.ansiWhite" = semantic.terminal "ansi-white" themeMode;
      "terminal.ansiBrightBlack" = semantic.terminal "ansi-bright-black" themeMode;
      "terminal.ansiBrightRed" = colors.error.hex;
      "terminal.ansiBrightGreen" = colors.added.hex;
      "terminal.ansiBrightYellow" = colors.warning.hex;
      "terminal.ansiBrightBlue" = colors.cursor.hex;
      "terminal.ansiBrightMagenta" = semantic.terminal "ansi-bright-magenta" themeMode;
      "terminal.ansiBrightCyan" = colors.cursor.hex;
      "terminal.ansiBrightWhite" = semantic.terminal "ansi-bright-white" themeMode;

      # Lists
      "list.activeSelectionBackground" = colors.border.hex;
      "list.activeSelectionForeground" = colors.fg.hex;
      "list.inactiveSelectionBackground" = colors.selection.hex;
      "list.inactiveSelectionForeground" = colors.fg.hex;
      "list.hoverBackground" = colors.bg-alt.hex;
      "list.hoverForeground" = colors.fg.hex;
      "list.focusBackground" = colors.border.hex;
      "list.focusForeground" = colors.fg.hex;

      # Buttons
      "button.background" = colors.cursor.hex;
      "button.foreground" = colors.bg.hex;
      "button.hoverBackground" = "${colors.cursor.hex}e0";

      # Input
      "input.background" = colors.bg-alt.hex;
      "input.foreground" = colors.fg.hex;
      "input.border" = colors.selection.hex;
      "input.placeholderForeground" = colors.fg-dim.hex;

      # Notifications
      "notificationCenter.border" = colors.selection.hex;
      "notifications.background" = colors.bg-alt.hex;
      "notifications.foreground" = colors.fg.hex;
      "notifications.border" = colors.selection.hex;
    };

    "editor.tokenColorCustomizations" = {
      textMateRules = [
        {
          scope = [ "comment" ];
          settings = {
            foreground = colors.fg-dim.hex;
            fontStyle = "italic";
          };
        }
        {
          scope = [ "string" ];
          settings = {
            foreground = semantic.multiplayer "player-2" themeMode;
          };
        }
        {
          scope = [ "constant.numeric" ];
          settings = {
            foreground = semantic.multiplayer "player-6" themeMode;
          };
        }
        {
          scope = [ "constant.language" ];
          settings = {
            foreground = colors.warning.hex;
          };
        }
        {
          scope = [ "keyword" ];
          settings = {
            foreground = colors.keyword.hex;
          };
        }
        {
          scope = [ "storage" ];
          settings = {
            foreground = colors.keyword.hex;
          };
        }
        {
          scope = [ "entity.name.function" ];
          settings = {
            foreground = colors.cursor.hex;
          };
        }
        {
          scope = [
            "entity.name.type"
            "entity.name.class"
          ];
          settings = {
            foreground = semantic.multiplayer "player-6" themeMode;
          };
        }
        {
          scope = [ "variable" ];
          settings = {
            foreground = colors.fg.hex;
          };
        }
        {
          scope = [
            "support.type"
            "support.class"
          ];
          settings = {
            foreground = semantic.multiplayer "player-6" themeMode;
          };
        }
        {
          scope = [ "support.function" ];
          settings = {
            foreground = colors.cursor.hex;
          };
        }
        {
          scope = [ "punctuation" ];
          settings = {
            foreground = colors.fg-alt.hex;
          };
        }
        {
          scope = [ "markup.heading" ];
          settings = {
            foreground = colors.error.hex;
            fontStyle = "bold";
          };
        }
        {
          scope = [ "markup.italic" ];
          settings = {
            fontStyle = "italic";
          };
        }
        {
          scope = [ "markup.bold" ];
          settings = {
            fontStyle = "bold";
          };
        }
        {
          scope = [ "markup.underline" ];
          settings = {
            fontStyle = "underline";
          };
        }
        {
          scope = [ "markup.inline.raw" ];
          settings = {
            foreground = semantic.multiplayer "player-2" themeMode;
          };
        }
        {
          scope = [ "meta.link" ];
          settings = {
            foreground = colors.cursor.hex;
          };
        }
      ];
    };
  };
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.vscode.profiles.default.userSettings = vscodeSettings;
  };
}
