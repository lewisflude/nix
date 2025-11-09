{
  config,
  lib,
  themeContext ? null,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeLib = themeContext.lib;

  # Generate both light and dark palettes
  darkPalette = themeLib.generateTheme "dark" { };
  lightPalette = themeLib.generateTheme "light" { };

  # Generate a single theme variant with complete Zed theme schema
  generateThemeVariant =
    palette: variantName:
    let
      inherit (palette) colors;
    in
    {
      name = "Signal ${variantName}";
      author = "Signal Theme";
      semanticClass = "dark";
      color = {
        # Editor colors
        "editor.background" = colors."surface-base".hex;
        "editor.foreground" = colors."text-primary".hex;
        "editor.lineHighlightBackground" = colors."surface-subtle".hex;
        "editor.selectionBackground" = colors."accent-primary".hex + "40";
        "editor.selectionHighlightBackground" = colors."accent-primary".hex + "20";
        "editor.inactiveSelectionBackground" = colors."surface-emphasis".hex + "60";
        "editor.findMatchBackground" = colors."accent-warning".hex + "60";
        "editor.findMatchHighlightBackground" = colors."accent-warning".hex + "30";
        "editor.wordHighlightBackground" = colors."accent-focus".hex + "20";
        "editor.wordHighlightStrongBackground" = colors."accent-focus".hex + "40";
        "editorLineNumber.foreground" = colors."text-tertiary".hex;
        "editorLineNumber.activeForeground" = colors."text-secondary".hex;
        "editorCursor.foreground" = colors."accent-primary".hex;
        "editorWhitespace.foreground" = colors."divider-primary".hex;
        "editorIndentGuide.background" = colors."divider-primary".hex;
        "editorIndentGuide.activeBackground" = colors."divider-secondary".hex;
        "editorRuler.foreground" = colors."divider-secondary".hex;
        "editorBracketMatch.background" = colors."accent-focus".hex + "30";
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
        "diffEditor.insertedTextBackground" = colors."ansi-green".hex + "20";
        "diffEditor.removedTextBackground" = colors."ansi-red".hex + "20";

        # Input controls
        "input.background" = colors."surface-subtle".hex;
        "input.border" = colors."divider-secondary".hex;
        "input.foreground" = colors."text-primary".hex;
        "inputOption.activeBorder" = colors."accent-primary".hex;

        # Buttons
        "button.background" = colors."accent-primary".hex;
        "button.foreground" = colors."surface-base".hex;
        "button.hoverBackground" = colors."accent-primary".hex;

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

      syntax = {
        # Keywords
        keyword = {
          color = colors."syntax-keyword".hex;
        };
        # Function definitions
        "function-definition" = {
          color = colors."syntax-function-def".hex;
        };
        # Function calls
        "function-call" = {
          color = colors."syntax-function-call".hex;
        };
        # Strings
        string = {
          color = colors."syntax-string".hex;
        };
        # Numbers and constants
        number = {
          color = colors."syntax-number".hex;
        };
        # Types
        type = {
          color = colors."syntax-type".hex;
        };
        # Variables (use default text color)
        variable = {
          color = colors."text-primary".hex;
        };
        # Comments
        comment = {
          color = colors."syntax-comment".hex;
          fontStyle = "italic";
        };
        # Invalid/Error
        invalid = {
          color = colors."syntax-error".hex;
          fontStyle = "bold underline";
        };
        # TODO/FIXME
        "code-tag" = {
          color = colors."syntax-special".hex;
          fontStyle = "bold";
        };
        # Punctuation
        punctuation = {
          color = colors."text-secondary".hex;
        };
        # Operators
        operator = {
          color = colors."text-primary".hex;
        };
      };
    };

  # Generate the complete theme family with both light and dark variants
  generateZedTheme = {
    themes = [
      (generateThemeVariant darkPalette "Dark")
      (generateThemeVariant lightPalette "Light")
    ];
  };
in
{
  config = mkIf (cfg.enable && cfg.applications.zed.enable && themeLib != null) {
    # Generate and install the theme file with both light and dark variants
    home.file.".config/zed/themes/signal.json" = {
      text = builtins.toJSON generateZedTheme;
      force = false; # Don't overwrite if user has customized
    };
  };
}
