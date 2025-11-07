{
  config,
  lib,
  pkgs,
  scientificPalette ? null,
  ...
}:
let
  inherit (lib) mkIf optionalString;
  cfg = config.theming.scientific;
  theme = scientificPalette;

  # Generate VS Code theme JSON
  generateVSCodeTheme =
    palette: mode:
    let
      colors = palette.semantic;
    in
    {
      name = "Scientific ${lib.strings.toUpper (builtins.substring 0 1 mode)}${
        builtins.substring 1 (builtins.stringLength mode) mode
      }";
      type = if mode == "light" then "light" else "dark";
      semanticHighlighting = true;
      colors = {
        # Editor colors
        "editor.background" = colors."surface-base".hex;
        "editor.foreground" = colors."text-primary".hex;
        "editor.lineHighlightBackground" = colors."surface-subtle".hex;
        "editor.selectionBackground" = "${colors."accent-primary".hex}40";
        "editor.selectionHighlightBackground" = "${colors."accent-primary".hex}20";
        "editor.inactiveSelectionBackground" = "${colors."surface-emphasis".hex}60";
        "editor.findMatchBackground" = "${colors."accent-warning".hex}60";
        "editor.findMatchHighlightBackground" = "${colors."accent-warning".hex}30";
        "editor.wordHighlightBackground" = "${colors."accent-focus".hex}20";
        "editor.wordHighlightStrongBackground" = "${colors."accent-focus".hex}40";
        "editorLineNumber.foreground" = colors."text-tertiary".hex;
        "editorLineNumber.activeForeground" = colors."text-secondary".hex;
        "editorCursor.foreground" = colors."accent-primary".hex;
        "editorWhitespace.foreground" = colors."divider-primary".hex;
        "editorIndentGuide.background" = colors."divider-primary".hex;
        "editorIndentGuide.activeBackground" = colors."divider-secondary".hex;
        "editorRuler.foreground" = colors."divider-secondary".hex;
        "editorBracketMatch.background" = "${colors."accent-focus".hex}30";
        "editorBracketMatch.border" = colors."accent-focus".hex;

        # UI colors
        "activityBar.background" = colors."surface-base".hex;
        "activityBar.foreground" = colors."text-primary".hex;
        "activityBar.border" = colors."divider-primary".hex;
        "activityBar.activeBorder" = colors."accent-primary".hex;
        "sideBar.background" = colors."surface-base".hex;
        "sideBar.foreground" = colors."text-primary".hex;
        "sideBar.border" = colors."divider-primary".hex;
        "sideBarSectionHeader.background" = colors."surface-subtle".hex;
        "sideBarSectionHeader.foreground" = colors."text-primary".hex;
        "statusBar.background" = colors."surface-emphasis".hex;
        "statusBar.foreground" = colors."text-primary".hex;
        "statusBar.border" = colors."divider-primary".hex;
        "statusBar.noFolderBackground" = colors."surface-emphasis".hex;
        "titleBar.activeBackground" = colors."surface-base".hex;
        "titleBar.activeForeground" = colors."text-primary".hex;
        "titleBar.border" = colors."divider-primary".hex;

        # List and tree views
        "list.activeSelectionBackground" = colors."accent-primary".hex;
        "list.activeSelectionForeground" = colors."surface-base".hex;
        "list.inactiveSelectionBackground" = colors."surface-emphasis".hex;
        "list.hoverBackground" = colors."surface-subtle".hex;
        "list.focusBackground" = colors."surface-emphasis".hex;

        # Panels
        "panel.background" = colors."surface-base".hex;
        "panel.border" = colors."divider-primary".hex;
        "panelTitle.activeBorder" = colors."accent-primary".hex;
        "panelTitle.activeForeground" = colors."text-primary".hex;
        "panelTitle.inactiveForeground" = colors."text-secondary".hex;

        # Terminal colors (ANSI)
        "terminal.background" = colors."surface-base".hex;
        "terminal.foreground" = colors."text-primary".hex;
        "terminal.ansiBlack" = colors."ansi-black".hex;
        "terminal.ansiRed" = colors."ansi-red".hex;
        "terminal.ansiGreen" = colors."ansi-green".hex;
        "terminal.ansiYellow" = colors."ansi-yellow".hex;
        "terminal.ansiBlue" = colors."ansi-blue".hex;
        "terminal.ansiMagenta" = colors."ansi-magenta".hex;
        "terminal.ansiCyan" = colors."ansi-cyan".hex;
        "terminal.ansiWhite" = colors."ansi-white".hex;
        "terminal.ansiBrightBlack" = colors."ansi-bright-black".hex;
        "terminal.ansiBrightRed" = colors."ansi-red".hex;
        "terminal.ansiBrightGreen" = colors."ansi-green".hex;
        "terminal.ansiBrightYellow" = colors."ansi-yellow".hex;
        "terminal.ansiBrightBlue" = colors."ansi-blue".hex;
        "terminal.ansiBrightMagenta" = colors."ansi-magenta".hex;
        "terminal.ansiBrightCyan" = colors."ansi-cyan".hex;
        "terminal.ansiBrightWhite" = colors."ansi-bright-white".hex;

        # Git colors
        "gitDecoration.modifiedResourceForeground" = colors."accent-warning".hex;
        "gitDecoration.deletedResourceForeground" = colors."accent-danger".hex;
        "gitDecoration.untrackedResourceForeground" = colors."accent-info".hex;
        "gitDecoration.conflictingResourceForeground" = colors."accent-danger".hex;
        "gitDecoration.ignoredResourceForeground" = colors."text-tertiary".hex;

        # Diff colors
        "diffEditor.insertedTextBackground" = "${colors."ansi-green".hex}20";
        "diffEditor.removedTextBackground" = "${colors."ansi-red".hex}20";

        # Input controls
        "input.background" = colors."surface-subtle".hex;
        "input.border" = colors."divider-secondary".hex;
        "input.foreground" = colors."text-primary".hex;
        "inputOption.activeBorder" = colors."accent-primary".hex;

        # Buttons
        "button.background" = colors."accent-primary".hex;
        "button.foreground" = colors."surface-base".hex;
        "button.hoverBackground" = palette.accent."Lc60-h130".hex;

        # Dropdown
        "dropdown.background" = colors."surface-subtle".hex;
        "dropdown.border" = colors."divider-secondary".hex;
        "dropdown.foreground" = colors."text-primary".hex;

        # Notifications
        "notificationCenter.border" = colors."divider-secondary".hex;
        "notifications.background" = colors."surface-subtle".hex;
        "notifications.border" = colors."divider-secondary".hex;
        "notifications.foreground" = colors."text-primary".hex;

        # Badge
        "badge.background" = colors."accent-primary".hex;
        "badge.foreground" = colors."surface-base".hex;

        # Tab colors
        "tab.activeBackground" = colors."surface-base".hex;
        "tab.activeForeground" = colors."text-primary".hex;
        "tab.inactiveBackground" = colors."surface-subtle".hex;
        "tab.inactiveForeground" = colors."text-secondary".hex;
        "tab.border" = colors."divider-primary".hex;
        "tab.activeBorder" = colors."accent-primary".hex;
      };

      tokenColors = [
        # Keywords
        {
          scope = [
            "keyword"
            "storage.type"
            "storage.modifier"
            "keyword.control"
          ];
          settings.foreground = colors."syntax-keyword".hex;
        }
        # Function definitions
        {
          scope = [
            "entity.name.function"
            "meta.function-call.generic"
            "support.function"
          ];
          settings.foreground = colors."syntax-function-def".hex;
        }
        # Function calls
        {
          scope = [
            "meta.function-call"
            "entity.name.function-call"
          ];
          settings.foreground = colors."syntax-function-call".hex;
        }
        # Strings
        {
          scope = [
            "string"
            "string.quoted"
          ];
          settings.foreground = colors."syntax-string".hex;
        }
        # Numbers and constants
        {
          scope = [
            "constant.numeric"
            "constant.language"
          ];
          settings.foreground = colors."syntax-number".hex;
        }
        # Types
        {
          scope = [
            "entity.name.type"
            "entity.name.class"
            "support.type"
            "support.class"
            "storage.type.primitive"
          ];
          settings.foreground = colors."syntax-type".hex;
        }
        # Variables (use default text color)
        {
          scope = [
            "variable"
            "variable.other"
          ];
          settings.foreground = colors."text-primary".hex;
        }
        # Comments
        {
          scope = [
            "comment"
            "punctuation.definition.comment"
          ];
          settings = {
            foreground = colors."syntax-comment".hex;
            fontStyle = "italic";
          };
        }
        # Invalid/Error
        {
          scope = [
            "invalid"
            "invalid.illegal"
          ];
          settings = {
            foreground = colors."syntax-error".hex;
            fontStyle = "bold underline";
          };
        }
        # TODO/FIXME
        {
          scope = [ "keyword.codetag" ];
          settings = {
            foreground = colors."syntax-special".hex;
            fontStyle = "bold";
          };
        }
        # Punctuation
        {
          scope = [ "punctuation" ];
          settings.foreground = colors."text-secondary".hex;
        }
        # Operators
        {
          scope = [
            "keyword.operator"
            "punctuation.separator"
          ];
          settings.foreground = colors."text-primary".hex;
        }
      ];
    };
in
{
  config = mkIf (cfg.enable && cfg.applications.cursor.enable && theme != null) {
    # Generate and install the theme file
    xdg.configFile."Cursor/User/themes/scientific-${cfg.mode}.json" = {
      text = builtins.toJSON (generateVSCodeTheme theme cfg.mode);
    };

    # Also install for VS Code if used
    xdg.configFile."Code/User/themes/scientific-${cfg.mode}.json" = {
      text = builtins.toJSON (generateVSCodeTheme theme cfg.mode);
    };

    # Update user settings to use the theme
    programs.vscode = {
      profiles.default.userSettings = {
        "workbench.colorTheme" = "Scientific ${lib.strings.toUpper (builtins.substring 0 1 cfg.mode)}${
          builtins.substring 1 (builtins.stringLength cfg.mode) cfg.mode
        }";
      };
    };
  };
}
