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
# CONFIGURATION METHOD: freeform-settings (Tier 3)
# HOME-MANAGER MODULE: xdg.configFile
# UPSTREAM SCHEMA: https://github.com/gabm/Satty#configuration-file
# LAST VALIDATED: 2026-01-18
# NOTES: Satty is a screenshot annotation tool for Wayland
#        Uses TOML config with color palette for drawing tools
#        Colors are in hex format: "#RRGGBB"
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # =============================================================================
  # Color Definitions
  # =============================================================================
  #
  # Satty uses a color palette for annotation tools (brush, shapes, text, etc.)
  # We provide Signal colors that work well for annotation and visibility.
  #
  # The palette appears in the toolbar for quick selection.
  # Custom colors are available in the color picker as presets.
  # =============================================================================

  colors = {
    surface-base = semantic.core "background" themeMode;
    text-primary = semantic.core "foreground" themeMode;
    text-inverse = semantic.text "inverse" themeMode;
  };

  inherit (signalPalette) accent categorical;

  # =============================================================================
  # TOML Configuration Generator
  # =============================================================================

  # Build color palette with Signal colors
  # These colors are selected for high visibility and semantic meaning
  colorPalette = [
    accent.secondary.Lc75.hex # Blue - primary annotation color
    accent.danger.Lc75.hex # Red - important/error markings
    accent.warning.Lc75.hex # Yellow - warnings/highlights
    categorical.${themeMode}."data-viz-02".hex # Green - success/positive
    accent.tertiary.Lc75.hex # Purple - alternate highlighting
    categorical.${themeMode}."data-viz-08".hex # Cyan - info/notes
  ];

  # Custom colors available in picker (same as palette for consistency)
  customColors = colorPalette;

  # Generate TOML configuration
  sattyConfig = {
    general = {
      # Start in fullscreen for maximum annotation area
      fullscreen = true;

      # Exit after copy for quick workflow
      early-exit = false;

      # Exit after save-as dialog
      early-exit-save-as = false;

      # Rounded corners for shapes (0 = sharp corners)
      corner-roundness = 8;

      # Default tool on startup
      initial-tool = "brush";

      # Copy command for Wayland (wl-copy is standard)
      copy-command = "wl-copy";

      # Annotation size factor (affects brush size, line thickness, etc.)
      annotation-size-factor = 2;

      # Save screenshots to Pictures/Screenshots with timestamp
      output-filename = "~/Pictures/Screenshots/satty-%Y-%m-%d_%H:%M:%S.png";

      # Don't save to file after copying (user can trigger manually)
      save-after-copy = false;

      # Show toolbars by default
      default-hide-toolbars = false;

      # Focus toggles toolbars (experimental)
      focus-toggles-toolbars = false;

      # Don't fill shapes by default
      default-fill-shapes = false;

      # Use block highlighter as primary (freehand via Ctrl)
      primary-highlighter = "block";

      # Enable notifications
      disable-notifications = false;

      # Actions on Enter: copy to clipboard
      actions-on-enter = [ "save-to-clipboard" ];

      # Actions on Escape: exit
      actions-on-escape = [ "exit" ];

      # Actions on right click: empty (no action)
      actions-on-right-click = [ ];

      # Request no window decoration for clean interface
      no-window-decoration = true;

      # Brush smoothing (0 = disabled, 5-10 = smooth)
      brush-smooth-history-size = 5;

      # Pan step size for arrow keys (pixels)
      pan-step-size = 50.0;

      # Zoom factor (1.0 = no zoom, 1.1 = 10% zoom steps)
      zoom-factor = 1.1;

      # Text move length for arrow keys (pixels)
      text-move-length = 50.0;
    };

    # Tool selection keyboard shortcuts (using defaults)
    keybinds = {
      pointer = "p";
      crop = "c";
      brush = "b";
      line = "i";
      arrow = "z";
      rectangle = "r";
      ellipse = "e";
      text = "t";
      marker = "m";
      blur = "u";
      highlight = "g";
    };

    # Font configuration for text annotations
    font = {
      family = "Inter";
      style = "Regular";
    };

    # Color palette configuration
    color-palette = {
      # Toolbar palette for quick selection
      palette = colorPalette;

      # Custom colors in picker (same as palette)
      custom = customColors;
    };
  };

  # TOML format for Satty config
  tomlFormat = pkgs.formats.toml { };

  # Check if Satty should be themed
  shouldTheme = signalLib.shouldThemeApp "satty" [
    "apps"
    "satty"
  ] cfg config;

  # Platform guard - Satty is Linux-only (Wayland screenshot annotation)
  platformOk = signalLib.platform.guard pkgs "satty";
in
{
  # =============================================================================
  # Configuration
  # =============================================================================
  config = mkIf (cfg.enable && shouldTheme && platformOk) {
    # Create Satty config file at ~/.config/satty/config.toml
    xdg.configFile."satty/config.toml" = {
      source = tomlFormat.generate "satty-config.toml" sattyConfig;
    };
  };
}
