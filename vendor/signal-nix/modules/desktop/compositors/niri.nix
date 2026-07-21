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
# CONFIGURATION METHOD: freeform-settings (Tier 3) + KDL export
# HOME-MANAGER MODULE: programs.niri.settings + custom KDL generation
# UPSTREAM SCHEMA: https://github.com/YaLTeR/niri/wiki/Configuration:-Overview
# SCHEMA VERSION: 0.1.x
# LAST VALIDATED: 2026-02-02
# NOTES: Niri uses KDL (KDL Document Language) for configuration. This module generates
#        both native settings via programs.niri.settings and KDL color files for
#        DankMaterialShell (DMS) integration. Colors use Signal's OKLCH-based palette
#        with semantic bridge mappings for scientific color accuracy.
let
  inherit (lib)
    mkIf
    mkOption
    types
    mkDefault
    ;
  cfg = config.theming.signal;
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Niri uses hex color format: "#RRGGBB"
  # Signal colors already provide .hex field
  toNiriColor = color: color.hex;

  # Semantic color mappings for Niri compositor
  colors = {
    # Core UI colors
    background = semantic.core "background" themeMode;
    foreground = semantic.core "foreground" themeMode;

    # UI component colors
    backdrop = semantic.ui "panel-background" themeMode;
    border = semantic.ui "panel-border" themeMode;
    borderActive = semantic.vcs "modified" themeMode;
    focus = semantic.core "focus" themeMode;
    hover = semantic.ui "element-hover" themeMode;

    # Status indicator colors
    error = semantic.status "error" themeMode;
    warning = semantic.status "warning" themeMode;
    success = semantic.status "success" themeMode;
    info = semantic.status "info" themeMode;

    # Window state colors
    inactive = semantic.ui "panel-border" themeMode;
    urgent = semantic.status "error" themeMode;

    # Shadow colors (semi-transparent)
    shadow = semantic.ui "panel-background" themeMode;
  };

  # Generate KDL format color definitions for DMS integration
  # This follows the DMS colors.kdl structure for compatibility
  colorsKdl = ''
    // Signal Design System Colors for Niri
    // Generated from signal-nix semantic bridge
    // Mode: ${themeMode}

    // Core layout colors
    layout {
        background-color "transparent"

        focus-ring {
            active-color   "${toNiriColor colors.focus}"
            inactive-color "${toNiriColor colors.inactive}"
            urgent-color   "${toNiriColor colors.urgent}"
        }

        border {
            active-color   "${toNiriColor colors.borderActive}"
            inactive-color "${toNiriColor colors.inactive}"
            urgent-color   "${toNiriColor colors.urgent}"
        }

        shadow {
            color "${toNiriColor colors.shadow}70"
        }

        tab-indicator {
            active-color   "${toNiriColor colors.focus}"
            inactive-color "${toNiriColor colors.inactive}"
            urgent-color   "${toNiriColor colors.urgent}"
        }

        insert-hint {
            color "${toNiriColor colors.info}80"
        }
    }

    // Recent windows (Alt-Tab) colors
    recent-windows {
        highlight {
            active-color   "${toNiriColor colors.focus}"
            urgent-color   "${toNiriColor colors.urgent}"
        }
    }
  '';

  # Check if Niri should be themed
  shouldTheme = signalLib.shouldThemeApp "niri" [
    "desktop"
    "compositors"
    "niri"
  ] cfg config;

  # Platform guard - Niri is Linux-only (Wayland compositor)
  platformOk = signalLib.platform.guard pkgs "niri";
in
{
  options.theming.signal.desktop.compositors.niri = {
    enable = lib.mkEnableOption "Signal theme for Niri compositor";

    exportKdl = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Export colors in KDL format for DankMaterialShell (DMS) integration.
        When enabled, generates a colors.kdl file compatible with DMS includes.
      '';
    };
  };

  config = mkIf (cfg.enable && shouldTheme && platformOk) {
    # Export colors for external access
    theming.signal.colors.niri = {
      inherit colors;
      kdl = colorsKdl;
      kdlFile = pkgs.writeText "signal-niri-colors.kdl" colorsKdl;
    };

    # Configure Niri native settings
    programs.niri.settings = {
      # Overview backdrop color
      overview = {
        backdrop-color = mkDefault (toNiriColor colors.backdrop);
      };

      # Optional: Additional color settings if not managed by DMS
      # Uncomment if you want signal-nix to fully control Niri colors
      # layout = {
      #   border = {
      #     active-color = mkDefault (toNiriColor colors.borderActive);
      #     inactive-color = mkDefault (toNiriColor colors.inactive);
      #   };
      #   focus-ring = {
      #     active-color = mkDefault (toNiriColor colors.focus);
      #     inactive-color = mkDefault (toNiriColor colors.inactive);
      #   };
      # };
    };

    # Export KDL file for DMS integration if enabled
    xdg.configFile."niri/dms/signal-colors.kdl" = mkIf cfg.desktop.compositors.niri.exportKdl {
      source = config.theming.signal.colors.niri.kdlFile;
    };
  };
}
