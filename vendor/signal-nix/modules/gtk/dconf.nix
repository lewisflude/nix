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
# CONFIGURATION METHOD: structured-colors (Tier 2)
# HOME-MANAGER MODULE: dconf.settings
# UPSTREAM SCHEMA: GSettings schemas from GNOME/GTK
# SCHEMA VERSION: GNOME 47 / GTK 4.16
# LAST VALIDATED: 2026-01-22
# NOTES: Provides behavioral dconf settings that complement Signal's GTK visual theming.
#        These settings control interface behavior, font rendering, and system preferences
#        rather than colors (which are handled by the main GTK module).
#
#        This module is automatically enabled when GTK theming is enabled and provides
#        sensible defaults that integrate with Signal's design philosophy.
let
  inherit (lib) mkIf mkOption types;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Check if gtk theming is active (same logic as main GTK module)
  shouldTheme = cfg.gtk.enable || (cfg.autoEnable && (config.gtk.enable or false));
in
{
  options.theming.signal.gtk = {
    dconf = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable Signal dconf behavioral settings for GTK applications.
          This complements the visual theming with interface behavior settings.

          Includes:
          - color-scheme preference (prefer-dark/prefer-light)
          - Font rendering settings (antialiasing, hinting)
          - Interface behaviors (animations, clock format)
          - Touchpad/mouse settings
        '';
      };

      clockFormat = mkOption {
        type = types.enum [
          "12h"
          "24h"
        ];
        default = "24h";
        description = "Clock format in GNOME applications";
      };

      clockShowWeekday = mkOption {
        type = types.bool;
        default = false;
        description = "Show weekday in GNOME clock";
      };

      enableAnimations = mkOption {
        type = types.bool;
        default = true;
        description = "Enable GTK animations";
      };

      fontAntialiasing = mkOption {
        type = types.enum [
          "none"
          "grayscale"
          "rgba"
        ];
        default = "rgba";
        description = "Font antialiasing method (rgba recommended for LCD monitors)";
      };

      fontHinting = mkOption {
        type = types.enum [
          "none"
          "slight"
          "medium"
          "full"
        ];
        default = "slight";
        description = "Font hinting strength (slight recommended for modern fonts)";
      };

      touchpad = {
        tapToClick = mkOption {
          type = types.bool;
          default = true;
          description = "Enable tap-to-click on touchpad";
        };

        clickMethod = mkOption {
          type = types.enum [
            "default"
            "none"
            "areas"
            "fingers"
          ];
          default = "fingers";
          description = "Touchpad click method (fingers = two-finger right-click)";
        };

        naturalScroll = mkOption {
          type = types.bool;
          default = false;
          description = "Enable natural (reversed) scrolling";
        };
      };

      nightLight = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enable Night Light (blue light filter)";
        };

        temperature = mkOption {
          type = types.int;
          default = 4500;
          description = "Night Light color temperature in Kelvin (2700-6500)";
        };
      };
    };
  };

  config = mkIf (cfg.enable && shouldTheme && cfg.gtk.dconf.enable) {
    dconf.settings = {
      # ============================================
      # Core Interface Settings
      # ============================================
      "org/gnome/desktop/interface" = {
        # Color scheme preference - tells GTK apps whether to use light or dark variants
        # This is the standard FreeDesktop Dark Style Preference
        color-scheme = if themeMode == "light" then "prefer-light" else "prefer-dark";

        # Clock settings
        clock-format = cfg.gtk.dconf.clockFormat;
        clock-show-weekday = cfg.gtk.dconf.clockShowWeekday;

        # Animation settings
        enable-animations = cfg.gtk.dconf.enableAnimations;

        # Font rendering
        font-antialiasing = cfg.gtk.dconf.fontAntialiasing;
        font-hinting = cfg.gtk.dconf.fontHinting;
      };

      # ============================================
      # Touchpad Settings
      # ============================================
      "org/gnome/desktop/peripherals/touchpad" = {
        tap-to-click = cfg.gtk.dconf.touchpad.tapToClick;
        click-method = cfg.gtk.dconf.touchpad.clickMethod;
        natural-scroll = cfg.gtk.dconf.touchpad.naturalScroll;
      };

      # ============================================
      # Night Light (Blue Light Filter)
      # ============================================
      "org/gnome/settings-daemon/plugins/color" = mkIf cfg.gtk.dconf.nightLight.enable {
        night-light-enabled = true;
        night-light-temperature = lib.hm.gvariant.mkUint32 cfg.gtk.dconf.nightLight.temperature;
        # Note: night-light-schedule-automatic can be set to true to follow sunrise/sunset
        # but requires geolocation services, so we default to manual control
      };

      # ============================================
      # File Manager (Nautilus/GNOME Files)
      # ============================================
      "org/gnome/nautilus/preferences" = {
        # Show hidden files by default (common for developers)
        show-hidden-files = false;
        # Use list view by default (better for file management)
        default-folder-viewer = "list-view";
      };

      # ============================================
      # GNOME Text Editor
      # ============================================
      "org/gnome/TextEditor" = {
        # Use Signal's theme preference
        style-scheme = if themeMode == "light" then "classic" else "Adwaita-dark";
        # Show line numbers (useful for code snippets)
        show-line-numbers = true;
        # Highlight current line
        highlight-current-line = true;
      };
    };
  };
}
