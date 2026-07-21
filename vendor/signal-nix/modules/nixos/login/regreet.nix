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
let
  inherit (lib) mkIf mkOption types;
  cfg = config.theming.signal.nixos;

  # Resolve theme mode
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Import the GTK theme package
  gtkTheme = pkgs.callPackage ../../../pkgs/gtk-theme {
    inherit signalLib;
    inherit (cfg) mode;
  };

  # Get colors for CSS
  colors = {
    background = (semantic.ui "panel-background" themeMode).hex;
    foreground = (semantic.text "primary" themeMode).hex;
    foreground-secondary = (semantic.text "secondary" themeMode).hex;
    surface = (semantic.ui "panel-background" themeMode).hex;
    surface-hover = (semantic.ui "element-hover" themeMode).hex;
    border = (semantic.ui "panel-border" themeMode).hex;
    accent = (semantic.getAccent "secondary" "Lc75").hex;
    error = (semantic.getAccent "danger" "Lc75").hex;
  };

  # Custom CSS for ReGreet with Signal colors
  signalCss = ''
    /* Signal Design System - ReGreet Theme (${themeMode} mode) */

    /* Main window background */
    window {
      background-color: ${colors.background};
    }

    /* Entry fields */
    entry {
      background-color: ${colors.surface};
      color: ${colors.foreground};
      border: 1px solid ${colors.border};
      border-radius: 6px;
      padding: 8px 12px;
    }

    entry:focus {
      border-color: ${colors.accent};
      box-shadow: 0 0 0 2px alpha(${colors.accent}, 0.3);
    }

    /* Buttons */
    button {
      background-color: ${colors.surface};
      color: ${colors.foreground};
      border: 1px solid ${colors.border};
      border-radius: 6px;
      padding: 8px 16px;
    }

    button:hover {
      background-color: ${colors.surface-hover};
    }

    button.suggested-action {
      background-color: ${colors.accent};
      color: ${colors.background};
      border-color: ${colors.accent};
    }

    button.destructive-action {
      background-color: ${colors.error};
      color: ${colors.background};
      border-color: ${colors.error};
    }

    /* Labels */
    label {
      color: ${colors.foreground};
    }

    label.dim-label {
      color: ${colors.foreground-secondary};
    }

    /* Combo boxes / dropdowns */
    combobox button {
      background-color: ${colors.surface};
      color: ${colors.foreground};
    }

    /* Messages */
    .error {
      color: ${colors.error};
    }
  '';

  # Determine if ReGreet should be themed
  shouldTheme =
    cfg.enable
    && (cfg.login.regreet.enable || (cfg.autoEnable && (config.programs.regreet.enable or false)));
in
{
  options.theming.signal.nixos.login.regreet = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Signal theme for ReGreet greeter";
    };

    backgroundImage = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Custom background image for ReGreet login screen.
        If not set, uses solid Signal colors.
      '';
      example = lib.literalExpression "./path/to/background.png";
    };
  };

  config = mkIf shouldTheme {
    # Install Signal GTK theme system-wide
    environment.systemPackages = [ gtkTheme ];

    # Configure ReGreet with Signal theme
    programs.regreet = {
      theme = {
        name = "Signal-${themeMode}";
        package = gtkTheme;
      };

      extraCss = signalCss;

      settings = {
        GTK = {
          application_prefer_dark_theme = themeMode == "dark";
          theme_name = "Signal-${themeMode}";
        };
      };
    };
  };
}
