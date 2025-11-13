{
  config,
  lib,
  themeContext ? null,
  ...
}:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.theming.signal;

  # Get author name from config if available, otherwise default to "Lewis Flude"
  # Check config.theming.signal.author first, then fall back to default
  authorName = config.theming.signal.author or "Lewis Flude";

  # Safely access themeContext attributes only when available
  themeLib = if themeContext != null then themeContext.lib else null;
  rawPalette = if themeContext != null then themeContext.palette else null;

  # Helper to add alpha channel to hex color
  # Input: color object, alpha hex string (e.g., "ff", "3d", "66")
  # Output: 8-digit hex string with alpha
  withAlpha = color: alpha: "${color.hex}${alpha}";

  # Generate a complete Zed theme variant with ALL properties
  # Returns a ThemeContent object matching the schema:
  # - appearance: "light" | "dark" (required)
  # - name: string (required)
  # - style: ThemeStyleContent object (required)
  generateZedThemeVariant =
    themePalette: variantName:
    let
      inherit (themePalette) colors;
      mode = if variantName == "Dark" then "dark" else "light";

      # Helper to get categorical color (for players and syntax)
      # Access categorical palette from themeContext using getPalette
      categoricalPalette = themeLib.getPalette mode rawPalette.categorical;
      cat = name: categoricalPalette.${name};
    in
    {
      # ThemeContent required fields (must match schema exactly)
      # Note: author is NOT in ThemeContent - it's only in ThemeFamilyContent
      appearance = mode; # "light" or "dark"
      name = "Signal ${variantName}";

      style = {
        # Border properties
        border = colors."divider-primary".hex + "ff";
        "border.variant" = colors."divider-secondary".hex + "ff";
        "border.focused" = colors."accent-focus".hex + "ff";
        "border.selected" = colors."accent-primary".hex + "ff";
        "border.transparent" = colors."border-transparent".hex;
        "border.disabled" = withAlpha colors."divider-primary" "80";

        # Surface properties
        "elevated_surface.background" = colors."surface-emphasis".hex + "ff";
        "surface.background" = colors."surface-base".hex + "ff";
        background = colors."surface-subtle".hex + "ff";
        "background.appearance" = null; # Optional: "opaque", "transparent", or "blurred"
        "element.background" = colors."surface-base".hex + "ff";
        "element.hover" = colors."surface-subtle".hex + "ff";
        "element.active" = colors."surface-emphasis".hex + "ff";
        "element.selected" = colors."surface-emphasis".hex + "ff";
        "element.disabled" = withAlpha colors."surface-base" "80";
        "drop_target.background" = withAlpha colors."accent-focus" "80";

        # Accents array (default empty, can contain accent color strings)
        accents = [ ];

        # Ghost element properties
        "ghost_element.background" = colors."surface-transparent".hex;
        "ghost_element.hover" = colors."surface-subtle".hex + "ff";
        "ghost_element.active" = colors."surface-emphasis".hex + "ff";
        "ghost_element.selected" = colors."surface-emphasis".hex + "ff";
        "ghost_element.disabled" = withAlpha colors."surface-base" "80";

        # Text properties
        text = colors."text-primary".hex + "ff";
        "text.muted" = colors."text-secondary".hex + "ff";
        "text.placeholder" = colors."text-tertiary".hex + "ff";
        "text.disabled" = colors."text-tertiary".hex + "ff";
        "text.accent" = colors."accent-primary".hex + "ff";

        # Icon properties
        icon = colors."text-primary".hex + "ff";
        "icon.muted" = colors."text-secondary".hex + "ff";
        "icon.disabled" = colors."text-tertiary".hex + "ff";
        "icon.placeholder" = colors."text-secondary".hex + "ff";
        "icon.accent" = colors."accent-primary".hex + "ff";

        # UI component properties
        "status_bar.background" = colors."surface-emphasis".hex + "ff";
        "title_bar.background" = colors."surface-emphasis".hex + "ff";
        "title_bar.inactive_background" = colors."surface-base".hex + "ff";
        "toolbar.background" = colors."surface-base".hex + "ff";
        "tab_bar.background" = colors."surface-subtle".hex + "ff";
        "tab.inactive_background" = colors."surface-subtle".hex + "ff";
        "tab.active_background" = colors."surface-base".hex + "ff";
        "search.match_background" = withAlpha colors."accent-warning" "66";
        "panel.background" = colors."surface-subtle".hex + "ff";
        "panel.focused_border" = null;
        "panel.indent_guide" = withAlpha colors."divider-primary" "1a";
        "panel.indent_guide_active" = withAlpha colors."divider-primary" "33";
        "panel.indent_guide_hover" = withAlpha colors."divider-primary" "4c";
        "pane.focused_border" = null;
        "pane_group.border" = colors."divider-primary".hex + "ff";

        # Scrollbar properties
        "scrollbar.thumb.background" = withAlpha colors."divider-primary" "4c";
        "scrollbar.thumb.hover_background" = colors."surface-subtle".hex + "ff";
        "scrollbar.thumb.border" = colors."surface-subtle".hex + "ff";
        "scrollbar.track.background" = colors."transparent".hex;
        "scrollbar.track.border" = colors."divider-primary".hex + "ff";

        # Editor properties
        "editor.foreground" = colors."text-primary".hex + "ff";
        "editor.background" = colors."surface-base".hex + "ff";
        "editor.gutter.background" = colors."surface-base".hex + "ff";
        "editor.subheader.background" = colors."surface-subtle".hex + "ff";
        "editor.active_line.background" = withAlpha colors."surface-subtle" "bf";
        "editor.highlighted_line.background" = colors."surface-subtle".hex + "ff";
        "editor.line_number" = colors."text-tertiary".hex;
        "editor.active_line_number" = colors."text-primary".hex;
        "editor.invisible" = colors."text-tertiary".hex + "ff";
        "editor.indent_guide" = withAlpha colors."divider-primary" "1a";
        "editor.indent_guide_active" = withAlpha colors."divider-primary" "33";
        "editor.wrap_guide" = withAlpha colors."divider-primary" "0d";
        "editor.active_wrap_guide" = withAlpha colors."divider-primary" "1a";
        "editor.document_highlight.bracket_background" = withAlpha colors."accent-focus" "1a";
        "editor.document_highlight.read_background" = withAlpha colors."accent-focus" "1a";
        "editor.document_highlight.write_background" = withAlpha colors."text-tertiary" "66";

        # Terminal properties (complete ANSI set)
        "terminal.background" = colors."surface-base".hex + "ff";
        "terminal.foreground" = colors."text-primary".hex + "ff";
        "terminal.bright_foreground" = colors."text-primary".hex + "ff";
        "terminal.dim_foreground" = colors."surface-base".hex + "ff";
        "terminal.ansi.background" = colors."surface-base".hex + "ff";
        "terminal.ansi.black" = colors."ansi-black".hex + "ff";
        "terminal.ansi.bright_black" = colors."ansi-bright-black".hex + "ff";
        "terminal.ansi.dim_black" = colors."text-primary".hex + "ff";
        "terminal.ansi.red" = colors."ansi-red".hex + "ff";
        "terminal.ansi.bright_red" = colors."ansi-red".hex + "ff";
        "terminal.ansi.dim_red" = withAlpha colors."ansi-red" "cc";
        "terminal.ansi.green" = colors."ansi-green".hex + "ff";
        "terminal.ansi.bright_green" = colors."ansi-green".hex + "ff";
        "terminal.ansi.dim_green" = withAlpha colors."ansi-green" "cc";
        "terminal.ansi.yellow" = colors."ansi-yellow".hex + "ff";
        "terminal.ansi.bright_yellow" = colors."ansi-yellow".hex + "ff";
        "terminal.ansi.dim_yellow" = withAlpha colors."ansi-yellow" "cc";
        "terminal.ansi.blue" = colors."ansi-blue".hex + "ff";
        "terminal.ansi.bright_blue" = colors."ansi-blue".hex + "ff";
        "terminal.ansi.dim_blue" = withAlpha colors."ansi-blue" "cc";
        "terminal.ansi.magenta" = colors."ansi-magenta".hex + "ff";
        "terminal.ansi.bright_magenta" = colors."ansi-magenta".hex + "ff";
        "terminal.ansi.dim_magenta" = withAlpha colors."ansi-magenta" "cc";
        "terminal.ansi.cyan" = colors."ansi-cyan".hex + "ff";
        "terminal.ansi.bright_cyan" = colors."ansi-cyan".hex + "ff";
        "terminal.ansi.dim_cyan" = withAlpha colors."ansi-cyan" "cc";
        "terminal.ansi.white" = colors."ansi-white".hex + "ff";
        "terminal.ansi.bright_white" = colors."ansi-bright-white".hex + "ff";
        "terminal.ansi.dim_white" = colors."text-tertiary".hex + "ff";

        # Link properties
        "link_text.hover" = colors."accent-focus".hex + "ff";

        # Diagnostic properties (complete set)
        conflict = colors."accent-warning".hex + "ff";
        "conflict.background" = withAlpha colors."accent-warning" "1a";
        "conflict.border" = colors."accent-warning".hex + "ff";
        created = colors."accent-primary".hex + "ff";
        "created.background" = withAlpha colors."accent-primary" "1a";
        "created.border" = colors."accent-primary".hex + "ff";
        deleted = colors."accent-danger".hex + "ff";
        "deleted.background" = withAlpha colors."accent-danger" "1a";
        "deleted.border" = colors."accent-danger".hex + "ff";
        error = colors."accent-danger".hex + "ff";
        "error.background" = withAlpha colors."accent-danger" "1a";
        "error.border" = colors."accent-danger".hex + "ff";
        hidden = colors."text-tertiary".hex + "ff";
        "hidden.background" = withAlpha colors."text-tertiary" "1a";
        "hidden.border" = colors."divider-primary".hex + "ff";
        hint = colors."accent-info".hex + "ff";
        "hint.background" = withAlpha colors."accent-info" "1a";
        "hint.border" = colors."accent-focus".hex + "ff";
        ignored = colors."text-tertiary".hex + "ff";
        "ignored.background" = withAlpha colors."text-tertiary" "1a";
        "ignored.border" = colors."divider-primary".hex + "ff";
        info = colors."accent-focus".hex + "ff";
        "info.background" = withAlpha colors."accent-focus" "1a";
        "info.border" = colors."accent-focus".hex + "ff";
        modified = colors."accent-warning".hex + "ff";
        "modified.background" = withAlpha colors."accent-warning" "1a";
        "modified.border" = colors."accent-warning".hex + "ff";
        predictive = colors."text-secondary".hex + "ff";
        "predictive.background" = withAlpha colors."text-secondary" "1a";
        "predictive.border" = colors."accent-primary".hex + "ff";
        renamed = colors."accent-focus".hex + "ff";
        "renamed.background" = withAlpha colors."accent-focus" "1a";
        "renamed.border" = colors."accent-focus".hex + "ff";
        success = colors."accent-primary".hex + "ff";
        "success.background" = withAlpha colors."accent-primary" "1a";
        "success.border" = colors."accent-primary".hex + "ff";
        unreachable = colors."text-secondary".hex + "ff";
        "unreachable.background" = withAlpha colors."text-secondary" "1a";
        "unreachable.border" = colors."divider-primary".hex + "ff";
        warning = colors."accent-warning".hex + "ff";
        "warning.background" = withAlpha colors."accent-warning" "1a";
        "warning.border" = colors."accent-warning".hex + "ff";

        # Players array (8 player color sets) - must be inside style
        players = [
          {
            cursor = colors."accent-focus".hex + "ff";
            background = colors."accent-focus".hex + "ff";
            selection = withAlpha colors."accent-focus" "3d";
          }
          {
            cursor = colors."accent-danger".hex + "ff";
            background = colors."accent-danger".hex + "ff";
            selection = withAlpha colors."accent-danger" "3d";
          }
          {
            cursor = colors."accent-warning".hex + "ff";
            background = colors."accent-warning".hex + "ff";
            selection = withAlpha colors."accent-warning" "3d";
          }
          {
            cursor = (cat "GA03").hex + "ff";
            background = (cat "GA03").hex + "ff";
            selection = withAlpha (cat "GA03") "3d";
          }
          {
            cursor = (cat "GA07").hex + "ff";
            background = (cat "GA07").hex + "ff";
            selection = withAlpha (cat "GA07") "3d";
          }
          {
            cursor = (cat "GA01").hex + "ff";
            background = (cat "GA01").hex + "ff";
            selection = withAlpha (cat "GA01") "3d";
          }
          {
            cursor = (cat "GA04").hex + "ff";
            background = (cat "GA04").hex + "ff";
            selection = withAlpha (cat "GA04") "3d";
          }
          {
            cursor = colors."accent-primary".hex + "ff";
            background = colors."accent-primary".hex + "ff";
            selection = withAlpha colors."accent-primary" "3d";
          }
        ];

        # Syntax properties (complete set) - must be inside style
        syntax = {
          attribute = {
            color = colors."accent-focus".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          boolean = {
            color = (cat "GA06").hex + "ff";
            font_style = null;
            font_weight = null;
          };
          comment = {
            color = colors."syntax-comment".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          "comment.doc" = {
            color = colors."text-secondary".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          constant = {
            color = (cat "GA03").hex + "ff";
            font_style = null;
            font_weight = null;
          };
          constructor = {
            color = colors."accent-focus".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          embedded = {
            color = colors."text-primary".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          emphasis = {
            color = colors."accent-focus".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          "emphasis.strong" = {
            color = colors."accent-warning".hex + "ff";
            font_style = null;
            font_weight = 700;
          };
          enum = {
            color = colors."accent-danger".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          function = {
            color = colors."syntax-function-call".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          hint = {
            color = colors."accent-info".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          keyword = {
            color = colors."syntax-keyword".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          label = {
            color = colors."accent-focus".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          "link_text" = {
            color = colors."accent-focus".hex + "ff";
            font_style = "normal";
            font_weight = null;
          };
          "link_uri" = {
            color = colors."accent-info".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          namespace = {
            color = colors."text-primary".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          number = {
            color = colors."syntax-number".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          operator = {
            color = colors."accent-info".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          predictive = {
            color = colors."text-secondary".hex + "ff";
            font_style = "italic";
            font_weight = null;
          };
          preproc = {
            color = colors."text-primary".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          primary = {
            color = colors."text-primary".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          property = {
            color = colors."accent-danger".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          punctuation = {
            color = colors."text-primary".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          "punctuation.bracket" = {
            color = colors."text-secondary".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          "punctuation.delimiter" = {
            color = colors."text-secondary".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          "punctuation.list_marker" = {
            color = colors."accent-danger".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          "punctuation.markup" = {
            color = colors."accent-danger".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          "punctuation.special" = {
            color = colors."accent-danger".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          selector = {
            color = colors."accent-warning".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          "selector.pseudo" = {
            color = colors."accent-focus".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          string = {
            color = colors."syntax-string".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          "string.escape" = {
            color = colors."text-secondary".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          "string.regex" = {
            color = colors."accent-warning".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          "string.special" = {
            color = colors."accent-warning".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          "string.special.symbol" = {
            color = colors."accent-warning".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          tag = {
            color = colors."accent-focus".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          "text.literal" = {
            color = colors."accent-primary".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          title = {
            color = colors."accent-danger".hex + "ff";
            font_style = null;
            font_weight = 400;
          };
          type = {
            color = colors."syntax-type".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          variable = {
            color = colors."text-primary".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          "variable.special" = {
            color = colors."accent-warning".hex + "ff";
            font_style = null;
            font_weight = null;
          };
          variant = {
            color = colors."accent-focus".hex + "ff";
            font_style = null;
            font_weight = null;
          };
        };
      };
    };

  # Generate a single theme family in ThemeFamilyContent format
  # This matches the schema from v0.2.0.json exactly:
  # - author: string (required)
  # - name: string (required)
  # - themes: array of ThemeContent objects (required)
  # Each ThemeContent has: appearance, name, style
  themeFamily =
    if themeContext != null then
      let
        # Generate both light and dark palettes
        darkPalette = themeLib.generateTheme "dark" { };
        lightPalette = themeLib.generateTheme "light" { };

        # Generate both theme variants (dark and light)
        darkTheme = generateZedThemeVariant darkPalette "Dark";
        lightTheme = generateZedThemeVariant lightPalette "Light";
      in
      {
        # ThemeFamilyContent required fields (must match schema exactly)
        author = authorName;
        name = "Signal";
        # Array containing both dark and light ThemeContent objects
        themes = [
          darkTheme
          lightTheme
        ];
      }
    else
      null;
in
{
  options.theming.signal.applications.zed.themes = mkOption {
    type = types.nullOr (
      types.submodule {
        options = {
          author = mkOption {
            type = types.str;
            description = "Theme author name";
          };
          name = mkOption {
            type = types.str;
            description = "Theme family name";
          };
          themes = mkOption {
            type = types.listOf types.attrs;
            description = "Array of theme objects";
          };
        };
      }
    );
    default = null;
    description = "Zed editor theme family in ThemeFamilyContent format";
    internal = true; # Mark as internal since it's generated, not user-configured
  };

  config = mkIf (cfg.enable && cfg.applications.zed.enable && themeContext != null) {
    # Export theme family for use in home-manager
    theming.signal.applications.zed.themes = themeFamily;
  };
}
