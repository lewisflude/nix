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
# CONFIGURATION METHOD: structured-config (Tier 2)
# HOME-MANAGER MODULE: qt.enable, qt.style, qt.kde.settings
# UPSTREAM SCHEMA: https://doc.qt.io/qt-6/qpalette.html (Qt Palette)
#                  https://develop.kde.org/docs/plasma/theme/colors/ (KDE Colors)
# SCHEMA VERSION: Qt 5.15 / Qt 6.7 / KDE Plasma 6
# LAST VALIDATED: 2026-01-17
# NOTES: Qt theming uses Adwaita-qt style for consistency with GTK.
#        KDE color schemes are configured via kdeglobals using RGB values.
#        Home-Manager provides qt.style for theme and qt.kde.settings for colors.
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Use semantic bridge for color resolution
  colors = {
    surface-base = semantic.core "background" themeMode;
    surface-subtle = semantic.ui "panel-background" themeMode;
    surface-emphasis = semantic.ui "element-hover" themeMode;
    text-primary = semantic.core "foreground" themeMode;
    text-secondary = semantic.text "secondary" themeMode;
    text-tertiary = semantic.text "tertiary" themeMode;
    divider-primary = semantic.ui "panel-border" themeMode;
    divider-secondary = semantic.ui "element-active" themeMode;
  };

  # Accent colors
  accent = {
    secondary = semantic.core "focus" themeMode;
    tertiary = semantic.status "info" themeMode;
  };

  # Helper to convert color to RGB format for KDE (comma-separated)
  toRgb = signalLib.hexToRgbCommaSeparated;

  # Check if qt should be themed
  # Note: We only check cfg.qt.enable, not config.qt.enable, to avoid infinite recursion
  # Users must explicitly enable Signal Qt theming or use autoEnable
  shouldTheme = cfg.qt.enable;
in
{
  config = mkIf (cfg.enable && shouldTheme) {
    qt = {
      # Use Adwaita style to match GTK theming
      style = {
        name = if themeMode == "light" then "adwaita" else "adwaita-dark";
        package = pkgs.adwaita-qt;
      };

      # Set platform theme to use Adwaita integration
      platformTheme.name = "adwaita";

      # Configure KDE color scheme via kdeglobals
      # This applies colors to KDE/Qt applications that respect KDE color schemes
      kde.settings = {
        kdeglobals = {
          # General color scheme identification
          General = {
            ColorScheme = if themeMode == "light" then "SignalLight" else "SignalDark";
            Name = if themeMode == "light" then "Signal Light" else "Signal Dark";
          };

          # Window colors (main application background/foreground)
          "Colors:Window" = {
            BackgroundNormal = toRgb colors.surface-base;
            BackgroundAlternate = toRgb colors.surface-subtle;
            ForegroundNormal = toRgb colors.text-primary;
            ForegroundInactive = toRgb colors.text-secondary;
            ForegroundActive = toRgb accent.secondary;
            ForegroundLink = toRgb accent.secondary;
            ForegroundVisited = toRgb accent.tertiary;
            DecorationHover = toRgb colors.surface-emphasis;
            DecorationFocus = toRgb accent.secondary;
          };

          # View colors (content areas like text editors, lists)
          "Colors:View" = {
            BackgroundNormal = toRgb colors.surface-base;
            BackgroundAlternate = toRgb colors.surface-subtle;
            ForegroundNormal = toRgb colors.text-primary;
            ForegroundInactive = toRgb colors.text-secondary;
            ForegroundActive = toRgb accent.secondary;
            ForegroundLink = toRgb accent.secondary;
            ForegroundVisited = toRgb accent.tertiary;
            DecorationHover = toRgb colors.surface-emphasis;
            DecorationFocus = toRgb accent.secondary;
          };

          # Button colors
          "Colors:Button" = {
            BackgroundNormal = toRgb colors.surface-subtle;
            BackgroundAlternate = toRgb colors.surface-emphasis;
            ForegroundNormal = toRgb colors.text-primary;
            ForegroundInactive = toRgb colors.text-secondary;
            ForegroundActive = toRgb accent.secondary;
            DecorationHover = toRgb colors.surface-emphasis;
            DecorationFocus = toRgb accent.secondary;
          };

          # Selection colors
          "Colors:Selection" = {
            BackgroundNormal = toRgb accent.secondary;
            BackgroundAlternate = toRgb accent.secondary;
            ForegroundNormal = toRgb colors.surface-base;
            ForegroundInactive = toRgb colors.text-tertiary;
            ForegroundActive = toRgb colors.surface-base;
            DecorationHover = toRgb accent.secondary;
            DecorationFocus = toRgb accent.secondary;
          };

          # Tooltip colors
          "Colors:Tooltip" = {
            BackgroundNormal = toRgb colors.surface-emphasis;
            BackgroundAlternate = toRgb colors.surface-subtle;
            ForegroundNormal = toRgb colors.text-primary;
            ForegroundInactive = toRgb colors.text-secondary;
            ForegroundActive = toRgb accent.secondary;
            DecorationHover = toRgb colors.surface-emphasis;
            DecorationFocus = toRgb accent.secondary;
          };

          # Complementary colors (sidebars, headers)
          "Colors:Complementary" = {
            BackgroundNormal = toRgb colors.surface-subtle;
            BackgroundAlternate = toRgb colors.surface-emphasis;
            ForegroundNormal = toRgb colors.text-primary;
            ForegroundInactive = toRgb colors.text-secondary;
            ForegroundActive = toRgb accent.secondary;
            DecorationHover = toRgb colors.surface-emphasis;
            DecorationFocus = toRgb accent.secondary;
          };

          # Header colors (title bars, etc.)
          "Colors:Header" = {
            BackgroundNormal = toRgb colors.surface-base;
            BackgroundAlternate = toRgb colors.surface-subtle;
            ForegroundNormal = toRgb colors.text-primary;
            ForegroundInactive = toRgb colors.text-secondary;
            ForegroundActive = toRgb accent.secondary;
            DecorationHover = toRgb colors.surface-emphasis;
            DecorationFocus = toRgb accent.secondary;
          };

          # Window Manager colors
          WM = {
            activeBackground = toRgb colors.surface-base;
            activeForeground = toRgb colors.text-primary;
            inactiveBackground = toRgb colors.surface-base;
            inactiveForeground = toRgb colors.text-secondary;
            activeBlend = toRgb accent.secondary;
            inactiveBlend = toRgb colors.divider-secondary;
          };

          # Color Effects for disabled/inactive states
          "ColorEffects:Disabled" = {
            # Reduce contrast for disabled state
            Color = toRgb colors.text-tertiary;
            ColorAmount = "0.3";
            ColorEffect = "2"; # Desaturate
            ContrastAmount = "0.4";
            ContrastEffect = "1"; # Fade
            IntensityAmount = "0.1";
            IntensityEffect = "0"; # None
          };

          "ColorEffects:Inactive" = {
            # Slightly reduce vibrancy for inactive windows
            Color = toRgb colors.text-secondary;
            ColorAmount = "0.1";
            ColorEffect = "2"; # Desaturate
            ContrastAmount = "0.1";
            ContrastEffect = "1"; # Fade
            IntensityAmount = "0.0";
            IntensityEffect = "0"; # None
          };
        };
      };
    };
  };
}
