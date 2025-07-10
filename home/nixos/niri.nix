{ pkgs, config, ... }:
let
  # Default applications
  terminal = "ghostty";
  launcher = "fuzzel";
  screenLocker = "swaylock";
in
{
  home.packages = with pkgs; [
    swww
    swaylock
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
          variable-refresh-rate = true;
        };
      };

      layout = {
        gaps = 16;
        always-center-single-column = true;
        empty-workspace-above-first = true;
        default-column-display = "tabbed";
        focus-ring = {
          width = 2;
        };
        border = {
          width = 2;
        };
        shadow = {
          enable = true;
          softness = 50;
          spread = 8;
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
      binds = {
        "Mod+T" = {
          action.spawn = [ terminal ];
        };
        "Mod+D" = {
          action.spawn = [ launcher ];
        };
        "Super+Alt+L" = {
          action.spawn = [ screenLocker ];
        };
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
            "systemctl"
            "enable"
            "--user"
            "com.mitchellh.ghostty.service"
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
