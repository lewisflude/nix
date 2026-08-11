# Niri Compositor Configuration
# Niri Wayland compositor with NVIDIA optimizations and home-manager settings
{ inputs, ... }:
{
  overlays.niri =
    final: prev: if prev.stdenv.hostPlatform.isLinux then inputs.niri.overlays.niri final prev else { };

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
      # See: https://niri-wm.github.io/niri/Nvidia.html#high-vram-usage-fix
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
        enable = true;
        name = "phinger-cursors-light";
        package = pkgs.phinger-cursors;
        size = 32;
        gtk.enable = true;
        x11.enable = true;
      };

      programs.hyprcursor-phinger.enable = true;

      programs.niri = {
        # Use the niri-flake package built against its pinned nixpkgs (see the
        # nixpkgs-niri note in flake.nix) rather than the overlay against the
        # system nixpkgs, which currently throws on the removed libdisplay-info_0_2.
        package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
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

            # `{ action.<name> = <value>; hotkey-overlay.title = <title>; }` —
            # the shape almost every titled bind below has. mkTitled covers the
            # common no-argument action; mkTitledArg the ones that take a value.
            mkTitledArg = name: value: title: {
              action.${name} = value;
              hotkey-overlay.title = title;
            };
            mkTitled = name: mkTitledArg name { };

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
              ) (lib.range 1 9)
            );

            floatingApps = map (id: { app-id = id; }) [
              "xdg-desktop-portal-gtk"
              "xdg-desktop-portal-gnome"
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
            debug = lib.mkIf (osConfig.host.hardware.renderDevice or null != null) {
              render-drm-device = osConfig.host.hardware.renderDevice;
            };

            environment = {
              MOZ_ENABLE_WAYLAND = "1";
            };

            cursor = {
              hide-when-typing = true;
              hide-after-inactive-ms = 5000;
            };

            layout = {
              gaps = 16;
              always-center-single-column = true;
              preset-column-widths = [
                { proportion = 1.0 / 3.0; }
                { proportion = 1.0 / 2.0; }
                { proportion = 2.0 / 3.0; }
                { proportion = 1.0; }
              ];
              preset-window-heights = [
                { proportion = 1.0 / 3.0; }
                { proportion = 1.0 / 2.0; }
                { proportion = 2.0 / 3.0; }
                { proportion = 1.0; }
              ];
            };

            binds = {
              "Mod+O" = {
                action.toggle-overview = { };
                repeat = false;
                hotkey-overlay.title = "Toggle Overview";
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
              "Mod+T" = mkTitledArg "spawn" [ "ghostty" ] "Open Terminal";
              "Mod+B" = mkTitledArg "spawn" [ "google-chrome-stable" ] "Open Browser";

              "Mod+Q" = mkTitled "close-window" "Close Window";

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
              "Mod+F" = mkTitled "maximize-column" "Maximize Column";
              "Mod+Shift+F" = mkTitled "fullscreen-window" "Fullscreen Window";
              "Mod+M" = mkTitled "maximize-window-to-edges" "Maximize Window (no gaps)";
              "Mod+W" = mkTitled "toggle-column-tabbed-display" "Toggle Tabbed Display";
              "Mod+Space" = mkTitled "toggle-window-floating" "Toggle Window Floating";
              "Mod+Shift+V" = mkTitled "switch-focus-between-floating-and-tiling" "Switch Focus Floating/Tiling";

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
              "Mod+Minus" = mkTitledArg "set-column-width" "-10%" "Decrease Column Width";
              "Mod+Equal" = mkTitledArg "set-column-width" "+10%" "Increase Column Width";
              "Mod+Shift+Minus" = mkTitledArg "set-window-height" "-10%" "Decrease Window Height";
              "Mod+Shift+Equal" = mkTitledArg "set-window-height" "+10%" "Increase Window Height";
              "Mod+R" = mkTitled "switch-preset-column-width" "Cycle Column Width Presets";
              "Mod+Shift+R" = mkTitled "switch-preset-window-height" "Cycle Window Height Presets";
              "Mod+Ctrl+R" = mkTitled "reset-window-height" "Reset Window Height";
              "Mod+C" = mkTitled "center-column" "Center Column";
              "Mod+Ctrl+C" = mkTitled "center-visible-columns" "Center All Visible Columns";
              "Mod+Ctrl+F" = mkTitled "expand-column-to-available-width" "Expand Column to Fill";

              # Column consume/expel
              "Mod+BracketLeft" = mkTitled "consume-or-expel-window-left" "Consume/Expel Window Left";
              "Mod+BracketRight" = mkTitled "consume-or-expel-window-right" "Consume/Expel Window Right";
              "Mod+Shift+Comma" = mkTitled "consume-window-into-column" "Consume Window into Column";
              "Mod+Period" = mkTitled "expel-window-from-column" "Expel Window from Column";

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
              "Mod+Shift+P" = mkTitled "power-off-monitors" "Power Off Monitors";
              # Not mkTitled: carries allow-inhibiting alongside the action.
              "Mod+Shift+Escape" = {
                action.toggle-keyboard-shortcuts-inhibit = { };
                allow-inhibiting = false;
                hotkey-overlay.title = "Toggle Shortcut Inhibitor";
              };
              "Ctrl+Alt+Delete" = mkTitled "quit" "Quit Niri";
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
              warp-mouse-to-focus = {
                enable = true;
                mode = "center-xy";
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
              overview-open-close = quick;
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
                matches = [
                  { app-id = "^org\\.quickshell$"; }
                ]
                ++ floatingApps
                ++ [
                  {
                    app-id = "^firefox";
                    title = "^Picture-in-Picture$";
                  }
                  { title = "^Picture in picture$"; }
                ];
                open-floating = true;
              }

              {
                matches = [ { app-id = "^1password$"; } ];
                open-floating = true;
                block-out-from = "screencast";
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
