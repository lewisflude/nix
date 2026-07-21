# Signal Zed Editor Theme Module
#
# This module generates a custom Zed theme and configures Zed to use it via
# Home Manager's programs.zed-editor module (themes + userSettings).
# It assumes you have already enabled Zed with:
#   programs.zed-editor.enable = true;
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
# CONFIGURATION METHOD: home-manager-module (Tier 2)
# HOME-MANAGER MODULE: programs.zed-editor.themes + programs.zed-editor.userSettings
# UPSTREAM SCHEMA: https://zed.dev/schema/themes/v0.2.0.json
# SCHEMA VERSION: v0.2.0
# LAST VALIDATED: 2026-01-20
# NOTES: Uses Home Manager's programs.zed-editor module to install the theme
#        and configure Zed to select it via userSettings.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Define colors using semantic bridge
  colors = {
    # Editor UI
    bg = semantic.editor "background" themeMode;
    bg-alt = semantic.editor "active-line-background" themeMode;
    gutter-bg = semantic.editor "gutter-background" themeMode;
    fg = semantic.editor "foreground" themeMode;
    fg-alt = semantic.editor "line-number" themeMode;
    fg-dim = semantic.syntax "comment" themeMode;

    # Core UI
    cursor = semantic.core "cursor" themeMode;
    selection = semantic.core "selection-bg" themeMode;
    selection-fg = semantic.core "selection-fg" themeMode;
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
    attribute = semantic.syntax "attribute" themeMode;
    preprocessing = semantic.syntax "preprocessing" themeMode;

    # Status colors
    error = semantic.status "error" themeMode;
    warning = semantic.status "warning" themeMode;
    success = semantic.status "success" themeMode;
    info = semantic.status "info" themeMode;
    hint = semantic.status "hint" themeMode;

    # VCS colors
    added = semantic.vcs "added" themeMode;
    modified = semantic.vcs "modified" themeMode;
    deleted = semantic.vcs "deleted" themeMode;

    # UI components
    panel-bg = semantic.ui "panel-background" themeMode;
    panel-border = semantic.ui "panel-border" themeMode;
    element-hover = semantic.ui "element-hover" themeMode;
    element-active = semantic.ui "element-active" themeMode;
    element-selected = semantic.ui "element-selected" themeMode;
  };

  # Categorical colors (data visualization / multiplayer)
  categorical = {
    "data-viz-03" = semantic.multiplayer "player-3" themeMode;
    "data-viz-05" = semantic.multiplayer "player-5" themeMode;
    "data-viz-07" = semantic.multiplayer "player-7" themeMode;
    "data-viz-08" = semantic.multiplayer "player-8" themeMode;
    "data-viz-09" = semantic.multiplayer "player-1" themeMode;
  };

  # Helper to add alpha channel to hex color
  withAlpha = color: alpha: "${color.hex}${alpha}";

  # Transparent color constant (fully transparent black)
  transparent = withAlpha (semantic.getTonal "black" themeMode) "00";

  # Generate Zed theme JSON structure
  zedTheme = {
    "$schema" = "https://zed.dev/schema/themes/v0.2.0.json";
    name = "Signal";
    author = "Signal Design System";
    themes = [
      {
        name = "Signal ${if themeMode == "dark" then "Dark" else "Light"}";
        appearance = themeMode;
        style = {
          # Border colors
          border = withAlpha colors.panel-border "ff";
          "border.variant" = withAlpha colors.panel-border "cc";
          "border.focused" = withAlpha colors.cursor "ff";
          "border.selected" = withAlpha colors.cursor "66";
          "border.transparent" = transparent;
          "border.disabled" = withAlpha colors.panel-border "66";

          # Surface colors
          "elevated_surface.background" = withAlpha colors.bg "ff";
          "surface.background" = withAlpha colors.bg "ff";
          background = withAlpha colors.bg-alt "ff";

          # Element colors (buttons, interactive elements)
          "element.background" = withAlpha colors.bg "ff";
          "element.hover" = withAlpha colors.bg-alt "ff";
          "element.active" = withAlpha colors.element-selected "ff";
          "element.selected" = withAlpha colors.element-selected "ff";
          "element.disabled" = withAlpha colors.bg "80";

          # Drop target
          "drop_target.background" = withAlpha colors.cursor "40";

          # Ghost elements (transparent interactive elements)
          "ghost_element.background" = transparent;
          "ghost_element.hover" = withAlpha colors.bg-alt "ff";
          "ghost_element.active" = withAlpha colors.element-selected "ff";
          "ghost_element.selected" = withAlpha colors.element-selected "ff";
          "ghost_element.disabled" = withAlpha colors.bg "80";

          # Text colors
          text = withAlpha colors.fg "ff";
          "text.muted" = withAlpha colors.fg-alt "ff";
          "text.placeholder" = withAlpha colors.fg-dim "ff";
          "text.disabled" = withAlpha colors.fg-dim "80";
          "text.accent" = withAlpha colors.cursor "ff";

          # Icon colors
          icon = withAlpha colors.fg "ff";
          "icon.muted" = withAlpha colors.fg-alt "ff";
          "icon.disabled" = withAlpha colors.fg-dim "80";
          "icon.placeholder" = withAlpha colors.fg-alt "ff";
          "icon.accent" = withAlpha colors.cursor "ff";

          # UI component colors
          "status_bar.background" = withAlpha colors.bg-alt "ff";
          "title_bar.background" = withAlpha colors.bg-alt "ff";
          "title_bar.inactive_background" = withAlpha colors.bg "ff";
          "toolbar.background" = withAlpha colors.gutter-bg "ff";
          "tab_bar.background" = withAlpha colors.bg "ff";
          "tab.inactive_background" = withAlpha colors.bg "ff";
          "tab.active_background" = withAlpha colors.gutter-bg "ff";

          # Search
          "search.match_background" = withAlpha colors.cursor "40";
          "search.active_match_background" = withAlpha colors.warning "40";

          # Panel
          "panel.background" = withAlpha colors.bg "ff";
          "panel.focused_border" = null;
          "pane.focused_border" = null;

          # Scrollbar
          "scrollbar.thumb.background" = withAlpha colors.selection "80";
          "scrollbar.thumb.hover_background" = withAlpha colors.bg-alt "ff";
          "scrollbar.thumb.border" = withAlpha colors.bg-alt "ff";
          "scrollbar.track.background" = transparent;
          "scrollbar.track.border" = withAlpha colors.panel-border "ff";

          # Editor
          "editor.foreground" = withAlpha colors.fg "ff";
          "editor.background" = withAlpha colors.gutter-bg "ff";
          "editor.gutter.background" = withAlpha colors.gutter-bg "ff";
          "editor.subheader.background" = withAlpha colors.bg "ff";
          "editor.active_line.background" = withAlpha colors.bg "bf";
          "editor.highlighted_line.background" = withAlpha colors.bg "ff";
          "editor.line_number" = withAlpha colors.fg-dim "ff";
          "editor.active_line_number" = withAlpha colors.fg "ff";
          "editor.hover_line_number" = withAlpha colors.fg-alt "ff";
          "editor.invisible" = withAlpha colors.fg-dim "ff";
          "editor.wrap_guide" = withAlpha colors.panel-border "20";
          "editor.active_wrap_guide" = withAlpha colors.panel-border "40";
          "editor.document_highlight.read_background" = withAlpha colors.cursor "20";
          "editor.document_highlight.write_background" = withAlpha colors.warning "20";

          # Terminal
          "terminal.background" = withAlpha colors.gutter-bg "ff";
          "terminal.foreground" = withAlpha colors.fg "ff";
          "terminal.bright_foreground" = withAlpha colors.fg "ff";
          "terminal.dim_foreground" = withAlpha colors.fg-dim "ff";

          # Terminal ANSI colors
          "terminal.ansi.black" = withAlpha colors.string "ff";
          "terminal.ansi.bright_black" = withAlpha categorical."data-viz-05" "ff";
          "terminal.ansi.dim_black" = withAlpha colors.string "80";
          "terminal.ansi.red" = withAlpha colors.error "ff";
          "terminal.ansi.bright_red" = withAlpha (semantic.terminal "ansi-bright-red" themeMode) "ff";
          "terminal.ansi.dim_red" = withAlpha (semantic.terminal "ansi-red" themeMode) "ff";
          "terminal.ansi.green" = withAlpha colors.function "ff";
          "terminal.ansi.bright_green" = withAlpha categorical."data-viz-03" "ff";
          "terminal.ansi.dim_green" = withAlpha colors.string "ff";
          "terminal.ansi.yellow" = withAlpha colors.warning "ff";
          "terminal.ansi.bright_yellow" = withAlpha (semantic.terminal "ansi-bright-yellow" themeMode) "ff";
          "terminal.ansi.dim_yellow" = withAlpha (semantic.terminal "ansi-yellow" themeMode) "ff";
          "terminal.ansi.blue" = withAlpha colors.cursor "ff";
          "terminal.ansi.bright_blue" = withAlpha (semantic.terminal "ansi-bright-blue" themeMode) "ff";
          "terminal.ansi.dim_blue" = withAlpha (semantic.terminal "ansi-blue" themeMode) "ff";
          "terminal.ansi.magenta" = withAlpha colors.keyword "ff";
          "terminal.ansi.bright_magenta" = withAlpha (semantic.terminal "ansi-bright-magenta" themeMode) "ff";
          "terminal.ansi.dim_magenta" = withAlpha (semantic.terminal "ansi-magenta" themeMode) "ff";
          "terminal.ansi.cyan" = withAlpha categorical."data-viz-08" "ff";
          "terminal.ansi.bright_cyan" = withAlpha categorical."data-viz-09" "ff";
          "terminal.ansi.dim_cyan" = withAlpha categorical."data-viz-07" "ff";
          "terminal.ansi.white" = withAlpha colors.fg "ff";
          "terminal.ansi.bright_white" = withAlpha colors.fg "ff";
          "terminal.ansi.dim_white" = withAlpha colors.fg-alt "ff";

          # Links
          "link_text.hover" = withAlpha colors.cursor "ff";

          # Version control
          "version_control.added" = withAlpha colors.function "ff";
          "version_control.modified" = withAlpha colors.warning "ff";
          "version_control.word_added" = withAlpha colors.function "40";
          "version_control.word_deleted" = withAlpha colors.error "40";
          "version_control.deleted" = withAlpha colors.error "ff";
          "version_control.conflict_marker.ours" = withAlpha colors.function "20";
          "version_control.conflict_marker.theirs" = withAlpha colors.cursor "20";

          # Status colors
          conflict = withAlpha colors.warning "ff";
          "conflict.background" = withAlpha colors.warning "20";
          "conflict.border" = withAlpha colors.warning "80";

          created = withAlpha colors.function "ff";
          "created.background" = withAlpha colors.function "20";
          "created.border" = withAlpha colors.function "80";

          deleted = withAlpha colors.error "ff";
          "deleted.background" = withAlpha colors.error "20";
          "deleted.border" = withAlpha colors.error "80";

          error = withAlpha colors.error "ff";
          "error.background" = withAlpha colors.error "20";
          "error.border" = withAlpha colors.error "80";

          hidden = withAlpha colors.fg-dim "ff";
          "hidden.background" = withAlpha colors.fg-dim "20";
          "hidden.border" = withAlpha colors.panel-border "ff";

          hint = withAlpha colors.cursor "ff";
          "hint.background" = withAlpha colors.cursor "20";
          "hint.border" = withAlpha colors.cursor "80";

          ignored = withAlpha colors.fg-dim "ff";
          "ignored.background" = withAlpha colors.fg-dim "20";
          "ignored.border" = withAlpha colors.panel-border "ff";

          info = withAlpha colors.cursor "ff";
          "info.background" = withAlpha colors.cursor "20";
          "info.border" = withAlpha colors.cursor "80";

          modified = withAlpha colors.warning "ff";
          "modified.background" = withAlpha colors.warning "20";
          "modified.border" = withAlpha colors.warning "80";

          predictive = withAlpha colors.fg-alt "ff";
          "predictive.background" = withAlpha colors.fg-alt "20";
          "predictive.border" = withAlpha colors.panel-border "ff";

          renamed = withAlpha colors.cursor "ff";
          "renamed.background" = withAlpha colors.cursor "20";
          "renamed.border" = withAlpha colors.cursor "80";

          success = withAlpha colors.function "ff";
          "success.background" = withAlpha colors.function "20";
          "success.border" = withAlpha colors.function "80";

          unreachable = withAlpha colors.fg-alt "ff";
          "unreachable.background" = withAlpha colors.fg-alt "20";
          "unreachable.border" = withAlpha colors.panel-border "ff";

          warning = withAlpha colors.warning "ff";
          "warning.background" = withAlpha colors.warning "20";
          "warning.border" = withAlpha colors.warning "80";

          # Collaborative editing colors (multiplayer cursors)
          players = [
            {
              cursor = withAlpha colors.cursor "ff";
              background = withAlpha colors.cursor "ff";
              selection = withAlpha colors.cursor "40";
            }
            {
              cursor = withAlpha colors.error "ff";
              background = withAlpha colors.error "ff";
              selection = withAlpha colors.error "40";
            }
            {
              cursor = withAlpha colors.warning "ff";
              background = withAlpha colors.warning "ff";
              selection = withAlpha colors.warning "40";
            }
            {
              cursor = withAlpha colors.keyword "ff";
              background = withAlpha colors.keyword "ff";
              selection = withAlpha colors.keyword "40";
            }
            {
              cursor = withAlpha categorical."data-viz-08" "ff";
              background = withAlpha categorical."data-viz-08" "ff";
              selection = withAlpha categorical."data-viz-08" "40";
            }
            {
              cursor = withAlpha colors.function "ff";
              background = withAlpha colors.function "ff";
              selection = withAlpha colors.function "40";
            }
            {
              cursor = withAlpha colors.type "ff";
              background = withAlpha colors.type "ff";
              selection = withAlpha colors.type "40";
            }
            {
              cursor = withAlpha colors.number "ff";
              background = withAlpha colors.number "ff";
              selection = withAlpha colors.number "40";
            }
          ];

          # Syntax highlighting
          syntax = {
            attribute = {
              color = withAlpha colors.cursor "ff";
              font_style = null;
              font_weight = null;
            };
            boolean = {
              color = withAlpha colors.warning "ff";
              font_style = null;
              font_weight = null;
            };
            comment = {
              color = withAlpha colors.fg-dim "ff";
              font_style = "italic";
              font_weight = null;
            };
            "comment.doc" = {
              color = withAlpha colors.fg-alt "ff";
              font_style = "italic";
              font_weight = null;
            };
            constant = {
              color = withAlpha colors.warning "ff";
              font_style = null;
              font_weight = null;
            };
            constructor = {
              color = withAlpha colors.cursor "ff";
              font_style = null;
              font_weight = null;
            };
            embedded = {
              color = withAlpha colors.fg "ff";
              font_style = null;
              font_weight = null;
            };
            emphasis = {
              color = withAlpha colors.cursor "ff";
              font_style = "italic";
              font_weight = null;
            };
            "emphasis.strong" = {
              color = withAlpha colors.warning "ff";
              font_style = null;
              font_weight = 700;
            };
            enum = {
              color = withAlpha colors.error "ff";
              font_style = null;
              font_weight = null;
            };
            function = {
              color = withAlpha colors.cursor "ff";
              font_style = null;
              font_weight = null;
            };
            hint = {
              color = withAlpha colors.cursor "ff";
              font_style = null;
              font_weight = null;
            };
            keyword = {
              color = withAlpha colors.keyword "ff";
              font_style = null;
              font_weight = null;
            };
            label = {
              color = withAlpha colors.cursor "ff";
              font_style = null;
              font_weight = null;
            };
            link_text = {
              color = withAlpha colors.cursor "ff";
              font_style = "normal";
              font_weight = null;
            };
            link_uri = {
              color = withAlpha categorical."data-viz-08" "ff";
              font_style = null;
              font_weight = null;
            };
            namespace = {
              color = withAlpha colors.fg "ff";
              font_style = null;
              font_weight = null;
            };
            number = {
              color = withAlpha colors.warning "ff";
              font_style = null;
              font_weight = null;
            };
            operator = {
              color = withAlpha categorical."data-viz-08" "ff";
              font_style = null;
              font_weight = null;
            };
            predictive = {
              color = withAlpha colors.fg-alt "ff";
              font_style = "italic";
              font_weight = null;
            };
            preproc = {
              color = withAlpha colors.fg "ff";
              font_style = null;
              font_weight = null;
            };
            primary = {
              color = withAlpha colors.fg "ff";
              font_style = null;
              font_weight = null;
            };
            property = {
              color = withAlpha colors.error "ff";
              font_style = null;
              font_weight = null;
            };
            punctuation = {
              color = withAlpha colors.fg-alt "ff";
              font_style = null;
              font_weight = null;
            };
            "punctuation.bracket" = {
              color = withAlpha colors.fg-alt "ff";
              font_style = null;
              font_weight = null;
            };
            "punctuation.delimiter" = {
              color = withAlpha colors.fg-alt "ff";
              font_style = null;
              font_weight = null;
            };
            "punctuation.list_marker" = {
              color = withAlpha colors.fg-alt "ff";
              font_style = null;
              font_weight = null;
            };
            "punctuation.special" = {
              color = withAlpha colors.fg-alt "ff";
              font_style = null;
              font_weight = null;
            };
            string = {
              color = withAlpha colors.function "ff";
              font_style = null;
              font_weight = null;
            };
            "string.escape" = {
              color = withAlpha categorical."data-viz-08" "ff";
              font_style = null;
              font_weight = null;
            };
            "string.regex" = {
              color = withAlpha categorical."data-viz-08" "ff";
              font_style = null;
              font_weight = null;
            };
            "string.special" = {
              color = withAlpha categorical."data-viz-08" "ff";
              font_style = null;
              font_weight = null;
            };
            "string.special.symbol" = {
              color = withAlpha categorical."data-viz-08" "ff";
              font_style = null;
              font_weight = null;
            };
            tag = {
              color = withAlpha colors.error "ff";
              font_style = null;
              font_weight = null;
            };
            "text.literal" = {
              color = withAlpha colors.function "ff";
              font_style = null;
              font_weight = null;
            };
            title = {
              color = withAlpha colors.error "ff";
              font_style = null;
              font_weight = 700;
            };
            type = {
              color = withAlpha colors.type "ff";
              font_style = null;
              font_weight = null;
            };
            variable = {
              color = withAlpha colors.fg "ff";
              font_style = null;
              font_weight = null;
            };
            "variable.special" = {
              color = withAlpha colors.keyword "ff";
              font_style = null;
              font_weight = null;
            };
            variant = {
              color = withAlpha colors.type "ff";
              font_style = null;
              font_weight = null;
            };
          };
        };
      }
    ];
  };

  # Check if Zed should be themed - using centralized helper
  shouldTheme = signalLib.shouldThemeApp "zed-editor" [
    "editors"
    "zed"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.zed-editor = {
      themes."signal-${themeMode}" = zedTheme;

      userSettings.theme = {
        mode = "system";
        light = "Signal Light";
        dark = "Signal Dark";
      };
    };
  };
}
