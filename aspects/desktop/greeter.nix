# Greeter Configuration
# Display manager greeters (ReGreet and DMS) with auto-login support
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.features.desktop;
  isLinux = pkgs.stdenv.isLinux;
  signalCfg = config.theming.signal.nixos or null;

  # Use Signal GTK theme if available, otherwise fall back to Adwaita
  gtkTheme = {
    name = signalCfg.gtk.themeName or "Adwaita";
    package = signalCfg.gtk.themePackage or pkgs.gnome-themes-extra;
  };
in
{
  options.host.features.desktop = {
    greeter = lib.mkOption {
      type = lib.types.enum [
        "regreet"
        "dms"
      ];
      default = "dms";
      description = "Which greeter to use (regreet or dms)";
    };

    autoLogin = {
      enable = lib.mkEnableOption "automatic login on boot";
      user = lib.mkOption {
        type = lib.types.str;
        default = config.host.username or "lewis";
        description = "User to automatically login (defaults to host.username)";
      };
    };
  };

  config = lib.mkIf (cfg.enable && isLinux) {
    # Enable ReGreet greeter for greetd (only if greeter is set to regreet)
    programs.regreet = {
      enable = cfg.greeter == "regreet";

      # Cage arguments - enable VT switching and use last monitor
      cageArgs = [
        "-s" # Enable VT switching
        "-m"
        "last" # Use last-connected monitor only
      ];

      # GTK theme configuration (uses Signal theme if enabled)
      # Use mkDefault to allow signal-nix to override
      theme = lib.mkDefault gtkTheme;

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

      # Custom CSS can be added via signal-nix's regreet module if enabled
      # or manually here if needed

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
          application_prefer_dark_theme = lib.mkDefault true;
          cursor_theme_name = "Adwaita";
          cursor_blink = true;
          font_name = "Inter 12";
          icon_theme_name = "Adwaita";
          theme_name = lib.mkDefault gtkTheme.name;
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

    # Enable DMS greeter for greetd (only if greeter is set to dms)
    programs.dank-material-shell.greeter = lib.mkIf (cfg.greeter == "dms") {
      enable = true;

      # Use niri as the compositor for the greeter
      compositor = {
        name = "niri";
        # Optional: Add custom compositor config if needed
        # customConfig = [];
      };

      # Enable logging for troubleshooting
      logs = {
        save = true;
        path = "/tmp/dms-greeter.log";
      };

      # Use config from user's home directory
      configHome = "/home/${config.host.username}/.config/dms";
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
