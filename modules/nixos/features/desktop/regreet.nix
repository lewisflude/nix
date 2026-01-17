{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.features.desktop;

  # Import Signal theme if enabled
  signalThemeConfig = lib.optionalAttrs (config.host.features.desktop.signalTheme.enable or false) {
    inherit (config.host.features.desktop.signalTheme) signalLib signalColors;
  };

  # Custom CSS for ReGreet with Signal theme colors
  # Reference: https://docs.gtk.org/gtk4/css-properties.html
  customCss =
    if (config.host.features.desktop.signalTheme.enable or false) then
      let
        inherit (signalThemeConfig) signalColors;
        # Extract colors from Signal palette
        surfaceBase = signalColors.tonal."surface-subtle".hex;
        surfaceEmphasis = signalColors.tonal."surface-hover".hex;
        textPrimary = signalColors.tonal."text-primary".hex;
        textSecondary = signalColors.tonal."text-secondary".hex;
        accentFocus = signalColors.accent.secondary.Lc75.hex;
        accentDanger = signalColors.accent.danger.Lc75.hex;
      in
      ''
        /**
         * ReGreet Custom Styling - Signal Theme
         * Based on Signal Design System colors
         * Reference: https://github.com/rharish101/ReGreet
         * GTK4 CSS: https://docs.gtk.org/gtk4/css-properties.html
         */

        /* === WINDOW BACKGROUND === */
        window {
          background-color: ${surfaceBase};
        }

        /* === MAIN CONTAINER === */
        box {
          background-color: ${surfaceBase};
        }

        /* === LABELS & TEXT === */
        label {
          color: ${textPrimary};
        }

        /* Greeting message */
        #GreetingLabel {
          color: ${textPrimary};
          font-weight: bold;
          font-size: 1.5em;
          margin-bottom: 24px;
        }

        /* === INPUT FIELDS === */
        entry {
          background-color: ${surfaceEmphasis};
          color: ${textPrimary};
          border: 1px solid alpha(${textSecondary}, 0.2);
          border-radius: 8px;
          padding: 12px;
          margin: 8px 0;
          min-height: 42px;
        }

        entry:focus {
          border-color: ${accentFocus};
          box-shadow: 0 0 0 2px alpha(${accentFocus}, 0.2);
          outline: none;
        }

        entry:hover {
          border-color: alpha(${textPrimary}, 0.3);
        }

        entry placeholder {
          color: ${textSecondary};
          opacity: 0.7;
        }

        /* === BUTTONS === */
        button {
          background-color: ${accentFocus};
          color: ${surfaceBase};
          border: none;
          border-radius: 8px;
          padding: 12px 24px;
          margin: 8px 4px;
          font-weight: 600;
          min-height: 42px;
          transition: all 0.2s ease;
        }

        button:hover {
          background-color: alpha(${accentFocus}, 0.9);
          box-shadow: 0 2px 8px alpha(${accentFocus}, 0.3);
        }

        button:active {
          background-color: alpha(${accentFocus}, 0.8);
          box-shadow: 0 1px 4px alpha(${accentFocus}, 0.2);
        }

        button:focus {
          box-shadow: 0 0 0 3px alpha(${accentFocus}, 0.3);
          outline: none;
        }

        button:disabled {
          background-color: ${surfaceEmphasis};
          color: ${textSecondary};
          opacity: 0.5;
        }

        /* === SESSION SELECTOR === */
        combobox {
          background-color: ${surfaceEmphasis};
          color: ${textPrimary};
          border: 1px solid alpha(${textSecondary}, 0.2);
          border-radius: 8px;
          padding: 12px;
          margin: 8px 0;
          min-height: 42px;
        }

        combobox:hover {
          border-color: alpha(${textPrimary}, 0.3);
        }

        combobox:focus {
          border-color: ${accentFocus};
          box-shadow: 0 0 0 2px alpha(${accentFocus}, 0.2);
        }

        /* === DROPDOWN MENU === */
        popover {
          background-color: ${surfaceEmphasis};
          border: 1px solid alpha(${textSecondary}, 0.2);
          border-radius: 8px;
          padding: 4px;
          box-shadow: 0 4px 16px rgba(0, 0, 0, 0.3);
        }

        popover modelbutton {
          background-color: transparent;
          color: ${textPrimary};
          border-radius: 6px;
          padding: 10px 16px;
          margin: 2px;
        }

        popover modelbutton:hover {
          background-color: alpha(${accentFocus}, 0.15);
        }

        popover modelbutton:selected {
          background-color: ${accentFocus};
          color: ${surfaceBase};
        }

        /* === POWER BUTTONS === */
        #RebootButton,
        #PoweroffButton {
          background-color: ${accentDanger};
          color: ${surfaceBase};
        }

        #RebootButton:hover,
        #PoweroffButton:hover {
          background-color: alpha(${accentDanger}, 0.9);
          box-shadow: 0 2px 8px alpha(${accentDanger}, 0.3);
        }

        /* === SCROLLBARS === */
        scrollbar {
          background-color: transparent;
        }

        scrollbar slider {
          background-color: alpha(${textSecondary}, 0.3);
          border-radius: 4px;
          min-width: 8px;
          min-height: 40px;
        }

        scrollbar slider:hover {
          background-color: alpha(${textSecondary}, 0.5);
        }

        scrollbar slider:active {
          background-color: alpha(${textSecondary}, 0.7);
        }

        /* === CARD/CONTAINER STYLING === */
        .card {
          background-color: ${surfaceEmphasis};
          border-radius: 12px;
          padding: 24px;
          box-shadow: 0 2px 12px rgba(0, 0, 0, 0.2);
        }

        /* === ERROR MESSAGES === */
        .error {
          color: ${accentDanger};
          font-weight: 600;
        }

        /* === LOADING SPINNER === */
        spinner {
          color: ${accentFocus};
        }
      ''
    else
      ""; # No custom CSS if Signal theme is not enabled
