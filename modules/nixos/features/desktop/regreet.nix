{
  config,
  lib,
  pkgs,
  themeLib,
  ...
}:
let
  cfg = config.host.features.desktop;

  # Generate dark mode theme using shared themeLib
  theme = themeLib.generateTheme "dark" { };

  # Extract colors from theme
  inherit (theme) colors;
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

      # Custom CSS for Signal theme colors
      extraCss = ''
        /* Signal Theme - ReGreet Greeter Styling */
        /* Generated from Signal palette - Dark mode */

        /* Window and container backgrounds */
        window {
          background-color: ${colors."surface-base".hex};
        }

        .container,
        .view,
        box {
          background-color: ${colors."surface-base".hex};
          color: ${colors."text-primary".hex};
        }

        /* Greeting message */
        .greeting-label,
        label.greeting {
          color: ${colors."text-primary".hex};
          font-size: 1.5em;
          font-weight: 500;
        }

        /* Clock display */
        .clock-label,
        label.clock {
          color: ${colors."text-secondary".hex};
          font-size: 1.1em;
        }

        /* Input fields (username, password) */
        entry {
          background-color: ${colors."surface-subtle".hex};
          color: ${colors."text-primary".hex};
          border: 2px solid ${colors."divider-primary".hex};
          border-radius: 8px;
          padding: 8px 12px;
          margin: 4px 0;
        }

        entry:focus {
          border-color: ${colors."accent-focus".hex};
          box-shadow: 0 0 0 2px ${theme.withAlpha colors."accent-focus" 0.2};
        }

        entry:hover {
          border-color: ${colors."divider-secondary".hex};
        }

        entry placeholder {
          color: ${colors."text-tertiary".hex};
        }

        /* Dropdown menus (session/user selection) */
        combobox,
        .combo {
          background-color: ${colors."surface-subtle".hex};
          color: ${colors."text-primary".hex};
          border: 2px solid ${colors."divider-primary".hex};
          border-radius: 8px;
        }

        combobox:hover,
        .combo:hover {
          border-color: ${colors."divider-secondary".hex};
        }

        combobox button {
          background-color: transparent;
          border: none;
          color: ${colors."text-secondary".hex};
        }

        /* Dropdown popup menu */
        popover,
        menu {
          background-color: ${colors."surface-emphasis".hex};
          border: 2px solid ${colors."divider-secondary".hex};
          border-radius: 8px;
          padding: 4px;
        }

        popover modelbutton,
        menu menuitem {
          color: ${colors."text-primary".hex};
          border-radius: 6px;
          padding: 8px 12px;
        }

        popover modelbutton:hover,
        menu menuitem:hover {
          background-color: ${colors."surface-subtle".hex};
        }

        popover modelbutton:selected,
        menu menuitem:selected {
          background-color: ${colors."accent-focus".hex};
          color: ${colors."surface-base".hex};
        }

        /* Buttons (Login, Reboot, Shutdown) */
        button {
          background-color: ${colors."accent-focus".hex};
          color: ${colors."surface-base".hex};
          border: none;
          border-radius: 8px;
          padding: 10px 24px;
          font-weight: 500;
          margin: 4px;
        }

        button:hover {
          background-color: ${colors."accent-special".hex};
        }

        button:active {
          background-color: ${colors."accent-info".hex};
        }

        button:disabled {
          background-color: ${colors."divider-primary".hex};
          color: ${colors."text-tertiary".hex};
        }

        /* Secondary buttons (Cancel, etc.) */
        button.secondary {
          background-color: ${colors."surface-emphasis".hex};
          color: ${colors."text-primary".hex};
          border: 2px solid ${colors."divider-primary".hex};
        }

        button.secondary:hover {
          border-color: ${colors."divider-secondary".hex};
          background-color: ${colors."surface-subtle".hex};
        }

        /* Destructive buttons (Shutdown, Reboot) */
        button.destructive-action {
          background-color: ${colors."accent-danger".hex};
          color: ${colors."surface-base".hex};
        }

        button.destructive-action:hover {
          background-color: ${colors."accent-warning".hex};
        }

        /* Error messages */
        .error-label,
        label.error {
          color: ${colors."accent-danger".hex};
          font-weight: 500;
        }

        /* Spinner/loading indicator */
        spinner {
          color: ${colors."accent-focus".hex};
        }

        /* Selection highlights */
        selection {
          background-color: ${colors."accent-focus".hex};
          color: ${colors."surface-base".hex};
        }

        /* Scrollbars (if any) */
        scrollbar {
          background-color: ${colors."surface-base".hex};
        }

        scrollbar slider {
          background-color: ${colors."divider-primary".hex};
          border-radius: 4px;
        }

        scrollbar slider:hover {
          background-color: ${colors."divider-secondary".hex};
        }

        /* Card-like containers */
        .card,
        frame {
          background-color: ${colors."surface-subtle".hex};
          border: 1px solid ${colors."divider-primary".hex};
          border-radius: 12px;
          padding: 16px;
        }

        /* Separators */
        separator {
          background-color: ${colors."divider-primary".hex};
          min-height: 1px;
          min-width: 1px;
        }
      '';
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
