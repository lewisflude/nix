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
# CONFIGURATION METHOD: json-config (Tier 2)
# HOME-MANAGER MODULE: xdg.configFile
# UPSTREAM SCHEMA: https://github.com/charmbracelet/glow
# SCHEMA VERSION: 1.5.1
# LAST VALIDATED: 2026-01-17
# NOTES: glow uses JSON config for custom styles. We create a glamour theme.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Glow uses glamour JSON theme format - use semantic bridge for all colors
  glowTheme = builtins.toJSON {
    document = {
      background_color = (semantic.ui "panel-background" themeMode).hex;
      color = (semantic.text "primary" themeMode).hex;
    };

    heading = {
      color = (semantic.markup "heading" themeMode).hex;
      bold = true;
    };

    h1 = {
      prefix = "# ";
      color = (semantic.markup "heading" themeMode).hex;
      bold = true;
    };

    h2 = {
      prefix = "## ";
      color = (semantic.markup "heading" themeMode).hex;
    };

    h3 = {
      prefix = "### ";
      color = (semantic.markup "heading" themeMode).hex;
    };

    h4 = {
      prefix = "#### ";
      color = (semantic.markup "heading" themeMode).hex;
    };

    h5 = {
      prefix = "##### ";
      color = (semantic.text "secondary" themeMode).hex;
    };

    h6 = {
      prefix = "###### ";
      color = (semantic.text "secondary" themeMode).hex;
    };

    text = {
      color = (semantic.text "primary" themeMode).hex;
    };

    paragraph = {
      color = (semantic.text "primary" themeMode).hex;
    };

    code = {
      color = (semantic.markup "code" themeMode).hex;
      background_color = (semantic.markup "code-block" themeMode).hex;
    };

    code_block = {
      color = (semantic.markup "code" themeMode).hex;
      background_color = (semantic.markup "code-block" themeMode).hex;
    };

    emph = {
      color = (semantic.markup "italic" themeMode).hex;
      italic = true;
    };

    strong = {
      color = (semantic.markup "bold" themeMode).hex;
      bold = true;
    };

    strikethrough = {
      color = (semantic.text "disabled" themeMode).hex;
      crossed_out = true;
    };

    link = {
      color = (semantic.markup "link" themeMode).hex;
      underline = true;
    };

    link_text = {
      color = (semantic.markup "link" themeMode).hex;
    };

    image = {
      color = (semantic.syntax "keyword" themeMode).hex;
    };

    list = {
      color = (semantic.text "primary" themeMode).hex;
    };

    enumeration = {
      color = (semantic.text "primary" themeMode).hex;
    };

    item = {
      color = (semantic.text "primary" themeMode).hex;
    };

    task = {
      ticked = "[✓] ";
      unticked = "[ ] ";
    };

    table = {
      color = (semantic.text "primary" themeMode).hex;
    };

    table_header = {
      color = (semantic.markup "heading" themeMode).hex;
      bold = true;
    };

    table_row = {
      color = (semantic.text "primary" themeMode).hex;
    };

    quote = {
      color = (semantic.markup "quote" themeMode).hex;
      italic = true;
    };

    quote_block = {
      color = (semantic.markup "quote" themeMode).hex;
      indent = 2;
    };

    hr = {
      color = (semantic.ui "panel-border" themeMode).hex;
    };
  };

  # Check if glow should be themed
  shouldTheme = cfg.cli.glow.enable or false || cfg.autoEnable;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    xdg.configFile."glow/signal.json".text = glowTheme;

    # Set glow to use Signal theme by default
    home.sessionVariables = mkIf shouldTheme {
      GLOW_STYLE = "$HOME/.config/glow/signal.json";
    };
  };
}
