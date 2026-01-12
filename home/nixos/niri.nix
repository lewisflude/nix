{
  pkgs,
  config,
  lib,
  inputs,
  system,
  themeLib,
  ...
}:
let
  themeConstants = import ./theme-constants.nix {
    inherit
      lib
      themeLib
      ;
  };
  # Use overlay packages to ensure mesa dependencies match system nixpkgs
  inherit (pkgs) xwayland-satellite-unstable niri-unstable;
  xwayland-satellite = xwayland-satellite-unstable;
in
{
  home.packages = [
    pkgs.grimblast
    pkgs.wl-clipboard
    pkgs.wlr-randr
    pkgs.wayland-utils
    pkgs.brightnessctl
    # Note: xdg-utils is handled in core-tooling.nix
    xwayland-satellite
    pkgs.argyllcms
    pkgs.colord-gtk
    pkgs.wl-gammactl
    pkgs.libdrm # Provides modetest for checking DRM/HDR properties
    # X11 compatibility tools
    pkgs.labwc # Nested Wayland compositor for X11 apps that need specific positioning
    pkgs.xsel # X11 clipboard utilities for rootful Xwayland integration
  ]
  ++ [
    inputs.awww.packages.${system}.awww
  ];

  # Make workspace creation script available
  home.file.".local/bin/create-niri-workspaces" = {
    source = ./scripts/create-niri-workspaces.sh;
    executable = true;
  };
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
      # Force NVIDIA RTX 4090 as the primary render device
      # Use renderD128 (render node) for optimal performance on multi-GPU systems
      # This ensures Niri doesn't try to use the Intel iGPU for rendering
      debug = {
        render-drm-device = "/dev/dri/renderD128";
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
          variable-refresh-rate = true;
        };
        # Dummy HDMI plug (HDMI-A-4) - used for Sunshine streaming
        # Positioned next to DP-3 (ultrawide) for Sunshine to capture properly
        # DP-3 will be turned off during streaming via Sunshine prep-cmd
        "HDMI-A-4" = {
          position = {
            x = 2752; # Position to the right of DP-3 (which is 2752 logical pixels wide)
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
          # Set to false to prevent background "spilling out" beyond borders
          # This fixes the issue with context menus and popups
          draw-behind-window = false;
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
      # HDR/10-bit support status:
      # - niri currently forces 8-bit by default to avoid bandwidth issues
      # - The debug flag keep-max-bpc-unchanged is deprecated
      # - PR #3158 is adding proper per-output BPC (bits per component) configuration
      # - For actual 10-bit rendering, niri needs code changes to SUPPORTED_COLOR_FORMATS
      # - 10-bit works with applications using vo=dmabuf-wayland (e.g., mpv)
      # - HDR color management is not yet implemented (see issue #1841)
      # See: https://github.com/YaLTeR/niri/issues/1533 and PR #3158
      # Workspace Organization:
      # 1-2: Browser and general browsing
      # 3-4: Development (terminals, editors)
      # 5-6: Communication (chat, email)
      # 7-8: Media (Spotify, Obsidian)
      # 9: Gaming (Steam, games) - isolated for performance and organization
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
        # Disable shadows for notifications (SwayNC)
        # Fixes background "spilling out" beyond borders issue
        {
          matches = [
            { app-id = "^org\\.erikreider\\.swaync.*"; }
          ];
          shadow.enable = false;
        }
        # Browser windows - workspace 1
        {
          matches = [
            { app-id = "^chromium-browser$"; }
            { app-id = "^brave-browser$"; }
            { app-id = "^firefox$"; }
          ];
          open-on-workspace = "1";
        }
        # Development tools - workspace 3
        {
          matches = [
            { app-id = "^code$"; }
            { app-id = "^cursor$"; }
            { app-id = "^com\\.visualstudio\\.code.*"; }
            { app-id = "^dev\\.zed\\.Zed.*"; }
          ];
          open-on-workspace = "3";
        }
        # Communication apps - workspace 5
        {
          matches = [
            { app-id = "^discord$"; }
            { app-id = "^slack$"; }
            { app-id = "^signal$"; }
            { app-id = "^org\\.telegram\\.desktop$"; }
          ];
          open-on-workspace = "5";
        }
        # Email - workspace 5 (same as chat for communication grouping)
        {
          matches = [
            { app-id = "^thunderbird$"; }
          ];
          open-on-workspace = "5";
        }
        # Media apps - workspace 7
        {
          matches = [
            { app-id = "^obsidian$"; }
            { app-id = "^spotify$"; }
            { app-id = "^md\\.obsidian\\.Obsidian$"; }
          ];
          open-on-workspace = "7";
        }
        # Gaming workspace 9 - isolated for performance and organization
        # This keeps Steam's noisy notifications and pop-ups separate from your work
        {
          matches = [
            { app-id = "^steam$"; }
            { title = "^Steam$"; }
          ];
          open-on-workspace = "9";
        }
        # Gamescope nested compositor - workspace 9 for gaming
        # Opens maximized for optimal gaming experience
        {
          matches = [
            { app-id = "^gamescope$"; }
          ];
          default-column-width = {
            proportion = 1.0;
          };
          open-maximized = true;
          open-on-workspace = "9";
        }
        # Steam games - auto-focus by opening fullscreen on gaming workspace
        # This ensures games launched via Steam are immediately focused and isolated
        # Performance tip: Disable compositor effects on this workspace if needed
        {
          matches = [
            { app-id = "^steam_app_.*"; }
          ];
          open-fullscreen = true;
          open-on-workspace = "9";
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
        # xwayland-satellite is automatically managed by niri >= 25.08
        # It spawns on-demand when X11 clients connect and auto-restarts if it crashes
        {
          command = [
            "${inputs.awww.packages.${system}.awww}/bin/awww-daemon"
          ];
        }
        # Create all workspaces on startup for consistent ironbar display
        {
          command = [
            "${config.home.homeDirectory}/.local/bin/create-niri-workspaces"
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
        # Gamma correction for better display quality
        # Adjust gamma values if needed (default: 1.0 for all channels)
        # For OLED displays, slight gamma adjustment can improve perceived contrast
        {
          command = [
            "${pkgs.wl-gammactl}/bin/wl-gammactl"
            "--gamma"
            "1.0"
            "--brightness"
            "1.0"
          ];
        }
        # Enable HDMI-A-4 at startup so Sunshine can detect it as Monitor 1
        # This display is used for streaming and should always be enabled
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
}
