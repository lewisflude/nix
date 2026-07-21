# Custom Editor Example
#
# This example shows how to integrate a custom code editor with Signal theming.
# Editors are more complex than terminals, requiring syntax highlighting colors
# and editor-specific UI elements.
#
# To use this example:
# 1. Copy this file to your modules directory
# 2. Replace "myEditor" with your editor's name
# 3. Adjust the color mappings to match your editor's theme format
# 4. Add to your imports in configuration.nix or home.nix
#
# See also:
# - templates/editor-module-template.nix - Blank template to start from
# - modules/editors/helix.nix - Real-world example (simple)
# - modules/editors/neovim.nix - Real-world example (complex)
# - docs/QUICK_REFERENCE.md - All available semantic colors
{
  config,
  lib,
  pkgs,
  signalLib,
  semantic,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;

  # ============================================================================
  # Step 1: Resolve Theme Mode
  # ============================================================================
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # ============================================================================
  # Step 2: Define Colors Using Semantic Bridge
  # ============================================================================
  # Editors need more color categories than terminals

  # Core editor colors
  editor = {
    background = semantic.editor "background" themeMode;
    foreground = semantic.editor "foreground" themeMode;
    gutter-bg = semantic.editor "gutter-background" themeMode;
    active-line = semantic.editor "active-line-background" themeMode;
    line-number = semantic.editor "line-number" themeMode;
    active-line-number = semantic.editor "active-line-number" themeMode;
    indent-guide = semantic.editor "indent-guide" themeMode;
    indent-guide-active = semantic.editor "indent-guide-active" themeMode;
    invisible = semantic.editor "invisible" themeMode;
    bracket-match = semantic.editor "bracket-match-background" themeMode;
    find-match-bg = semantic.editor "find-match-background" themeMode;
    find-match-fg = semantic.editor "find-match-foreground" themeMode;
    scrollbar-thumb = semantic.editor "scrollbar-thumb" themeMode;
    scrollbar-track = semantic.editor "scrollbar-track" themeMode;
  };

  # UI elements (panels, tabs, borders)
  ui = {
    panel-bg = semantic.ui "panel-background" themeMode;
    panel-border = semantic.ui "panel-border" themeMode;
    hover = semantic.ui "element-hover" themeMode;
    active = semantic.ui "element-active" themeMode;
    selected = semantic.ui "element-selected" themeMode;
    disabled = semantic.ui "element-disabled" themeMode;
    statusbar-bg = semantic.ui "status-bar-background" themeMode;
    tab-active = semantic.ui "tab-active-background" themeMode;
    tab-inactive = semantic.ui "tab-inactive-background" themeMode;
  };

  # Text hierarchy
  text = {
    primary = semantic.text "primary" themeMode;
    secondary = semantic.text "secondary" themeMode;
    tertiary = semantic.text "tertiary" themeMode;
    disabled = semantic.text "disabled" themeMode;
    link = semantic.text "link" themeMode;
  };

  # Syntax highlighting - the most important part for editors
  syntax = {
    keyword = semantic.syntax "keyword" themeMode; # if, for, return, class
    function = semantic.syntax "function" themeMode; # function names
    string = semantic.syntax "string" themeMode; # "hello", 'world'
    number = semantic.syntax "number" themeMode; # 42, 3.14
    comment = semantic.syntax "comment" themeMode; # // comments
    type = semantic.syntax "type" themeMode; # String, int
    variable = semantic.syntax "variable" themeMode; # variable names
    constant = semantic.syntax "constant" themeMode; # TRUE, NULL
    operator = semantic.syntax "operator" themeMode; # +, -, *, /
    tag = semantic.syntax "tag" themeMode; # HTML tags
    attribute = semantic.syntax "attribute" themeMode; # HTML attributes
    preprocessing = semantic.syntax "preprocessing" themeMode; # #include
    punctuation = semantic.syntax "punctuation" themeMode; # (), [], {}
    escape = semantic.syntax "escape" themeMode; # \n, \t
  };

  # Markup (Markdown, etc.)
  markup = {
    heading = semantic.markup "heading" themeMode;
    bold = semantic.markup "bold" themeMode;
    italic = semantic.markup "italic" themeMode;
    link = semantic.markup "link" themeMode;
    code = semantic.markup "code" themeMode;
    code-block = semantic.markup "code-block" themeMode;
    quote = semantic.markup "quote" themeMode;
  };

  # Version control (git gutter, diff view)
  vcs = {
    added = semantic.vcs "added" themeMode;
    modified = semantic.vcs "modified" themeMode;
    deleted = semantic.vcs "deleted" themeMode;
    conflict = semantic.vcs "conflict" themeMode;
    ignored = semantic.vcs "ignored" themeMode;
  };

  # Status indicators (errors, warnings, etc.)
  status = {
    error = semantic.status "error" themeMode;
    warning = semantic.status "warning" themeMode;
    success = semantic.status "success" themeMode;
    info = semantic.status "info" themeMode;
    hint = semantic.status "hint" themeMode;
  };

  # Terminal colors (for integrated terminal)
  terminal = {
    black = semantic.terminal "ansi-black" themeMode;
    red = semantic.terminal "ansi-red" themeMode;
    green = semantic.terminal "ansi-green" themeMode;
    yellow = semantic.terminal "ansi-yellow" themeMode;
    blue = semantic.terminal "ansi-blue" themeMode;
    magenta = semantic.terminal "ansi-magenta" themeMode;
    cyan = semantic.terminal "ansi-cyan" themeMode;
    white = semantic.terminal "ansi-white" themeMode;
  };

  # ============================================================================
  # Step 3: Determine if Editor Should Be Themed
  # ============================================================================
  shouldTheme = signalLib.shouldThemeApp "myEditor" [
    "editors"
    "myEditor"
  ] cfg config;
in
{
  # ============================================================================
  # Step 4: Apply Configuration
  # ============================================================================
  config = mkIf (cfg.enable && shouldTheme) {
    # Replace with your editor's Home Manager module
    # Common patterns:
    #   - programs.helix.settings.theme = "signal-${themeMode}";
    #   - programs.neovim.colorscheme = "signal";
    #   - programs.vscode.userSettings."workbench.colorTheme" = "Signal ${themeMode}";

    programs.myEditor = {
      enable = true;

      # Example 1: Theme file generation (most common for editors)
      # Many editors expect a theme file in a specific format
      theme = {
        name = "signal-${themeMode}";
        colors = {
          # Editor UI
          "editor.background" = editor.background.hex;
          "editor.foreground" = editor.foreground.hex;
          "editorLineNumber.foreground" = editor.line-number.hex;
          "editorLineNumber.activeForeground" = editor.active-line-number.hex;
          "editorCursor.foreground" = semantic.core "cursor" themeMode;
          "editor.selectionBackground" = semantic.core "selection-bg" themeMode;
          "editor.lineHighlightBackground" = editor.active-line.hex;
          "editorIndentGuide.background" = editor.indent-guide.hex;
          "editorIndentGuide.activeBackground" = editor.indent-guide-active.hex;
          "editorBracketMatch.background" = editor.bracket-match.hex;
          "editor.findMatchBackground" = editor.find-match-bg.hex;
          "editor.findMatchForeground" = editor.find-match-fg.hex;

          # Panels and sidebars
          "sideBar.background" = ui.panel-bg.hex;
          "sideBar.border" = ui.panel-border.hex;
          "statusBar.background" = ui.statusbar-bg.hex;
          "tab.activeBackground" = ui.tab-active.hex;
          "tab.inactiveBackground" = ui.tab-inactive.hex;

          # Git decorations
          "gitDecoration.addedResourceForeground" = vcs.added.hex;
          "gitDecoration.modifiedResourceForeground" = vcs.modified.hex;
          "gitDecoration.deletedResourceForeground" = vcs.deleted.hex;
          "gitDecoration.conflictingResourceForeground" = vcs.conflict.hex;
          "gitDecoration.ignoredResourceForeground" = vcs.ignored.hex;

          # Diagnostics
          "editorError.foreground" = status.error.hex;
          "editorWarning.foreground" = status.warning.hex;
          "editorInfo.foreground" = status.info.hex;
          "editorHint.foreground" = status.hint.hex;
        };

        # Syntax highlighting token colors
        tokenColors = [
          # Keywords (if, for, return, class, etc.)
          {
            scope = [
              "keyword"
              "keyword.control"
              "keyword.operator.new"
              "storage.type"
              "storage.modifier"
            ];
            settings.foreground = syntax.keyword.hex;
          }

          # Functions
          {
            scope = [
              "entity.name.function"
              "support.function"
              "meta.function-call"
            ];
            settings.foreground = syntax.function.hex;
          }

          # Strings
          {
            scope = [
              "string"
              "string.quoted"
              "string.template"
            ];
            settings.foreground = syntax.string.hex;
          }

          # Numbers
          {
            scope = [
              "constant.numeric"
              "constant.language.number"
            ];
            settings.foreground = syntax.number.hex;
          }

          # Comments
          {
            scope = [
              "comment"
              "punctuation.definition.comment"
            ];
            settings = {
              foreground = syntax.comment.hex;
              fontStyle = "italic";
            };
          }

          # Types
          {
            scope = [
              "entity.name.type"
              "entity.name.class"
              "support.type"
              "support.class"
            ];
            settings.foreground = syntax.type.hex;
          }

          # Variables
          {
            scope = [
              "variable"
              "variable.other"
            ];
            settings.foreground = syntax.variable.hex;
          }

          # Constants
          {
            scope = [
              "constant"
              "constant.language"
              "support.constant"
            ];
            settings.foreground = syntax.constant.hex;
          }

          # Operators
          {
            scope = [
              "keyword.operator"
              "punctuation.separator"
            ];
            settings.foreground = syntax.operator.hex;
          }

          # HTML/XML Tags
          {
            scope = [
              "entity.name.tag"
              "meta.tag"
            ];
            settings.foreground = syntax.tag.hex;
          }

          # HTML Attributes
          {
            scope = [
              "entity.other.attribute-name"
            ];
            settings.foreground = syntax.attribute.hex;
          }

          # Preprocessor directives
          {
            scope = [
              "meta.preprocessor"
              "keyword.control.directive"
            ];
            settings.foreground = syntax.preprocessing.hex;
          }

          # Punctuation
          {
            scope = [
              "punctuation"
              "meta.brace"
              "meta.bracket"
            ];
            settings.foreground = syntax.punctuation.hex;
          }

          # Escape sequences
          {
            scope = [
              "constant.character.escape"
            ];
            settings.foreground = syntax.escape.hex;
          }

          # Markdown headings
          {
            scope = [
              "markup.heading"
              "entity.name.section"
            ];
            settings = {
              foreground = markup.heading.hex;
              fontStyle = "bold";
            };
          }

          # Markdown bold
          {
            scope = [
              "markup.bold"
            ];
            settings = {
              foreground = markup.bold.hex;
              fontStyle = "bold";
            };
          }

          # Markdown italic
          {
            scope = [
              "markup.italic"
            ];
            settings = {
              foreground = markup.italic.hex;
              fontStyle = "italic";
            };
          }

          # Markdown links
          {
            scope = [
              "markup.underline.link"
              "string.other.link"
            ];
            settings.foreground = markup.link.hex;
          }

          # Markdown code
          {
            scope = [
              "markup.inline.raw"
              "markup.fenced_code"
            ];
            settings = {
              foreground = markup.code.hex;
              background = markup.code-block.hex;
            };
          }

          # Markdown quotes
          {
            scope = [
              "markup.quote"
            ];
            settings.foreground = markup.quote.hex;
          }
        ];
      };

      # Example 2: Integrated terminal colors (if supported)
      terminal = {
        colors = {
          black = terminal.black.hex;
          red = terminal.red.hex;
          green = terminal.green.hex;
          yellow = terminal.yellow.hex;
          blue = terminal.blue.hex;
          magenta = terminal.magenta.hex;
          cyan = terminal.cyan.hex;
          white = terminal.white.hex;
        };
      };
    };
  };
}

# ============================================================================
# Editor-Specific Tips
# ============================================================================
#
# Neovim/Vim:
# - Use highlight groups: Normal, Comment, Function, etc.
# - Map semantic colors to vim highlight groups
# - Test with :highlight command
#
# Helix:
# - Define theme in TOML format
# - Use semantic.* for all colors
# - Test with :theme signal-dark
#
# VS Code:
# - Generate .json theme file
# - Use workbench.colorCustomizations
# - Test with Ctrl+K Ctrl+T
#
# Emacs:
# - Use deftheme and custom-theme-set-faces
# - Map to standard faces: default, font-lock-*, etc.
# - Test with M-x load-theme
#
# ============================================================================
# Common Editor Color Mappings
# ============================================================================
#
# Editor Background → semantic.editor "background"
# Editor Text → semantic.editor "foreground"
# Line Numbers → semantic.editor "line-number"
# Current Line → semantic.editor "active-line-background"
# Gutter → semantic.editor "gutter-background"
# Selection → semantic.core "selection-bg"
# Cursor → semantic.core "cursor"
# Find Matches → semantic.editor "find-match-background"
#
# Keywords → semantic.syntax "keyword"
# Functions → semantic.syntax "function"
# Strings → semantic.syntax "string"
# Comments → semantic.syntax "comment"
# Types → semantic.syntax "type"
# Variables → semantic.syntax "variable"
#
# Errors → semantic.status "error"
# Warnings → semantic.status "warning"
# Info → semantic.status "info"
#
# Git Added → semantic.vcs "added"
# Git Modified → semantic.vcs "modified"
# Git Deleted → semantic.vcs "deleted"
#
# ============================================================================
# Testing Your Editor Theme
# ============================================================================
#
# 1. Build and activate:
#    nix build .#homeConfigurations.test-user.activationPackage
#    ./result/activate
#
# 2. Open your editor and test:
#    - Syntax highlighting (all token types)
#    - UI elements (panels, tabs, statusbar)
#    - Git decorations (if supported)
#    - Diagnostics (errors, warnings)
#    - Search/find matches
#    - Selection and cursor
#
# 3. Test both light and dark modes:
#    theming.signal.mode = "light";  # or "dark"
#
# 4. Validate no hardcoded colors:
#    nix flake check
#
# 5. Compare with other Signal themes:
#    - VS Code Signal theme
#    - Terminal Signal theme
#    - Ensure consistency
