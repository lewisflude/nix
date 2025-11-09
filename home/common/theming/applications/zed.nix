{
  config,
  lib,
  pkgs,
  scientificPalette ? null,
  scientificThemeLib ? null,
  ...
}:
let
  inherit (lib) mkIf mkForce;
  cfg = config.theming.scientific;

  # Generate both light and dark palettes
  darkPalette = if scientificThemeLib != null then scientificThemeLib.generateTheme "dark" else null;
  lightPalette =
    if scientificThemeLib != null then scientificThemeLib.generateTheme "light" else null;

  # Generate a single theme variant with complete Zed theme schema
  generateThemeVariant =
    palette: mode:
    let
      colors = palette.semantic;
    in
    {
      name = "Scientific ${lib.strings.toUpper (builtins.substring 0 1 mode)}${
        builtins.substring 1 (builtins.stringLength mode) mode
      }";
      appearance = if mode == "light" then "light" else "dark";
      style = {
        # Accent colors for various UI highlights
        accents = [
          "${colors."syntax-error".hex}"
          "${colors."ansi-green".hex}"
          "${colors."accent-warning".hex}"
          "${colors."syntax-keyword".hex}"
          "${colors."syntax-constant".hex}"
          "${colors."ansi-cyan".hex}"
          "${colors."syntax-type".hex}"
        ];

        # Border colors
        border = "${colors."divider-primary".hex}";
        "border.variant" = "${colors."divider-secondary".hex}";
        "border.focused" = "${colors."accent-primary".hex}";
        "border.selected" = "${colors."accent-primary".hex}";
        "border.transparent" = "#00000000";
        "border.disabled" = "${colors."text-tertiary".hex}";

        # Surface colors
        "elevated_surface.background" = "${colors."surface-emphasis".hex}";
        "surface.background" = "${colors."surface-subtle".hex}";
        background = "${colors."surface-base".hex}";

        # Element colors
        "element.background" = "${colors."surface-subtle".hex}";
        "element.hover" = "${colors."divider-secondary".hex}";
        "element.active" = "${colors."surface-emphasis".hex}";
        "element.selected" = "${colors."surface-emphasis".hex}";
        "element.disabled" = "${colors."surface-subtle".hex}";

        # Drop target
        "drop_target.background" = "${colors."accent-primary".hex}80";

        # Ghost elements
        "ghost_element.background" = "#00000000";
        "ghost_element.hover" = "${colors."divider-secondary".hex}";
        "ghost_element.active" = "${colors."surface-emphasis".hex}";
        "ghost_element.selected" = "${colors."surface-emphasis".hex}";
        "ghost_element.disabled" = "${colors."surface-subtle".hex}";

        # Text colors
        text = "${colors."text-primary".hex}";
        "text.muted" = "${colors."text-secondary".hex}";
        "text.placeholder" = "${colors."text-tertiary".hex}";
        "text.disabled" = "${colors."text-tertiary".hex}";
        "text.accent" = "${colors."accent-primary".hex}";

        # Icon colors
        icon = "${colors."text-primary".hex}";
        "icon.muted" = "${colors."text-tertiary".hex}";
        "icon.disabled" = "${colors."text-tertiary".hex}";
        "icon.placeholder" = "${colors."text-secondary".hex}";
        "icon.accent" = "${colors."accent-primary".hex}";

        # UI component backgrounds
        "status_bar.background" = "${colors."surface-emphasis".hex}";
        "title_bar.background" = "${colors."surface-base".hex}";
        "title_bar.inactive_background" = "${colors."surface-subtle".hex}";
        "toolbar.background" = "${colors."surface-subtle".hex}";
        "tab_bar.background" = "${colors."surface-subtle".hex}";
        "tab.inactive_background" = "${colors."surface-subtle".hex}";
        "tab.active_background" = "${colors."surface-base".hex}";

        # Search
        "search.match_background" = "${colors."accent-warning".hex}66";

        # Panel
        "panel.background" = "${colors."surface-subtle".hex}";
        "panel.focused_border" = "${colors."accent-primary".hex}";
        "pane.focused_border" = null;

        # Scrollbar
        "scrollbar.thumb.active_background" = "${colors."accent-primary".hex}ac";
        "scrollbar.thumb.hover_background" = "${colors."text-primary".hex}4c";
        "scrollbar.thumb.background" = "${colors."text-tertiary".hex}4c";
        "scrollbar.thumb.border" = "${colors."divider-secondary".hex}";
        "scrollbar.track.background" = "#00000000";
        "scrollbar.track.border" = "${colors."divider-primary".hex}";

        # Editor
        "editor.foreground" = "${colors."text-primary".hex}";
        "editor.background" = "${colors."surface-base".hex}";
        "editor.gutter.background" = "${colors."surface-base".hex}";
        "editor.subheader.background" = "${colors."surface-subtle".hex}";
        "editor.active_line.background" = "${colors."surface-subtle".hex}bf";
        "editor.highlighted_line.background" = "${colors."surface-subtle".hex}";
        "editor.line_number" = "${colors."text-tertiary".hex}";
        "editor.active_line_number" = "${colors."text-secondary".hex}";
        "editor.hover_line_number" = "${colors."text-secondary".hex}";
        "editor.invisible" = "${colors."text-tertiary".hex}";
        "editor.wrap_guide" = "${colors."divider-primary".hex}0d";
        "editor.active_wrap_guide" = "${colors."divider-primary".hex}1a";
        "editor.document_highlight.read_background" = "${colors."accent-primary".hex}1a";
        "editor.document_highlight.write_background" = "${colors."text-tertiary".hex}66";

        # Terminal
        "terminal.background" = "${colors."surface-base".hex}";
        "terminal.foreground" = "${colors."text-primary".hex}";
        "terminal.bright_foreground" = "${colors."text-primary".hex}";
        "terminal.dim_foreground" = "${colors."surface-base".hex}";
        "terminal.ansi.black" = "${colors."ansi-black".hex}";
        "terminal.ansi.bright_black" = "${colors."ansi-bright-black".hex}";
        "terminal.ansi.dim_black" = "${colors."text-primary".hex}";
        "terminal.ansi.red" = "${colors."ansi-red".hex}";
        "terminal.ansi.bright_red" = "${colors."ansi-red".hex}";
        "terminal.ansi.dim_red" = "${colors."ansi-red".hex}80";
        "terminal.ansi.green" = "${colors."ansi-green".hex}";
        "terminal.ansi.bright_green" = "${colors."ansi-green".hex}";
        "terminal.ansi.dim_green" = "${colors."ansi-green".hex}80";
        "terminal.ansi.yellow" = "${colors."ansi-yellow".hex}";
        "terminal.ansi.bright_yellow" = "${colors."ansi-yellow".hex}";
        "terminal.ansi.dim_yellow" = "${colors."ansi-yellow".hex}80";
        "terminal.ansi.blue" = "${colors."ansi-blue".hex}";
        "terminal.ansi.bright_blue" = "${colors."ansi-blue".hex}";
        "terminal.ansi.dim_blue" = "${colors."ansi-blue".hex}80";
        "terminal.ansi.magenta" = "${colors."ansi-magenta".hex}";
        "terminal.ansi.bright_magenta" = "${colors."ansi-magenta".hex}";
        "terminal.ansi.dim_magenta" = "${colors."ansi-magenta".hex}80";
        "terminal.ansi.cyan" = "${colors."ansi-cyan".hex}";
        "terminal.ansi.bright_cyan" = "${colors."ansi-cyan".hex}";
        "terminal.ansi.dim_cyan" = "${colors."ansi-cyan".hex}80";
        "terminal.ansi.white" = "${colors."ansi-white".hex}";
        "terminal.ansi.bright_white" = "${colors."ansi-bright-white".hex}";
        "terminal.ansi.dim_white" = "${colors."text-secondary".hex}";

        # Links
        "link_text.hover" = "${colors."accent-primary".hex}";

        # Version control
        "version_control.added" = "${colors."ansi-green".hex}";
        "version_control.modified" = "${colors."ansi-yellow".hex}";
        "version_control.deleted" = "${colors."ansi-red".hex}";

        # Status indicators
        conflict = "${colors."accent-warning".hex}";
        "conflict.background" = "${colors."accent-warning".hex}20";
        "conflict.border" = "${colors."accent-warning".hex}40";

        created = "${colors."ansi-green".hex}";
        "created.background" = "${colors."ansi-green".hex}20";
        "created.border" = "${colors."ansi-green".hex}40";

        deleted = "${colors."ansi-red".hex}";
        "deleted.background" = "${colors."ansi-red".hex}20";
        "deleted.border" = "${colors."ansi-red".hex}40";

        error = "${colors."syntax-error".hex}";
        "error.background" = "${colors."syntax-error".hex}20";
        "error.border" = "${colors."syntax-error".hex}40";

        hidden = "${colors."text-tertiary".hex}";
        "hidden.background" = "${colors."surface-base".hex}";
        "hidden.border" = "${colors."divider-primary".hex}";

        hint = "${colors."text-secondary".hex}";
        "hint.background" = "${colors."accent-info".hex}20";
        "hint.border" = "${colors."accent-info".hex}";

        ignored = "${colors."text-tertiary".hex}";
        "ignored.background" = "${colors."surface-base".hex}";
        "ignored.border" = "${colors."divider-primary".hex}";

        info = "${colors."accent-info".hex}";
        "info.background" = "${colors."accent-info".hex}20";
        "info.border" = "${colors."accent-info".hex}";

        modified = "${colors."ansi-yellow".hex}";
        "modified.background" = "${colors."ansi-yellow".hex}20";
        "modified.border" = "${colors."ansi-yellow".hex}40";

        predictive = "${colors."text-tertiary".hex}";
        "predictive.background" = "${colors."ansi-green".hex}20";
        "predictive.border" = "${colors."ansi-green".hex}40";

        renamed = "${colors."accent-info".hex}";
        "renamed.background" = "${colors."accent-info".hex}20";
        "renamed.border" = "${colors."accent-info".hex}";

        success = "${colors."ansi-green".hex}";
        "success.background" = "${colors."ansi-green".hex}20";
        "success.border" = "${colors."ansi-green".hex}40";

        unreachable = "${colors."text-secondary".hex}";
        "unreachable.background" = "${colors."surface-base".hex}";
        "unreachable.border" = "${colors."divider-primary".hex}";

        warning = "${colors."accent-warning".hex}";
        "warning.background" = "${colors."accent-warning".hex}20";
        "warning.border" = "${colors."accent-warning".hex}40";

        # Players for collaborative editing
        players = [
          {
            cursor = "${colors."accent-primary".hex}";
            background = "${colors."accent-primary".hex}";
            selection = "${colors."accent-primary".hex}3d";
          }
          {
            cursor = "${colors."text-secondary".hex}";
            background = "${colors."text-secondary".hex}";
            selection = "${colors."text-secondary".hex}3d";
          }
          {
            cursor = "${colors."syntax-type".hex}";
            background = "${colors."syntax-type".hex}";
            selection = "${colors."syntax-type".hex}3d";
          }
          {
            cursor = "${colors."syntax-constant".hex}";
            background = "${colors."syntax-constant".hex}";
            selection = "${colors."syntax-constant".hex}3d";
          }
          {
            cursor = "${colors."ansi-cyan".hex}";
            background = "${colors."ansi-cyan".hex}";
            selection = "${colors."ansi-cyan".hex}3d";
          }
          {
            cursor = "${colors."ansi-red".hex}";
            background = "${colors."ansi-red".hex}";
            selection = "${colors."ansi-red".hex}3d";
          }
          {
            cursor = "${colors."ansi-yellow".hex}";
            background = "${colors."ansi-yellow".hex}";
            selection = "${colors."ansi-yellow".hex}3d";
          }
          {
            cursor = "${colors."ansi-green".hex}";
            background = "${colors."ansi-green".hex}";
            selection = "${colors."ansi-green".hex}3d";
          }
        ];

        # Syntax highlighting
        syntax = {
          attribute = {
            color = "${colors."syntax-type".hex}";
            font_style = null;
            font_weight = null;
          };
          boolean = {
            color = "${colors."syntax-constant".hex}";
            font_style = null;
            font_weight = null;
          };
          comment = {
            color = "${colors."syntax-comment".hex}";
            font_style = "italic";
            font_weight = null;
          };
          "comment.doc" = {
            color = "${colors."text-secondary".hex}";
            font_style = "italic";
            font_weight = null;
          };
          constant = {
            color = "${colors."syntax-constant".hex}";
            font_style = null;
            font_weight = null;
          };
          constructor = {
            color = "${colors."syntax-type".hex}";
            font_style = null;
            font_weight = null;
          };
          embedded = {
            color = "${colors."syntax-special".hex}";
            font_style = null;
            font_weight = null;
          };
          emphasis = {
            color = "${colors."accent-primary".hex}";
            font_style = "italic";
            font_weight = null;
          };
          "emphasis.strong" = {
            color = "${colors."accent-primary".hex}";
            font_style = null;
            font_weight = 700;
          };
          enum = {
            color = "${colors."syntax-type".hex}";
            font_style = null;
            font_weight = null;
          };
          "function" = {
            color = "${colors."syntax-function-def".hex}";
            font_style = null;
            font_weight = null;
          };
          "function.builtin" = {
            color = "${colors."syntax-keyword".hex}";
            font_style = null;
            font_weight = null;
          };
          "function.call" = {
            color = "${colors."syntax-function-call".hex}";
            font_style = null;
            font_weight = null;
          };
          hint = {
            color = "${colors."text-secondary".hex}";
            font_style = null;
            font_weight = null;
          };
          keyword = {
            color = "${colors."syntax-keyword".hex}";
            font_style = null;
            font_weight = null;
          };
          label = {
            color = "${colors."accent-primary".hex}";
            font_style = null;
            font_weight = null;
          };
          link_text = {
            color = "${colors."accent-primary".hex}";
            font_style = "italic";
            font_weight = null;
          };
          link_uri = {
            color = "${colors."accent-info".hex}";
            font_style = null;
            font_weight = null;
          };
          namespace = {
            color = "${colors."syntax-type".hex}";
            font_style = null;
            font_weight = null;
          };
          number = {
            color = "${colors."syntax-number".hex}";
            font_style = null;
            font_weight = null;
          };
          operator = {
            color = "${colors."text-primary".hex}";
            font_style = null;
            font_weight = null;
          };
          predictive = {
            color = "${colors."text-tertiary".hex}";
            font_style = "italic";
            font_weight = null;
          };
          preproc = {
            color = "${colors."syntax-keyword".hex}";
            font_style = null;
            font_weight = null;
          };
          primary = {
            color = "${colors."text-primary".hex}";
            font_style = null;
            font_weight = null;
          };
          property = {
            color = "${colors."text-primary".hex}";
            font_style = null;
            font_weight = null;
          };
          punctuation = {
            color = "${colors."text-secondary".hex}";
            font_style = null;
            font_weight = null;
          };
          "punctuation.bracket" = {
            color = "${colors."text-secondary".hex}";
            font_style = null;
            font_weight = null;
          };
          "punctuation.delimiter" = {
            color = "${colors."text-secondary".hex}";
            font_style = null;
            font_weight = null;
          };
          "punctuation.list_marker" = {
            color = "${colors."text-primary".hex}";
            font_style = null;
            font_weight = null;
          };
          "punctuation.markup" = {
            color = "${colors."accent-primary".hex}";
            font_style = null;
            font_weight = null;
          };
          "punctuation.special" = {
            color = "${colors."text-secondary".hex}";
            font_style = null;
            font_weight = null;
          };
          selector = {
            color = "${colors."syntax-type".hex}";
            font_style = null;
            font_weight = null;
          };
          "selector.pseudo" = {
            color = "${colors."syntax-keyword".hex}";
            font_style = null;
            font_weight = null;
          };
          string = {
            color = "${colors."syntax-string".hex}";
            font_style = null;
            font_weight = null;
          };
          "string.escape" = {
            color = "${colors."syntax-special".hex}";
            font_style = null;
            font_weight = null;
          };
          "string.regex" = {
            color = "${colors."syntax-string".hex}";
            font_style = null;
            font_weight = null;
          };
          "string.special" = {
            color = "${colors."syntax-special".hex}";
            font_style = null;
            font_weight = null;
          };
          "string.special.symbol" = {
            color = "${colors."syntax-constant".hex}";
            font_style = null;
            font_weight = null;
          };
          tag = {
            color = "${colors."syntax-keyword".hex}";
            font_style = null;
            font_weight = null;
          };
          "text.literal" = {
            color = "${colors."syntax-string".hex}";
            font_style = null;
            font_weight = null;
          };
          title = {
            color = "${colors."syntax-function-def".hex}";
            font_style = null;
            font_weight = 700;
          };
          type = {
            color = "${colors."syntax-type".hex}";
            font_style = null;
            font_weight = null;
          };
          variable = {
            color = "${colors."text-primary".hex}";
            font_style = null;
            font_weight = null;
          };
          "variable.special" = {
            color = "${colors."accent-primary".hex}";
            font_style = null;
            font_weight = null;
          };
          variant = {
            color = "${colors."syntax-type".hex}";
            font_style = null;
            font_weight = null;
          };
        };
      };
    };

  # Generate the complete theme family with both light and dark variants
  generateZedTheme = {
    "$schema" = "https://zed.dev/schema/themes/v0.2.0.json";
    name = "Scientific";
    author = "Scientific Color System";
    themes = [
      (generateThemeVariant darkPalette "dark")
      (generateThemeVariant lightPalette "light")
    ];
  };
in
{
  config =
    mkIf (cfg.enable && cfg.applications.zed.enable && darkPalette != null && lightPalette != null)
      {
        # Generate and install the theme file with both light and dark variants
        # Using home.file instead of xdg.configFile to allow manual theme management
        home.file.".config/zed/themes/scientific.json" = {
          text = builtins.toJSON generateZedTheme;
          force = false; # Don't overwrite if file exists, allows manual theme additions
        };

        # Configure Zed to use the scientific theme
        programs.zed-editor.userSettings = {
          theme = {
            mode = "system";
            light = "Scientific Light";
            dark = "Scientific Dark";
          };
        };
      };
}
