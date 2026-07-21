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
# CONFIGURATION METHOD: structured-settings (Tier 2)
# HOME-MANAGER MODULE: programs.tealdeer.settings.style
# UPSTREAM SCHEMA: https://dbrgn.github.io/tealdeer/config.html
# SCHEMA VERSION: 1.7.1
# LAST VALIDATED: 2026-01-18
# NOTES: Tealdeer uses TOML config with style section for coloring tldr pages.
#        Supports foreground/background colors with bold/underline modifiers.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Check if tealdeer should be themed - using centralized helper
  shouldTheme = signalLib.shouldThemeApp "tealdeer" [
    "cli"
    "tealdeer"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.tealdeer = {
      settings = {
        style = {
          # Command name - prominent, bold header - using semantic bridge
          command_name = {
            foreground = (semantic.markup "heading" themeMode).hex;
            bold = true;
          };

          # Description text - main content, clear and readable
          description = {
            foreground = (semantic.text "primary" themeMode).hex;
          };

          # Example text - the command examples
          example_text = {
            foreground = (semantic.text "secondary" themeMode).hex;
          };

          # Example variables - placeholders in examples like <file>
          example_variable = {
            foreground = (semantic.syntax "variable" themeMode).hex;
            bold = true;
          };

          # Example code - the actual command being shown
          example_code = {
            foreground = (semantic.markup "code" themeMode).hex;
          };
        };
      };
    };
  };
}
