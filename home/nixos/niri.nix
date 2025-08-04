{ pkgs, config, ... }:
let
  # Import theme constants
  themeConstants = import ./theme-constants.nix { inherit config pkgs; };
in
{
  home.packages = with pkgs; [
    swww
    gtklock
    grimblast
    swayidle
    grim
    slurp
    swappy
    wl-clipboard
  ];

  imports = [
    ./niri/keybinds.nix
  ];

  programs.niri = {
    package = pkgs.niri-unstable;
    settings = {
      input = {
        mouse = {
          natural-scroll = true;
          accel-speed = 0.2;
          accel-profile = "flat";
          scroll-factor = 1.0;
          scroll-button = 273;
        };
      };
      outputs = {
        "DP-1" = {
          scale = 1.25;
          position = {
            x = 0;
            y = 0;
          };
          mode = {
            width = 3440;
            height = 1440;
            refresh = 164.90;
          };
          variable-refresh-rate = "on-demand";
        };
      };

      layout = {
        gaps = 16;
        always-center-single-column = true;
        empty-workspace-above-first = true;
        default-column-display = "tabbed";
        focus-ring = {
          width = 2;
          active = {
            color = themeConstants.niri.colors.focus-ring.active;
          };
          inactive = {
            color = themeConstants.niri.colors.focus-ring.inactive;
          };
        };
        struts = {
          left = 0;
          right = 0;
          top = 0;
          bottom = 0;
        };
        border = {
          width = 1;
          active = {
            color = themeConstants.niri.colors.border.active;
          };
          inactive = {
            color = themeConstants.niri.colors.border.inactive;
          };
          urgent = {
            color = themeConstants.niri.colors.border.urgent;
          };
        };
        shadow = {
          enable = true;
          softness = 50;
          spread = 4;
          offset = {
            x = 0;
            y = 8;
          };
          color = themeConstants.niri.colors.shadow;
          draw-behind-window = true;
        };
        tab-indicator = {
          hide-when-single-tab = true;
          place-within-column = true;
          gap = 4;
          width = 4;
          position = "right";
          gaps-between-tabs = 2;
          corner-radius = 4;
          active = {
            color = themeConstants.niri.colors.tab-indicator.active;
          };
          inactive = {
            color = themeConstants.niri.colors.tab-indicator.inactive;
          };
        };
      };

      prefer-no-csd = true;

      animations = {
        enable = true;
        slowdown = 1.0;
        workspace-switch = {
          enable = true;
          kind = {
            spring = {
              damping-ratio = 1.0;
              stiffness = 1000;
              epsilon = 0.0001;
            };
          };
        };
        window-movement = {
          enable = true;
          kind = {
            spring = {
              damping-ratio = 1.0;
              stiffness = 800;
              epsilon = 0.0001;
            };
          };
        };
      };

      environment = {
        DISPLAY = ":0";
        NIXOS_OZONE_WL = "1";

        ELECTRON_OZONE_PLATFORM_HINT = "auto";

        _JAVA_AWT_WM_NONREPARENTING = "1";

        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        QT_QPA_PLATFORM = "wayland";
        QT_QPA_PLATFORMTHEME = "gtk3";

        XDG_CURRENT_DESKTOP = "niri";
        XDG_SESSION_DESKTOP = "niri";
        XDG_SESSION_TYPE = "wayland";
      };
      xwayland-satellite = {
        enable = true;
        path = "${pkgs.xwayland-satellite-unstable}/bin/xwayland-satellite";
      };

      spawn-at-startup = [
        {
          command = [
            "${pkgs.uwsm}/bin/uwsm"
            "app"
            "--"
            "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
          ];
        }

        {
          command = [
            "${pkgs.uwsm}/bin/uwsm"
            "app"
            "--"
            "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon"
            "--start"
            "--components=secrets,ssh"
          ];
        }

        {
          command = [
            "${pkgs.uwsm}/bin/uwsm"
            "app"
            "--"
            "${pkgs.swww}/bin/swww-daemon"
          ];
        }

        {
          command = [
            "${pkgs.swww}/bin/swww"
            "img"
            "${config.home.homeDirectory}/wallpapers/nix-wallpaper-nineish-catppuccin-mocha.png"
          ];
        }
        {
          command = [
            "pw-link"
            "Main-Output-Proxy:monitor_FL"
            "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX0"
          ];
        }
        {
          command = [
            "pw-link"
            "Main-Output-Proxy:monitor_FR"
            "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX1"
          ];
        }
      ];
    };
  };
}
