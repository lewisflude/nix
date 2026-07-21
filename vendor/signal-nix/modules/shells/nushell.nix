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
# CONFIGURATION METHOD: raw-config (Tier 4)
# HOME-MANAGER MODULE: programs.nushell.extraConfig
# UPSTREAM SCHEMA: https://www.nushell.sh/
# SCHEMA VERSION: 0.89.0
# LAST VALIDATED: 2026-01-17
# NOTES: nushell uses Nushell language for config. Home-Manager provides
#        extraConfig for custom settings. We configure color_config.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for color resolution
  colors = {
    surface-base = semantic.ui "panel-background" themeMode;
    text-primary = semantic.core "foreground" themeMode;
    text-secondary = semantic.text "secondary" themeMode;
    text-dim = semantic.text "tertiary" themeMode;
    divider = semantic.ui "panel-border" themeMode;
  };

  inherit (signalPalette) accent;

  # nushell uses hex colors with #
  # Generate nushell color config
  nushellConfig = ''
    # Signal theme for nushell

    $env.config = {
      color_config: {
        # Primitive types
        separator: "${colors.divider.hex}"
        leading_trailing_space_bg: { attr: n }
        header: { fg: "${accent.secondary.Lc75.hex}" attr: b }
        empty: "${accent.secondary.Lc75.hex}"
        bool: "${accent.secondary.Lc75.hex}"
        int: "${colors.text-primary.hex}"
        filesize: "${accent.secondary.Lc75.hex}"
        duration: "${colors.text-secondary.hex}"
        date: "${accent.tertiary.Lc75.hex}"
        range: "${colors.text-secondary.hex}"
        float: "${colors.text-primary.hex}"
        string: "${accent.primary.Lc75.hex}"
        nothing: "${colors.text-dim.hex}"
        binary: "${accent.tertiary.Lc75.hex}"
        cellpath: "${colors.text-secondary.hex}"
        row_index: { fg: "${accent.secondary.Lc75.hex}" attr: b }
        record: "${colors.text-primary.hex}"
        list: "${colors.text-primary.hex}"
        block: "${colors.text-secondary.hex}"
        hints: "${colors.text-dim.hex}"

        # Shapes (syntax highlighting)
        shape_garbage: { fg: "${accent.danger.Lc75.hex}" attr: b }
        shape_binary: "${accent.tertiary.Lc75.hex}"
        shape_bool: "${accent.secondary.Lc75.hex}"
        shape_int: "${colors.text-primary.hex}"
        shape_float: "${colors.text-primary.hex}"
        shape_range: "${colors.text-secondary.hex}"
        shape_internalcall: "${accent.secondary.Lc75.hex}"
        shape_external: "${accent.primary.Lc75.hex}"
        shape_externalarg: "${colors.text-primary.hex}"
        shape_literal: "${accent.secondary.Lc75.hex}"
        shape_operator: "${accent.warning.Lc75.hex}"
        shape_signature: { fg: "${accent.secondary.Lc75.hex}" attr: b }
        shape_string: "${accent.primary.Lc75.hex}"
        shape_string_interpolation: "${accent.secondary.Lc75.hex}"
        shape_datetime: "${accent.tertiary.Lc75.hex}"
        shape_list: "${colors.text-secondary.hex}"
        shape_table: "${colors.text-primary.hex}"
        shape_record: "${colors.text-primary.hex}"
        shape_block: "${colors.text-secondary.hex}"
        shape_filepath: "${accent.secondary.Lc75.hex}"
        shape_directory: { fg: "${accent.secondary.Lc75.hex}" attr: b }
        shape_globpattern: "${accent.secondary.Lc75.hex}"
        shape_variable: "${accent.tertiary.Lc75.hex}"
        shape_flag: { fg: "${accent.secondary.Lc75.hex}" attr: b }
        shape_custom: "${accent.primary.Lc75.hex}"
        shape_nothing: "${colors.text-dim.hex}"
      }
    }
  '';

  # Check if nushell should be themed
  shouldTheme = signalLib.shouldThemeApp "nushell" [
    "shells"
    "nushell"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.nushell.extraConfig = nushellConfig;
  };
}
