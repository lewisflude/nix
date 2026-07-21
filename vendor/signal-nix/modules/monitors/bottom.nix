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
# CONFIGURATION METHOD: toml-config (Tier 2)
# HOME-MANAGER MODULE: programs.bottom (via xdg.configFile)
# UPSTREAM SCHEMA: https://github.com/ClementTsang/bottom
# SCHEMA VERSION: 0.9.6
# LAST VALIDATED: 2026-01-17
# NOTES: bottom (btm) uses TOML config. Home-Manager doesn't have a dedicated
#        module yet, so we use xdg.configFile to write the config.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for color resolution
  colors = {
    bg = semantic.ui "panel-background" themeMode;
    fg = semantic.core "foreground" themeMode;
    fg-alt = semantic.text "secondary" themeMode;
    fg-dim = semantic.text "tertiary" themeMode;
    border = semantic.ui "panel-border" themeMode;
  };

  inherit (signalPalette) accent categorical;

  # Generate bottom config in TOML format
  bottomConfig = ''
    # Signal theme for bottom

    [colors]
    # Widget styling
    border_color = "${colors.border.hex}"
    highlighted_border_color = "${accent.secondary.Lc75.hex}"
    text_color = "${colors.fg.hex}"
    selected_text_color = "${colors.fg.hex}"
    selected_bg_color = "${colors.border.hex}"
    widget_title_color = "${colors.fg.hex}"
    graph_color = "${accent.secondary.Lc75.hex}"

    # CPU colors
    cpu_core_colors = [
      "${accent.secondary.Lc75.hex}",
      "${accent.secondary.Lc75.hex}",
      "${accent.primary.Lc75.hex}",
      "${accent.warning.Lc75.hex}",
      "${accent.danger.Lc75.hex}",
      "${accent.tertiary.Lc75.hex}",
      "${categorical.${themeMode}."data-viz-02".hex}",
      "${categorical.${themeMode}."data-viz-04".hex}",
    ]

    # Memory/Swap colors
    ram_color = "${accent.secondary.Lc75.hex}"
    swap_color = "${accent.warning.Lc75.hex}"

    # Network colors
    rx_color = "${accent.primary.Lc75.hex}"
    tx_color = "${accent.danger.Lc75.hex}"

    # Battery colors
    high_battery_color = "${accent.primary.Lc75.hex}"
    medium_battery_color = "${accent.warning.Lc75.hex}"
    low_battery_color = "${accent.danger.Lc75.hex}"

    # Disk colors
    arc_color = "${accent.secondary.Lc75.hex}"

    # Temperature colors
    # These are gradients from cold to hot
    [[colors.temperature_colors]]
    temperature = 0
    color = "${accent.secondary.Lc75.hex}"

    [[colors.temperature_colors]]
    temperature = 50
    color = "${accent.primary.Lc75.hex}"

    [[colors.temperature_colors]]
    temperature = 70
    color = "${accent.warning.Lc75.hex}"

    [[colors.temperature_colors]]
    temperature = 90
    color = "${accent.danger.Lc75.hex}"
  '';

  # Check if bottom should be themed
  shouldTheme = cfg.monitors.bottom.enable or false || cfg.autoEnable;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    xdg.configFile."bottom/bottom.toml".text = bottomConfig;
  };
}
