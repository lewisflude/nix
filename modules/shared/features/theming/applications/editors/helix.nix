{
  config,
  lib,
  themeContext ? null,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  theme = themeContext.theme;

  # Generate Helix theme
  generateHelixTheme =
    themeObj:
    let
      colors = themeObj.colors;
    in
    {
      # UI elements
      "ui.background" = "${colors."surface-base".hex}";
      "ui.text" = "${colors."text-primary".hex}";
      "ui.text.focus" = "${colors."text-primary".hex}";
      "ui.text.info" = "${colors."text-secondary".hex}";
      "ui.text.inactive" = "${colors."text-tertiary".hex}";

      # Cursor
      "ui.cursor" = {
        bg = "${colors."accent-primary".hex}";
        fg = "${colors."surface-base".hex}";
      };
      "ui.cursor.primary" = {
        bg = "${colors."accent-primary".hex}";
        fg = "${colors."surface-base".hex}";
      };
      "ui.cursor.match" = {
        bg = "${colors."accent-focus".hex}";
        fg = "${colors."surface-base".hex}";
      };

      # Line numbers
      "ui.linenr" = "${colors."text-tertiary".hex}";
      "ui.linenr.selected" = "${colors."text-secondary".hex}";

      # Status line
      "ui.statusline" = {
        bg = "${colors."surface-emphasis".hex}";
        fg = "${colors."text-primary".hex}";
      };
      "ui.statusline.inactive" = {
        bg = "${colors."surface-subtle".hex}";
        fg = "${colors."text-secondary".hex}";
      };
      "ui.statusline.normal" = {
        bg = "${colors."accent-primary".hex}";
        fg = "${colors."surface-base".hex}";
      };
      "ui.statusline.insert" = {
        bg = "${colors."accent-focus".hex}";
        fg = "${colors."surface-base".hex}";
      };
      "ui.statusline.select" = {
        bg = "${colors."accent-warning".hex}";
        fg = "${colors."surface-base".hex}";
      };

      # Current line highlight
      "ui.cursorline" = {
        bg = "${colors."surface-subtle".hex}";
      };

      # Selection
      "ui.selection" = {
        bg = "${colors."accent-primary".hex}40";
      };
      "ui.selection.primary" = {
        bg = "${colors."accent-primary".hex}40";
      };

      # Virtual text (hints, diagnostics)
      "ui.virtual" = "${colors."text-tertiary".hex}";
      "ui.virtual.ruler" = {
        bg = "${colors."divider-primary".hex}";
      };
      "ui.virtual.whitespace" = "${colors."divider-primary".hex}";
      "ui.virtual.indent-guide" = "${colors."divider-primary".hex}";

      # Popups and menus
      "ui.popup" = {
        bg = "${colors."surface-subtle".hex}";
        fg = "${colors."text-primary".hex}";
      };
      "ui.popup.info" = {
        bg = "${colors."surface-emphasis".hex}";
        fg = "${colors."text-primary".hex}";
      };
      "ui.menu" = {
        bg = "${colors."surface-subtle".hex}";
        fg = "${colors."text-primary".hex}";
      };
      "ui.menu.selected" = {
        bg = "${colors."accent-primary".hex}";
        fg = "${colors."surface-base".hex}";
      };
      "ui.menu.scroll" = {
        bg = "${colors."divider-secondary".hex}";
        fg = "${colors."text-primary".hex}";
      };

      # Window
      "ui.window" = {
        bg = "${colors."surface-base".hex}";
      };

      # Help
      "ui.help" = {
        bg = "${colors."surface-emphasis".hex}";
        fg = "${colors."text-primary".hex}";
      };

      # Syntax highlighting
      "comment" = {
        fg = "${colors."syntax-comment".hex}";
        modifiers = [ "italic" ];
      };

      "keyword" = "${colors."syntax-keyword".hex}";
      "keyword.control" = "${colors."syntax-keyword".hex}";
      "keyword.directive" = "${colors."syntax-keyword".hex}";
      "keyword.function" = "${colors."syntax-keyword".hex}";
      "keyword.operator" = "${colors."text-primary".hex}";
      "keyword.storage" = "${colors."syntax-keyword".hex}";

      "function" = "${colors."syntax-function-def".hex}";
      "function.builtin" = "${colors."syntax-function-def".hex}";
      "function.call" = "${colors."syntax-function-call".hex}";
      "function.macro" = "${colors."syntax-special".hex}";
      "function.method" = "${colors."syntax-function-def".hex}";

      "string" = "${colors."syntax-string".hex}";
      "string.special" = "${colors."syntax-special".hex}";

      "number" = "${colors."syntax-number".hex}";
      "constant" = "${colors."syntax-constant".hex}";
      "constant.builtin" = "${colors."syntax-constant".hex}";
      "constant.character" = "${colors."syntax-string".hex}";
      "constant.numeric" = "${colors."syntax-number".hex}";

      "type" = "${colors."syntax-type".hex}";
      "type.builtin" = "${colors."syntax-type".hex}";

      "variable" = "${colors."text-primary".hex}";
      "variable.builtin" = "${colors."syntax-keyword".hex}";
      "variable.parameter" = "${colors."text-primary".hex}";

      "attribute" = "${colors."syntax-type".hex}";
      "constructor" = "${colors."syntax-type".hex}";
      "label" = "${colors."syntax-keyword".hex}";
      "namespace" = "${colors."syntax-type".hex}";
      "operator" = "${colors."text-primary".hex}";
      "punctuation" = "${colors."text-secondary".hex}";
      "special" = "${colors."syntax-special".hex}";
      "tag" = "${colors."syntax-keyword".hex}";

      # Markup (Markdown, etc.)
      "markup.heading" = {
        fg = "${colors."syntax-keyword".hex}";
        modifiers = [ "bold" ];
      };
      "markup.list" = "${colors."syntax-special".hex}";
      "markup.bold" = {
        modifiers = [ "bold" ];
      };
      "markup.italic" = {
        modifiers = [ "italic" ];
      };
      "markup.link.url" = {
        fg = "${colors."accent-info".hex}";
        modifiers = [ "underline" ];
      };
      "markup.link.text" = "${colors."syntax-string".hex}";
      "markup.quote" = "${colors."syntax-comment".hex}";
      "markup.raw" = "${colors."syntax-string".hex}";

      # Diagnostics
      "error" = "${colors."syntax-error".hex}";
      "warning" = "${colors."accent-warning".hex}";
      "info" = "${colors."accent-info".hex}";
      "hint" = "${colors."text-secondary".hex}";

      "diagnostic.error" = {
        underline = {
          style = "curl";
          color = "${colors."syntax-error".hex}";
        };
      };
      "diagnostic.warning" = {
        underline = {
          style = "curl";
          color = "${colors."accent-warning".hex}";
        };
      };
      "diagnostic.info" = {
        underline = {
          style = "curl";
          color = "${colors."accent-info".hex}";
        };
      };
      "diagnostic.hint" = {
        underline = {
          style = "curl";
          color = "${colors."text-secondary".hex}";
        };
      };

      # Diff
      "diff.plus" = "${colors."ansi-green".hex}";
      "diff.minus" = "${colors."ansi-red".hex}";
      "diff.delta" = "${colors."ansi-yellow".hex}";
    };
in
{
  config = mkIf (cfg.enable && cfg.applications.helix.enable && theme != null) {
    programs.helix = {
      settings = {
        theme = "signal-${cfg.mode}";
      };

      themes."signal-${cfg.mode}" = generateHelixTheme theme;
    };
  };
}
