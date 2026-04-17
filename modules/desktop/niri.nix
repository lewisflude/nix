# Niri Compositor Configuration
# Niri Wayland compositor with NVIDIA optimizations and home-manager settings
{ inputs, ... }:
{
  flake.modules.nixos.niri =
    { lib, config, ... }:
    {
      programs.niri = {
        enable = true;
        package = inputs.niri.packages.${config.nixpkgs.hostPlatform.system}.niri-unstable;
      };

      # UWSM session management for niri
      programs.uwsm = {
        enable = true;
        waylandCompositors.niri = {
          prettyName = "Niri";
          comment = "Niri compositor managed by UWSM";
          binPath = lib.getExe config.programs.niri.package;
        };
      };

      # niri-flake targets WantedBy=niri.service, but UWSM uses
      # wayland-wm@niri-session.service — fix to target graphical-session.target
      systemd.user.services.niri-flake-polkit.wantedBy = lib.mkForce [
        "graphical-session.target"
      ];

      # NVIDIA application profile to fix high VRAM usage with niri
      # See: https://yalter.github.io/niri/Nvidia.html#high-vram-usage-fix
      environment.etc."nvidia/nvidia-application-profiles-rc.d/50-limit-free-buffer-pool-in-wayland-compositors.json" =
        lib.mkIf config.hardware.nvidia.enabled {
          text = ''
            {
                "rules": [
                    {
                        "pattern": {
                            "feature": "procname",
                            "matches": "niri"
                        },
                        "profile": "Limit Free Buffer Pool On Wayland Compositors"
                    }
                ],
                "profiles": [
                    {
                        "name": "Limit Free Buffer Pool On Wayland Compositors",
                        "settings": [
                            {
                                "key": "GLVidHeapReuseRatio",
                                "value": 0
                            }
                        ]
                    }
                ]
            }
          '';
          mode = "0644";
        };
    };

  flake.modules.homeManager.niri =
    {
      lib,
      pkgs,
      osConfig ? { },
      ...
    }:
    lib.mkIf pkgs.stdenv.isLinux {
      home.packages = [
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard
        pkgs.wlr-randr
        pkgs.argyllcms
        pkgs.wl-gammactl
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
        package = pkgs.niri-unstable;
        settings =
          let
            dmsIpc = args: {
              action.spawn = [
                "dms"
                "ipc"
              ]
              ++ args;
            };
            dmsIpcLocked = args: dmsIpc args // { allow-when-locked = true; };
            dmsIpcTitle = args: title: dmsIpc args // { hotkey-overlay.title = title; };

            workspaceBinds = builtins.listToAttrs (
              builtins.concatMap (
                n:
                let
                  s = toString n;
                in
                [
                  {
                    name = "Mod+${s}";
                    value.action.focus-workspace = n;
                  }
                  {
                    name = "Mod+Shift+${s}";
                    value.action.move-window-to-workspace = n;
                  }
                  {
                    name = "Mod+Ctrl+${s}";
                    value.action.move-column-to-workspace = n;
                  }
                ]
              ) (lib.range 6 9)
            );

            floatingApps = map (id: { app-id = id; }) [
              "xdg-desktop-portal-gtk"
              "xdg-desktop-portal-gnome"
              "^pinentry-"
              "gcr-prompter"
              "nm-connection-editor"
              "blueman-manager"
              "^pavucontrol$"
              "^pwvucontrol$"
              "org.gnome.Calculator"
              "zenity"
            ];

            r = 12.0;
            cornerRadius = {
              top-left = r;
              top-right = r;
              bottom-left = r;
              bottom-right = r;
            };

            snappy.kind.spring = {
              damping-ratio = 1.0;
              stiffness = 1000;
              epsilon = 0.0001;
            };
            quick.kind.easing = {
              duration-ms = 150;
              curve = "ease-out-quad";
            };
          in
          {
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
            xwayland-satellite = {
              enable = true;
              path = lib.getExe pkgs.xwayland-satellite-unstable;
            };
            screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
            environment.QT_QPA_PLATFORM = "wayland";
            debug = lib.mkIf (osConfig.host.hardware.renderDevice or null != null) {
              render-drm-device = osConfig.host.hardware.renderDevice;
            };

            binds = {
              "Mod+O" = {
                action.toggle-overview = { };
                repeat = false;
                hotkey-overlay.title = "Toggle Overview";
              };
              "Mod+Shift+Slash" = {
                action.show-hotkey-overlay = { };
                hotkey-overlay.title = "Show Hotkey Overlay";
              };

              # DMS IPC binds
              "Mod+D" = dmsIpcTitle [ "call" "spotlight" "toggle" ] "Launch DMS Spotlight";
              "Mod+V" = dmsIpcTitle [ "call" "clipboard" "toggle" ] "Clipboard Manager";
              "Mod+Escape" = dmsIpcTitle [ "call" "lock" "lock" ] "Lock Screen";
              "Mod+Shift+E" = dmsIpcTitle [ "call" "powermenu" "toggle" ] "Power Menu";
              "Mod+Comma" = dmsIpcTitle [ "call" "settings" "toggle" ] "Settings";
              "Mod+N" = dmsIpcTitle [ "call" "control-center" "toggle" ] "Notifications";
              "Mod+Slash" = dmsIpcTitle [ "call" "keybinds" "toggle" ] "Show Keybinds";
              "Mod+Shift+T" = dmsIpcTitle [ "call" "theme" "toggle" ] "Toggle Light/Dark Theme";

              # App launchers
              "Mod+T" = {
                action.spawn = [ "ghostty" ];
                hotkey-overlay.title = "Open Terminal";
              };
              "Mod+B" = {
                action.spawn = [ "google-chrome-stable" ];
                hotkey-overlay.title = "Open Browser";
              };

              "Mod+Q" = {
                action.close-window = { };
                hotkey-overlay.title = "Close Window";
              };

              # Focus navigation (vim + arrows)
              "Mod+H".action.focus-column-left = { };
              "Mod+J".action.focus-window-down = { };
              "Mod+K".action.focus-window-up = { };
              "Mod+L".action.focus-column-right = { };
              "Mod+Left".action.focus-column-left = { };
              "Mod+Down".action.focus-window-down = { };
              "Mod+Up".action.focus-window-up = { };
              "Mod+Right".action.focus-column-right = { };

              # Window layout
              "Mod+F" = {
                action.maximize-column = { };
                hotkey-overlay.title = "Maximize Column";
              };
              "Mod+Shift+F" = {
                action.fullscreen-window = { };
                hotkey-overlay.title = "Fullscreen Window";
              };
              "Mod+M" = {
                action.maximize-window-to-edges = { };
                hotkey-overlay.title = "Maximize Window (no gaps)";
              };
              "Mod+W" = {
                action.toggle-column-tabbed-display = { };
                hotkey-overlay.title = "Toggle Tabbed Display";
              };
              "Mod+Space" = {
                action.toggle-window-floating = { };
                hotkey-overlay.title = "Toggle Window Floating";
              };
              "Mod+Shift+V" = {
                action.switch-focus-between-floating-and-tiling = { };
                hotkey-overlay.title = "Switch Focus Floating/Tiling";
              };

              # Move windows (vim + arrows)
              "Mod+Ctrl+H".action.move-column-left = { };
              "Mod+Ctrl+J".action.move-window-down = { };
              "Mod+Ctrl+K".action.move-window-up = { };
              "Mod+Ctrl+L".action.move-column-right = { };
              "Mod+Ctrl+Left".action.move-column-left = { };
              "Mod+Ctrl+Down".action.move-window-down = { };
              "Mod+Ctrl+Up".action.move-window-up = { };
              "Mod+Ctrl+Right".action.move-column-right = { };

              "Mod+Home".action.focus-column-first = { };
              "Mod+End".action.focus-column-last = { };
              "Mod+Ctrl+Home".action.move-column-to-first = { };
              "Mod+Ctrl+End".action.move-column-to-last = { };

              # Column/window sizing
              "Mod+Minus" = {
                action.set-column-width = "-10%";
                hotkey-overlay.title = "Decrease Column Width";
              };
              "Mod+Equal" = {
                action.set-column-width = "+10%";
                hotkey-overlay.title = "Increase Column Width";
              };
              "Mod+Shift+Minus" = {
                action.set-window-height = "-10%";
                hotkey-overlay.title = "Decrease Window Height";
              };
              "Mod+Shift+Equal" = {
                action.set-window-height = "+10%";
                hotkey-overlay.title = "Increase Window Height";
              };
              "Mod+R" = {
                action.switch-preset-column-width = { };
                hotkey-overlay.title = "Cycle Column Width Presets";
              };
              "Mod+Shift+R" = {
                action.switch-preset-window-height = { };
                hotkey-overlay.title = "Cycle Window Height Presets";
              };
              "Mod+Ctrl+R" = {
                action.reset-window-height = { };
                hotkey-overlay.title = "Reset Window Height";
              };
              "Mod+C" = {
                action.center-column = { };
                hotkey-overlay.title = "Center Column";
              };
              "Mod+Ctrl+C" = {
                action.center-visible-columns = { };
                hotkey-overlay.title = "Center All Visible Columns";
              };
              "Mod+Ctrl+F" = {
                action.expand-column-to-available-width = { };
                hotkey-overlay.title = "Expand Column to Fill";
              };

              # Column consume/expel
              "Mod+BracketLeft" = {
                action.consume-or-expel-window-left = { };
                hotkey-overlay.title = "Consume/Expel Window Left";
              };
              "Mod+BracketRight" = {
                action.consume-or-expel-window-right = { };
                hotkey-overlay.title = "Consume/Expel Window Right";
              };
              "Mod+Shift+Comma" = {
                action.consume-window-into-column = { };
                hotkey-overlay.title = "Consume Window into Column";
              };
              "Mod+Period" = {
                action.expel-window-from-column = { };
                hotkey-overlay.title = "Expel Window from Column";
              };

              # Monitor focus/move (vim + arrows)
              "Mod+Shift+H".action.focus-monitor-left = { };
              "Mod+Shift+J".action.focus-monitor-down = { };
              "Mod+Shift+K".action.focus-monitor-up = { };
              "Mod+Shift+L".action.focus-monitor-right = { };
              "Mod+Shift+Left".action.focus-monitor-left = { };
              "Mod+Shift+Down".action.focus-monitor-down = { };
              "Mod+Shift+Up".action.focus-monitor-up = { };
              "Mod+Shift+Right".action.focus-monitor-right = { };

              "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = { };
              "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = { };
              "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = { };
              "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = { };
              "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = { };
              "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = { };
              "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = { };
              "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = { };

              # Workspace navigation
              "Mod+U".action.focus-workspace-down = { };
              "Mod+I".action.focus-workspace-up = { };
              "Mod+Page_Down".action.focus-workspace-down = { };
              "Mod+Page_Up".action.focus-workspace-up = { };
              "Mod+Ctrl+U".action.move-column-to-workspace-down = { };
              "Mod+Ctrl+I".action.move-column-to-workspace-up = { };
              "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = { };
              "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = { };

              "Mod+Shift+U".action.move-workspace-down = { };
              "Mod+Shift+I".action.move-workspace-up = { };
              "Mod+Shift+Page_Down".action.move-workspace-down = { };
              "Mod+Shift+Page_Up".action.move-workspace-up = { };

              # Scroll binds
              "Mod+WheelScrollDown" = {
                action.focus-workspace-down = { };
                cooldown-ms = 150;
              };
              "Mod+WheelScrollUp" = {
                action.focus-workspace-up = { };
                cooldown-ms = 150;
              };
              "Mod+Ctrl+WheelScrollDown" = {
                action.move-column-to-workspace-down = { };
                cooldown-ms = 150;
              };
              "Mod+Ctrl+WheelScrollUp" = {
                action.move-column-to-workspace-up = { };
                cooldown-ms = 150;
              };

              "Mod+WheelScrollRight".action.focus-column-right = { };
              "Mod+WheelScrollLeft".action.focus-column-left = { };
              "Mod+Ctrl+WheelScrollRight".action.move-column-right = { };
              "Mod+Ctrl+WheelScrollLeft".action.move-column-left = { };

              "Mod+Shift+WheelScrollDown".action.focus-column-right = { };
              "Mod+Shift+WheelScrollUp".action.focus-column-left = { };
              "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = { };
              "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = { };

              # Screenshots
              "Print".action.screenshot = { };
              "Ctrl+Print".action.screenshot-screen = { };
              "Alt+Print".action.screenshot-window = { };

              # Media keys (DMS IPC, available when locked)
              "XF86AudioRaiseVolume" = dmsIpcLocked [
                "call"
                "audio"
                "increment"
              ];
              "XF86AudioLowerVolume" = dmsIpcLocked [
                "call"
                "audio"
                "decrement"
              ];
              "XF86AudioMute" = dmsIpcLocked [
                "call"
                "audio"
                "mute"
              ];
              "XF86AudioMicMute" = dmsIpcLocked [
                "call"
                "audio"
                "micmute"
              ];
              "XF86AudioPlay" = dmsIpcLocked [
                "call"
                "mpris"
                "playPause"
              ];
              "XF86AudioStop" = dmsIpcLocked [
                "call"
                "mpris"
                "stop"
              ];
              "XF86AudioNext" = dmsIpcLocked [
                "call"
                "mpris"
                "next"
              ];
              "XF86AudioPrev" = dmsIpcLocked [
                "call"
                "mpris"
                "previous"
              ];

              # Brightness (DMS IPC, available when locked)
              "XF86MonBrightnessUp" = dmsIpcLocked [
                "call"
                "brightness"
                "increment"
              ];
              "XF86MonBrightnessDown" = dmsIpcLocked [
                "call"
                "brightness"
                "decrement"
              ];

              # System
              "Mod+Shift+P" = {
                action.power-off-monitors = { };
                hotkey-overlay.title = "Power Off Monitors";
              };
              "Mod+Shift+Escape" = {
                action.toggle-keyboard-shortcuts-inhibit = { };
                allow-inhibiting = false;
                hotkey-overlay.title = "Toggle Shortcut Inhibitor";
              };
              "Ctrl+Alt+Delete" = {
                action.quit = { };
                hotkey-overlay.title = "Quit Niri";
              };
            }
            // workspaceBinds;

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
              workspace-auto-back-and-forth = true;
              mouse = {
                natural-scroll = true;
                accel-profile = "flat";
              };
            };

            animations = {
              workspace-switch = snappy;
              window-movement = snappy;
              window-open = snappy;
              window-resize = snappy;
              horizontal-view-movement = snappy;
              window-close = quick;
              screenshot-ui-open = quick;
            };

            layer-rules = [
              {
                matches = [ { namespace = "^quickshell$"; } ];
                place-within-backdrop = true;
              }
            ];

            window-rules = [
              {
                geometry-corner-radius = cornerRadius;
                clip-to-geometry = true;
              }

              {
                matches = [ { app-id = "^org\\.quickshell$"; } ];
                open-floating = true;
              }

              {
                matches = floatingApps;
                open-floating = true;
              }

              {
                matches = [ { app-id = "^1password$"; } ];
                open-floating = true;
                block-out-from = "screencast";
              }

              {
                matches = [
                  {
                    app-id = "^firefox";
                    title = "^Picture-in-Picture$";
                  }
                  { title = "^Picture in picture$"; }
                ];
                open-floating = true;
              }

              {
                matches = [ { app-id = "^steam_app_"; } ];
                open-fullscreen = true;
                variable-refresh-rate = true;
              }

              {
                matches = [ { app-id = "^gamescope$"; } ];
                open-fullscreen = true;
                variable-refresh-rate = true;
              }

              {
                matches = [ { app-id = "^steam$"; } ];
                default-column-width.proportion = 0.65;
              }

              # Labwc nested compositor (used for Unity Editor)
              {
                matches = [ { app-id = "^labwc$"; } ];
                open-maximized = true;
              }

              {
                matches = [ { is-active = false; } ];
                opacity = 0.95;
              }
            ];

          };
      };
    };
}