in
{
  options.host.features.desktop.autoLogin = {
    enable = lib.mkEnableOption "automatic login on boot";
    user = lib.mkOption {
      type = lib.types.str;
      default = config.host.username or "lewis";
      description = "User to automatically login (defaults to host.username)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable ReGreet greeter for greetd
    programs.regreet = {
      enable = true;

      # Cage arguments - enable VT switching and use last monitor
      cageArgs = [
        "-s" # Enable VT switching
        "-m"
        "last" # Use last-connected monitor only
      ];

      # GTK theme configuration
      theme = {
        name = "Adwaita";
        package = pkgs.gnome-themes-extra;
      };

      cursorTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };

      iconTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };

      font = {
        name = "Inter";
        size = 12;
        package = pkgs.inter;
      };

      # Custom CSS styling with Signal theme colors
      # Applied on top of Adwaita base theme
      # Reference: https://docs.gtk.org/gtk4/css-properties.html
      extraCss = customCss;

      # ReGreet TOML configuration
      settings = {
        background = {
          path = "/usr/share/backgrounds/nixos/nix-wallpaper-simple-blue.png";
          fit = "Cover";
        };

        # Set environment variables for sessions
        env = {
          # Wayland-specific
          XDG_SESSION_TYPE = "wayland";
          # Force wlroots to use NVIDIA GPU (card2) where monitors are connected
          WLR_DRM_DEVICES = "/dev/dri/card2";
        };

        GTK = {
          application_prefer_dark_theme = true;
          cursor_theme_name = "Adwaita";
          cursor_blink = true;
          font_name = "Inter 12";
          icon_theme_name = "Adwaita";
          theme_name = "Adwaita";
        };

        commands = {
          reboot = [
            "systemctl"
            "reboot"
          ];
          poweroff = [
            "systemctl"
            "poweroff"
          ];
        };

        appearance = {
          greeting_msg = "Welcome back!";
        };
      };
    };

    # Greetd configuration with optional auto-login
    services.greetd = {
      settings = lib.mkIf cfg.autoLogin.enable {
        initial_session = {
          command = "${pkgs.niri}/bin/niri-session";
          inherit (cfg.autoLogin) user;
        };
      };
    };
  };
}
