{
  pkgs,
  config,
  lib,
  ...
}: let
  themeConstants = import ./theme-constants.nix {inherit config lib pkgs;};
in {
  home.packages = with pkgs; [
    swww
    grim
    slurp
    wl-clipboard
    wlr-randr
    wayland-utils
    brightnessctl
    xdg-utils
    polkit_gnome
    xwayland-satellite-unstable
    argyllcms
    colord-gtk
    wl-gammactl
  ];
  imports = [
    ./niri/keybinds.nix
  ];
  programs.niri = {
    package = pkgs.niri-unstable;
    settings = {
      xwayland-satellite = {
        enable = true;
        path = "${lib.getExe pkgs.xwayland-satellite-unstable}";
      };
      input = {
        keyboard = {
          xkb = {
            layout = "us";
            # WKL keyboard configuration handled by keyd at system level
            # Keeping this section for future XKB customization if needed
          };
          # Disable repeat for modifier keys to prevent issues with layer switching
          repeat-delay = 600;
          repeat-rate = 25;
        };
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
      hotkey-overlay.skip-at-startup = true;
      window-rules = [
        {
          matches = [
            {
              app-id = "^displaycal$";
            }
          ];
          default-column-width = {};
          open-floating = true;
        }
      ];
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
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        NIXOS_OZONE_WL = "1";
        MOZ_ENABLE_WAYLAND = "1";
        MOZ_WEBRENDER = "1";
        XDG_CURRENT_DESKTOP = "niri";
        XDG_SESSION_DESKTOP = "niri";
        XDG_SESSION_TYPE = "wayland";
        QT_QPA_PLATFORM = "wayland";
        QT_QPA_PLATFORMTHEME = "gtk3";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        QT_AUTO_SCREEN_SCALE_FACTOR = "1";
        QT_WAYLAND_FORCE_DPI = "physical";
        _JAVA_AWT_WM_NONREPARENTING = "1";
        SDL_VIDEODRIVER = "wayland,x11";
        GTK_THEME = "Adwaita:dark";
        FREETYPE_PROPERTIES = "cff:no-stem-darkening=0 autofitter:no-stem-darkening=0";
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
            "${lib.getExe pkgs.xwayland-satellite-unstable}"
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
            "${pkgs.uwsm}/bin/uwsm"
            "app"
            "--"
            "${pkgs.swww}/bin/swww"
            "img"
            "${config.home.homeDirectory}/wallpapers/nix-wallpaper-nineish-catppuccin-mocha.png"
          ];
        }
        {
          command = [
            "${pkgs.argyllcms}/bin/dispwin"
            "-d"
            "1"
            "${config.home.homeDirectory}/.local/share/icc/aw3423dwf.icc"
          ];
        }
      ];
    };
  };
}
