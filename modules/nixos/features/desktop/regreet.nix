{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.features.desktop;

  # Custom CSS for ReGreet (Signal theme support disabled for now)
  # TODO: Re-enable Signal theme integration once signal-nix provides proper module args
  # Reference: https://docs.gtk.org/gtk4/css-properties.html
  customCss = ""; # Disabled until Signal theme is properly integrated
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
