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
# HOME-MANAGER MODULE: xdg.configFile (custom theme file)
# UPSTREAM SCHEMA: https://github.com/aristocratos/btop#themes
# SCHEMA VERSION: 1.3.0
# LAST VALIDATED: 2026-01-17
# NOTES: Btop requires theme files in custom format at ~/.config/btop/themes/.
#        Home-Manager's programs.btop.settings doesn't support inline theme definition.
#        We generate theme file and link it via xdg.configFile.
let
  inherit (lib) mkIf removePrefix;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for color resolution
  colors = {
    surface-base = semantic.ui "panel-background" themeMode;
    text-primary = semantic.core "foreground" themeMode;
    text-secondary = semantic.text "secondary" themeMode;
    text-tertiary = semantic.text "tertiary" themeMode;
    divider-primary = semantic.ui "panel-border" themeMode;

    # Accent colors for status indicators
    accent-primary = semantic.status "success" themeMode;
    accent-secondary = semantic.core "focus" themeMode;
    accent-tertiary = semantic.syntax "keyword" themeMode;
    accent-warning = semantic.status "warning" themeMode;
    accent-danger = semantic.status "error" themeMode;

    # Categorical colors for data visualization
    data-viz-02 = semantic.multiplayer "player-2" themeMode;
    data-viz-06 = semantic.multiplayer "player-6" themeMode;
  };

  # Helper to get hex without # prefix
  hexRaw = color: removePrefix "#" color.hex;

  # Generate btop theme file
  btopTheme = pkgs.writeText "signal.theme" ''
    # Signal Theme for btop++
    # Generated from Signal Design System

    # Main background
    theme[main_bg]="${hexRaw colors.surface-base}"

    # Main text color
    theme[main_fg]="${hexRaw colors.text-primary}"

    # Title color for boxes
    theme[title]="${hexRaw colors.text-primary}"

    # Highlight color for keyboard shortcuts
    theme[hi_fg]="${hexRaw colors.accent-secondary}"

    # Background color of selected items
    theme[selected_bg]="${hexRaw colors.divider-primary}"

    # Foreground color of selected items
    theme[selected_fg]="${hexRaw colors.text-primary}"

    # Color of inactive/disabled text
    theme[inactive_fg]="${hexRaw colors.text-tertiary}"

    # Color of text appearing on top of graphs
    theme[graph_text]="${hexRaw colors.text-secondary}"

    # Misc colors for processes box
    theme[proc_misc]="${hexRaw colors.accent-primary}"

    # Box outline colors
    theme[cpu_box]="${hexRaw colors.divider-primary}"
    theme[mem_box]="${hexRaw colors.divider-primary}"
    theme[net_box]="${hexRaw colors.divider-primary}"
    theme[proc_box]="${hexRaw colors.divider-primary}"

    # Box divider line and small boxes line color
    theme[div_line]="${hexRaw colors.divider-primary}"

    # Temperature graph colors (green -> yellow -> red)
    theme[temp_start]="${hexRaw colors.accent-primary}"
    theme[temp_mid]="${hexRaw colors.accent-warning}"
    theme[temp_end]="${hexRaw colors.accent-danger}"

    # CPU graph colors (blue gradient)
    theme[cpu_start]="${hexRaw colors.accent-secondary}"
    theme[cpu_mid]="${hexRaw colors.accent-secondary}"
    theme[cpu_end]="${hexRaw colors.accent-tertiary}"

    # Mem/Disk free meter (red -> yellow -> green)
    theme[free_start]="${hexRaw colors.accent-danger}"
    theme[free_mid]="${hexRaw colors.accent-warning}"
    theme[free_end]="${hexRaw colors.accent-primary}"

    # Mem/Disk cached meter (blue gradient)
    theme[cached_start]="${hexRaw colors.accent-secondary}"
    theme[cached_mid]="${hexRaw colors.accent-secondary}"
    theme[cached_end]="${hexRaw colors.accent-primary}"

    # Mem/Disk available meter (purple gradient)
    theme[available_start]="${hexRaw colors.accent-tertiary}"
    theme[available_mid]="${hexRaw colors.data-viz-06}"
    theme[available_end]="${hexRaw colors.accent-warning}"

    # Mem/Disk used meter (green -> yellow -> red)
    theme[used_start]="${hexRaw colors.accent-primary}"
    theme[used_mid]="${hexRaw colors.accent-warning}"
    theme[used_end]="${hexRaw colors.accent-danger}"

    # Download graph colors (green gradient)
    theme[download_start]="${hexRaw colors.accent-primary}"
    theme[download_mid]="${hexRaw colors.data-viz-02}"
    theme[download_end]="${hexRaw colors.accent-secondary}"

    # Upload graph colors (red gradient)
    theme[upload_start]="${hexRaw colors.accent-danger}"
    theme[upload_mid]="${hexRaw colors.accent-warning}"
    theme[upload_end]="${hexRaw colors.data-viz-06}"

    # Process box color gradient
    theme[process_start]="${hexRaw colors.accent-secondary}"
    theme[process_mid]="${hexRaw colors.accent-warning}"
    theme[process_end]="${hexRaw colors.accent-danger}"
  '';

  # Check if btop should be themed
  # Check if btop should be themed - using centralized helper
  shouldTheme = signalLib.shouldThemeApp "btop" [
    "monitors"
    "btop"
  ] cfg config;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    programs.btop = {
      settings = {
        # Set theme name
        color_theme = "signal";

        # Theme override using extraConfig
        # This creates a custom theme in the btop config
        theme_background = false; # Use terminal background
      };

      # Link the theme file
      # btop looks for themes in ~/.config/btop/themes/
      extraConfig = ''
        # Signal theme is defined via file in themes directory
      '';
    };

    # Create the theme file in the correct location
    xdg.configFile."btop/themes/signal.theme".source = btopTheme;
  };
}
