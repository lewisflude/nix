{
  config,
  lib,
  themeContext ? null,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  inherit (themeContext) theme palette;
  themeLib = themeContext.lib;

  # Get categorical colors for the current mode
  categorical = themeLib.getPalette cfg.mode palette.categorical;

  # Get accent colors with variants
  accent = themeLib.getPalette cfg.mode palette.accent;

  # Generate Helix theme
  generateHelixTheme =
    themeObj:
    let
      inherit (themeObj) colors;
    in
    {
      # Syntax highlighting
      # -------------------
      "attribute" = categorical.GA06.hex; # Orange (warm, distinct)
      "type" = categorical.GA06.hex; # Orange
      "type.enum.variant" = categorical.GA02.hex; # Green (teal-like)

      "constructor" = accent.Lc75-h240.hex; # Blue (sapphire-like)

      "constant" = categorical.GA06.hex; # Orange (peach-like)
      "constant.character" = categorical.GA02.hex; # Green (teal-like)
      "constant.character.escape" = categorical.GA08.hex; # Pink

      "string" = categorical.GA02.hex; # Green
      "string.regexp" = categorical.GA08.hex; # Pink
      "string.special" = accent.Lc75-h240.hex; # Blue
      "string.special.symbol" = accent.Lc75-h040.hex; # Red

      "comment" = {
        fg = colors."text-tertiary".hex;
        modifiers = [ "italic" ];
      };

      "variable" = colors."text-primary".hex;
      "variable.parameter" = {
        fg = accent.Lc60-h040.hex; # Red (maroon-like)
        modifiers = [ "italic" ];
      };
      "variable.builtin" = accent.Lc75-h040.hex; # Red
      "variable.other.member" = accent.Lc75-h240.hex; # Blue

      "label" = accent.Lc75-h240.hex; # Blue (sapphire-like, used for lifetimes)

      "punctuation" = colors."text-tertiary".hex;
      "punctuation.special" = accent.Lc75-h190.hex; # Cyan (sky-like)

      "keyword" = accent.Lc75-h290.hex; # Purple (mauve-like)
      "keyword.control.conditional" = {
        fg = accent.Lc75-h290.hex; # Purple
        modifiers = [ "italic" ];
      };

      "operator" = accent.Lc75-h190.hex; # Cyan (sky-like)

      "function" = accent.Lc75-h240.hex; # Blue
      "function.macro" = categorical.GA08.hex; # Pink (rosewater-like)

      "tag" = accent.Lc75-h240.hex; # Blue

      "namespace" = {
        fg = categorical.GA06.hex; # Orange (yellow-like)
        modifiers = [ "italic" ];
      };

      "special" = accent.Lc75-h240.hex; # Blue (fuzzy highlight)

      # Markup
      "markup.heading.1" = accent.Lc75-h040.hex; # Red
      "markup.heading.2" = categorical.GA06.hex; # Orange (peach-like)
      "markup.heading.3" = categorical.GA06.hex; # Orange (yellow-like)
      "markup.heading.4" = categorical.GA02.hex; # Green
      "markup.heading.5" = accent.Lc75-h240.hex; # Blue (sapphire-like)
      "markup.heading.6" = accent.Lc75-h290.hex; # Purple (lavender-like)
      "markup.list" = categorical.GA02.hex; # Green (teal-like)
      "markup.list.unchecked" = colors."text-tertiary".hex;
      "markup.list.checked" = categorical.GA02.hex; # Green
      "markup.bold" = {
        fg = accent.Lc75-h040.hex; # Red
        modifiers = [ "bold" ];
      };
      "markup.italic" = {
        fg = accent.Lc75-h040.hex; # Red
        modifiers = [ "italic" ];
      };
      "markup.link.url" = {
        fg = accent.Lc75-h240.hex; # Blue
        modifiers = [
          "italic"
          "underlined"
        ];
      };
      "markup.link.text" = accent.Lc75-h290.hex; # Purple (lavender-like)
      "markup.link.label" = accent.Lc75-h240.hex; # Blue (sapphire-like)
      "markup.raw" = categorical.GA02.hex; # Green
      "markup.quote" = categorical.GA08.hex; # Pink

      # Diff
      "diff.plus" = categorical.GA02.hex; # Green
      "diff.minus" = accent.Lc75-h040.hex; # Red
      "diff.delta" = accent.Lc75-h240.hex; # Blue

      # User Interface
      # --------------
      "ui.background" = {
        fg = colors."text-primary".hex;
        bg = colors."surface-base".hex;
      };

      "ui.linenr" = {
        fg = colors."divider-secondary".hex;
      };
      "ui.linenr.selected" = {
        fg = accent.Lc75-h290.hex; # Purple (lavender-like)
      };

      "ui.statusline" = {
        fg = colors."text-secondary".hex;
        bg = colors."surface-emphasis".hex;
      };
      "ui.statusline.inactive" = {
        fg = colors."divider-secondary".hex;
        bg = colors."surface-emphasis".hex;
      };
      "ui.statusline.normal" = {
        fg = colors."surface-base".hex;
        bg = categorical.GA08.hex; # Pink (rosewater-like)
        modifiers = [ "bold" ];
      };
      "ui.statusline.insert" = {
        fg = colors."surface-base".hex;
        bg = categorical.GA02.hex; # Green
        modifiers = [ "bold" ];
      };
      "ui.statusline.select" = {
        fg = colors."surface-base".hex;
        bg = accent.Lc75-h290.hex; # Purple (lavender-like)
        modifiers = [ "bold" ];
      };

      "ui.popup" = {
        fg = colors."text-primary".hex;
        bg = colors."surface-subtle".hex;
      };
      "ui.window" = {
        fg = colors."surface-base".hex;
      };
      "ui.help" = {
        fg = colors."text-tertiary".hex;
        bg = colors."surface-subtle".hex;
      };

      "ui.bufferline" = {
        fg = colors."text-secondary".hex;
        bg = colors."surface-emphasis".hex;
      };
      "ui.bufferline.active" = {
        fg = accent.Lc75-h290.hex; # Purple (mauve-like)
        bg = colors."surface-base".hex;
        underline = {
          color = accent.Lc75-h290.hex;
          style = "line";
        };
      };
      "ui.bufferline.background" = {
        bg = colors."surface-base".hex;
      };

      "ui.text" = colors."text-primary".hex;
      "ui.text.focus" = {
        fg = colors."text-primary".hex;
        bg = colors."surface-subtle".hex;
        modifiers = [ "bold" ];
      };
      "ui.text.inactive" = colors."text-tertiary".hex;
      "ui.text.directory" = accent.Lc75-h240.hex; # Blue

      "ui.virtual" = colors."text-tertiary".hex;
      "ui.virtual.ruler" = {
        bg = colors."surface-subtle".hex;
      };
      "ui.virtual.indent-guide" = colors."surface-subtle".hex;
      "ui.virtual.inlay-hint" = {
        fg = colors."divider-secondary".hex;
        bg = colors."surface-emphasis".hex;
      };
      "ui.virtual.jump-label" = {
        fg = categorical.GA08.hex; # Pink (rosewater-like)
        modifiers = [ "bold" ];
      };

      "ui.selection" = {
        bg = colors."divider-secondary".hex;
      };

      "ui.cursor" = {
        fg = colors."surface-base".hex;
        bg = colors."text-tertiary".hex; # Secondary cursor color
      };
      "ui.cursor.primary" = {
        fg = colors."surface-base".hex;
        bg = categorical.GA08.hex; # Pink (rosewater-like)
      };
      "ui.cursor.match" = {
        fg = categorical.GA06.hex; # Orange (peach-like)
        modifiers = [ "bold" ];
      };

      "ui.cursor.primary.normal" = {
        fg = colors."surface-base".hex;
        bg = categorical.GA08.hex; # Pink (rosewater-like)
      };
      "ui.cursor.primary.insert" = {
        fg = colors."surface-base".hex;
        bg = categorical.GA02.hex; # Green
      };
      "ui.cursor.primary.select" = {
        fg = colors."surface-base".hex;
        bg = accent.Lc75-h290.hex; # Purple (lavender-like)
      };

      "ui.cursor.normal" = {
        fg = colors."surface-base".hex;
        bg = colors."text-tertiary".hex; # Secondary cursor normal
      };
      "ui.cursor.insert" = {
        fg = colors."surface-base".hex;
        bg = categorical.GA02.hex; # Green (secondary cursor insert)
      };
      "ui.cursor.select" = {
        fg = colors."surface-base".hex;
        bg = accent.Lc75-h290.hex; # Purple (secondary cursor select)
      };

      "ui.cursorline.primary" = {
        bg = colors."surface-subtle".hex; # Cursorline color
      };

      "ui.highlight" = {
        bg = colors."divider-secondary".hex;
        modifiers = [ "bold" ];
      };

      "ui.menu" = {
        fg = colors."text-tertiary".hex;
        bg = colors."surface-subtle".hex;
      };
      "ui.menu.selected" = {
        fg = colors."text-primary".hex;
        bg = colors."divider-secondary".hex;
        modifiers = [ "bold" ];
      };

      "diagnostic.error" = {
        underline = {
          color = accent.Lc75-h040.hex; # Red
          style = "curl";
        };
      };
      "diagnostic.warning" = {
        underline = {
          color = categorical.GA06.hex; # Orange (yellow-like)
          style = "curl";
        };
      };
      "diagnostic.info" = {
        underline = {
          color = accent.Lc75-h190.hex; # Cyan (sky-like)
          style = "curl";
        };
      };
      "diagnostic.hint" = {
        underline = {
          color = categorical.GA02.hex; # Green (teal-like)
          style = "curl";
        };
      };
      "diagnostic.unnecessary" = {
        modifiers = [ "dim" ];
      };

      error = accent.Lc75-h040.hex; # Red
      warning = categorical.GA06.hex; # Orange (yellow-like)
      info = accent.Lc75-h190.hex; # Cyan (sky-like)
      hint = categorical.GA02.hex; # Green (teal-like)

      rainbow = [
        accent.Lc75-h040.hex # Red
        categorical.GA06.hex # Orange (peach-like)
        categorical.GA06.hex # Orange (yellow-like)
        categorical.GA02.hex # Green
        accent.Lc75-h240.hex # Blue (sapphire-like)
        accent.Lc75-h290.hex # Purple (lavender-like)
      ];
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
