# Niri compositor home-manager configuration (NixOS only)
# Dendritic pattern: Full implementation as flake.modules.homeManager.niriHome
{ config, ... }:
{
  flake.modules.homeManager.niriHome =
    {
      config,
      lib,
      pkgs,
      osConfig ? { },
      ...
    }:
    let
      inherit (pkgs) niri-unstable;
    in
    lib.mkIf pkgs.stdenv.isLinux {
      home.packages = [
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard
        pkgs.wlr-randr
        pkgs.wayland-utils
        pkgs.libdrm
        pkgs.argyllcms
        pkgs.wl-gammactl
        pkgs.xwayland-satellite-unstable
      ];

      home.pointerCursor = {
        name = "phinger-cursors-light";
        package = pkgs.phinger-cursors;
        size = 32;
        gtk.enable = true;
        x11.enable = true;
      };

      programs.hyprcursor-phinger.enable = true;

      programs.niri = {
        package = niri-unstable;
        settings = {
          prefer-no-csd = true;
          hotkey-overlay.skip-at-startup = true;
          overview.zoom = 0.5;
          gestures = {
            hot-corners.enable = true;
            dnd-edge-view-scroll = {
              delay-ms = 200;
              trigger-width = 48;
              max-speed = 1000;
            };
            dnd-edge-workspace-switch = {
              delay-ms = 200;
              trigger-height = 48;
              max-speed = 1000;
            };
          };
          xwayland-satellite.enable = true;
          screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
          cursor = {
            theme = "phinger-cursors-light";
            size = 32;
          };
          environment.QT_QPA_PLATFORM = "wayland";
          debug = lib.mkIf (osConfig.host.hardware.renderDevice or null != null) {
            render-drm-device = osConfig.host.hardware.renderDevice;
          };

          # Outputs
          outputs = {
            "DP-3" = {
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
              focus-at-startup = true;
            };
            "HDMI-A-4" = {
              position = {
                x = 2752;
                y = 0;
              };
              mode = {
                width = 1920;
                height = 1080;
                refresh = 60.0;
              };
              scale = 1.0;
            };
          };

          # Layout
          layout = {
            always-center-single-column = true;
            empty-workspace-above-first = true;
            default-column-display = "tabbed";
            center-focused-column = "on-overflow";
            preset-column-widths = [
              { proportion = 1.0 / 3.0; }
              { proportion = 1.0 / 2.0; }
              { proportion = 2.0 / 3.0; }
              { proportion = 1.0; }
            ];
            struts = {
              left = 0;
              right = 0;
              top = 0;
              bottom = 0;
            };
          };

          # Input
          input = {
            keyboard = {
              xkb.layout = "us";
              repeat-delay = 600;
              repeat-rate = 25;
            };
            focus-follows-mouse = {
              enable = true;
              max-scroll-amount = "0%";
            };
            warp-mouse-to-focus.enable = false;
            workspace-auto-back-and-forth = true;
            mouse = {
              natural-scroll = true;
              accel-profile = "flat";
              scroll-factor = 1.0;
            };
          };

          # Animations
          animations = {
            enable = true;
            slowdown = 1.0;
            workspace-switch = {
              enable = true;
              kind.spring = {
                damping-ratio = 1.0;
                stiffness = 1000;
                epsilon = 0.0001;
              };
            };
            window-movement = {
              enable = true;
              kind.spring = {
                damping-ratio = 1.0;
                stiffness = 1000;
                epsilon = 0.0001;
              };
            };
            window-open = {
              enable = true;
              kind.spring = {
                damping-ratio = 1.0;
                stiffness = 1000;
                epsilon = 0.0001;
              };
            };
            window-resize = {
              enable = true;
              kind.spring = {
                damping-ratio = 1.0;
                stiffness = 1000;
                epsilon = 0.0001;
              };
            };
            horizontal-view-movement = {
              enable = true;
              kind.spring = {
                damping-ratio = 1.0;
                stiffness = 1000;
                epsilon = 0.0001;
              };
            };
            window-close = {
              enable = true;
              kind.easing = {
                duration-ms = 150;
                curve = "ease-out-quad";
              };
            };
            screenshot-ui-open = {
              enable = true;
              kind.easing = {
                duration-ms = 150;
                curve = "ease-out-quad";
              };
            };
          };

          # Startup
          spawn-at-startup = [
            { command = [ "awww-daemon" ]; }
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
                "${pkgs.wl-gammactl}/bin/wl-gammactl"
                "--gamma"
                "1.0"
                "--brightness"
                "1.0"
              ];
            }
            {
              command = [
                "${pkgs.niri}/bin/niri"
                "msg"
                "output"
                "HDMI-A-4"
                "on"
              ];
            }
          ];
        };
      };
    };
}
