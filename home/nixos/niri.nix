{
  pkgs,
  config,
  lib,
  inputs,
  system,
  ...
}:
let
  themeConstants = import ./theme-constants.nix {
    inherit
      pkgs
      inputs
      system
      config
      lib
      ;
  };
  inherit (inputs.niri.packages.${system}) xwayland-satellite-unstable niri-unstable;
  xwayland-satellite = xwayland-satellite-unstable;
in
{
  home.packages =
    (with pkgs; [
      grim
      slurp
      wl-clipboard
      wlr-randr
      wayland-utils
      brightnessctl
      # Note: xdg-utils is handled in core-tooling.nix
      lxqt.lxqt-policykit
      xwayland-satellite
      argyllcms
      colord-gtk
      wl-gammactl
    ])
    ++ [
      inputs.awww.packages.${system}.awww
    ];
  imports = [
    ./niri/keybinds.nix
  ];
  programs.niri = {
    package = niri-unstable;
    settings = {
      xwayland-satellite = {
        enable = true;
        path = "${lib.getExe xwayland-satellite}";
      };
      input = {
        keyboard = {
          xkb = {
            layout = "us";

          };

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
          default-column-width = { };
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
      spawn-at-startup = [
        {
          command = [
            "${pkgs.uwsm}/bin/uwsm"
            "app"
            "--"
            "${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent"
          ];
        }
        {
          command = [
            "${lib.getExe xwayland-satellite}"
          ];
        }
        {
          command = [
            "${inputs.awww.packages.${system}.awww}/bin/awww-daemon"
          ];
        }
        {
          command = [
            "${pkgs.bash}/bin/bash"
            "-c"
            "sleep 1 && ${
              inputs.awww.packages.${system}.awww
            }/bin/awww img ${config.home.homeDirectory}/wallpapers/nix-wallpaper-nineish-catppuccin-mocha.png"
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
        {
          command = [
            "${pkgs.uwsm}/bin/uwsm"
            "app"
            "--"
            "${pkgs.waybar}/bin/waybar"
          ];
        }
      ];
    };
  };
}
