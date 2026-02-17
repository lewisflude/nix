# Niri compositor home-manager configuration (NixOS only)
# Dendritic pattern: Full implementation as flake.modules.homeManager.niriHome
_: {
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

          # Note: outputs and layout are managed by DankMaterialShell includes
          # See modules/desktop/dms.nix: filesToInclude = ["outputs", "layout", ...]
          # DMS also manages minimal binds via dms/binds.kdl (Mod+D, Mod+Return, workspaces, etc.)

          # Custom keybinds (declarative, following niri-flake + DMS best practices)
          binds = {
            # ═══════════════════════════════════════════════════════════════════
            # Overview & Help
            # ═══════════════════════════════════════════════════════════════════
            "Mod+O" = {
              action.toggle-overview = { };
              repeat = false;
              hotkey-overlay.title = "Toggle Overview";
            };
            "Mod+Shift+Slash" = {
              action.show-hotkey-overlay = { };
              hotkey-overlay.title = "Show Hotkey Overlay";
            };

            # ═══════════════════════════════════════════════════════════════════
            # Launch Applications
            # ═══════════════════════════════════════════════════════════════════
            # Note: Mod+Return (terminal) provided by DMS binds.kdl
            # DMS 1.4 binds.kdl generates incorrect spotlight command (missing "call"),
            # so we override Mod+D here with the correct IPC syntax.
            "Mod+D" = {
              action.spawn = [
                "dms"
                "ipc"
                "call"
                "spotlight"
                "toggle"
              ];
              hotkey-overlay.title = "Launch DMS Spotlight";
            };
            "Mod+T" = {
              action.spawn = [ "ghostty" ];
              hotkey-overlay.title = "Open Terminal";
            };
            "Mod+B" = {
              action.spawn = [ "google-chrome-stable" ];
              hotkey-overlay.title = "Open Browser";
            };

            # ═══════════════════════════════════════════════════════════════════
            # Window Actions
            # ═══════════════════════════════════════════════════════════════════
            "Mod+Q" = {
              action.close-window = { };
              hotkey-overlay.title = "Close Window";
            };

            # ═══════════════════════════════════════════════════════════════════
            # Focus Navigation
            # ═══════════════════════════════════════════════════════════════════
            "Mod+H".action.focus-column-left = { };
            "Mod+J".action.focus-window-down = { };
            "Mod+K".action.focus-window-up = { };
            "Mod+L".action.focus-column-right = { };
            "Mod+Left".action.focus-column-left = { };
            "Mod+Down".action.focus-window-down = { };
            "Mod+Up".action.focus-window-up = { };
            "Mod+Right".action.focus-column-right = { };

            # ═══════════════════════════════════════════════════════════════════
            # DMS Features
            # ═══════════════════════════════════════════════════════════════════
            "Mod+V" = {
              action.spawn = [
                "dms"
                "ipc"
                "clipboard"
                "toggle"
              ];
              hotkey-overlay.title = "Clipboard Manager";
            };
            "Mod+Escape" = {
              action.spawn = [
                "dms"
                "ipc"
                "lock"
                "lock"
              ];
              hotkey-overlay.title = "Lock Screen";
            };
            "Mod+Shift+E" = {
              action.spawn = [
                "dms"
                "ipc"
                "powermenu"
                "toggle"
              ];
              hotkey-overlay.title = "Power Menu";
            };
            "Mod+Comma" = {
              action.spawn = [
                "dms"
                "ipc"
                "settings"
                "toggle"
              ];
              hotkey-overlay.title = "Settings";
            };
            "Mod+N" = {
              action.spawn = [
                "dms"
                "ipc"
                "control-center"
                "toggle"
              ];
              hotkey-overlay.title = "Notifications";
            };
            "Mod+Slash" = {
              action.spawn = [
                "dms"
                "ipc"
                "keybinds"
                "toggle"
              ];
              hotkey-overlay.title = "Show Keybinds";
            };
            "Mod+Shift+T" = {
              action.spawn = [
                "dms"
                "ipc"
                "theme"
                "toggle"
              ];
              hotkey-overlay.title = "Toggle Light/Dark Theme";
            };

            # ═══════════════════════════════════════════════════════════════════
            # Window Management (beyond DMS defaults)
            # ═══════════════════════════════════════════════════════════════════
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
            # Note: Default Mod+V is toggle-window-floating, but we use it for clipboard
            # Use Mod+Space as alternative for toggling floating state
            "Mod+Space" = {
              action.toggle-window-floating = { };
              hotkey-overlay.title = "Toggle Window Floating";
            };
            "Mod+Shift+V" = {
              action.switch-focus-between-floating-and-tiling = { };
              hotkey-overlay.title = "Switch Focus Floating/Tiling";
            };

            # Window Movement (Ctrl variations for moving windows/columns)
            "Mod+Ctrl+H".action.move-column-left = { };
            "Mod+Ctrl+J".action.move-window-down = { };
            "Mod+Ctrl+K".action.move-window-up = { };
            "Mod+Ctrl+L".action.move-column-right = { };
            "Mod+Ctrl+Left".action.move-column-left = { };
            "Mod+Ctrl+Down".action.move-window-down = { };
            "Mod+Ctrl+Up".action.move-window-up = { };
            "Mod+Ctrl+Right".action.move-column-right = { };

            # First/Last column
            "Mod+Home".action.focus-column-first = { };
            "Mod+End".action.focus-column-last = { };
            "Mod+Ctrl+Home".action.move-column-to-first = { };
            "Mod+Ctrl+End".action.move-column-to-last = { };

            # ═══════════════════════════════════════════════════════════════════
            # Window Sizing
            # ═══════════════════════════════════════════════════════════════════
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

            # ═══════════════════════════════════════════════════════════════════
            # Column Management (consume/expel windows)
            # ═══════════════════════════════════════════════════════════════════
            "Mod+BracketLeft" = {
              action.consume-or-expel-window-left = { };
              hotkey-overlay.title = "Consume/Expel Window Left";
            };
            "Mod+BracketRight" = {
              action.consume-or-expel-window-right = { };
              hotkey-overlay.title = "Consume/Expel Window Right";
            };
            # Note: Default Mod+Comma is consume-window-into-column, but we use it for DMS settings
            # Using Mod+Shift+Comma as alternative
            "Mod+Shift+Comma" = {
              action.consume-window-into-column = { };
              hotkey-overlay.title = "Consume Window into Column";
            };
            "Mod+Period" = {
              action.expel-window-from-column = { };
              hotkey-overlay.title = "Expel Window from Column";
            };

            # ═══════════════════════════════════════════════════════════════════
            # Monitor Management
            # ═══════════════════════════════════════════════════════════════════
            "Mod+Shift+H".action.focus-monitor-left = { };
            "Mod+Shift+J".action.focus-monitor-down = { };
            "Mod+Shift+K".action.focus-monitor-up = { };
            "Mod+Shift+L".action.focus-monitor-right = { };
            "Mod+Shift+Left".action.focus-monitor-left = { };
            "Mod+Shift+Down".action.focus-monitor-down = { };
            "Mod+Shift+Up".action.focus-monitor-up = { };
            "Mod+Shift+Right".action.focus-monitor-right = { };

            # Move column to monitor
            "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = { };
            "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = { };
            "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = { };
            "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = { };
            "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = { };
            "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = { };
            "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = { };
            "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = { };

            # ═══════════════════════════════════════════════════════════════════
            # Additional Workspace Navigation (beyond 1-5 that DMS provides)
            # ═══════════════════════════════════════════════════════════════════
            # Focus workspaces 6-9
            "Mod+6".action.focus-workspace = 6;
            "Mod+7".action.focus-workspace = 7;
            "Mod+8".action.focus-workspace = 8;
            "Mod+9".action.focus-workspace = 9;

            # Move window to workspace (consistent with DMS behavior for 1-5)
            "Mod+Shift+6".action.move-window-to-workspace = 6;
            "Mod+Shift+7".action.move-window-to-workspace = 7;
            "Mod+Shift+8".action.move-window-to-workspace = 8;
            "Mod+Shift+9".action.move-window-to-workspace = 9;

            # Move entire column to workspace (upstream default pattern)
            "Mod+Ctrl+1".action.move-column-to-workspace = 1;
            "Mod+Ctrl+2".action.move-column-to-workspace = 2;
            "Mod+Ctrl+3".action.move-column-to-workspace = 3;
            "Mod+Ctrl+4".action.move-column-to-workspace = 4;
            "Mod+Ctrl+5".action.move-column-to-workspace = 5;
            "Mod+Ctrl+6".action.move-column-to-workspace = 6;
            "Mod+Ctrl+7".action.move-column-to-workspace = 7;
            "Mod+Ctrl+8".action.move-column-to-workspace = 8;
            "Mod+Ctrl+9".action.move-column-to-workspace = 9;

            # Workspace up/down
            "Mod+U".action.focus-workspace-down = { };
            "Mod+I".action.focus-workspace-up = { };
            "Mod+Page_Down".action.focus-workspace-down = { };
            "Mod+Page_Up".action.focus-workspace-up = { };
            "Mod+Ctrl+U".action.move-column-to-workspace-down = { };
            "Mod+Ctrl+I".action.move-column-to-workspace-up = { };
            "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = { };
            "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = { };

            # Move workspace itself
            "Mod+Shift+U".action.move-workspace-down = { };
            "Mod+Shift+I".action.move-workspace-up = { };
            "Mod+Shift+Page_Down".action.move-workspace-down = { };
            "Mod+Shift+Page_Up".action.move-workspace-up = { };

            # Workspace wheel scrolling (with cooldown)
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

            # Column wheel scrolling
            "Mod+WheelScrollRight".action.focus-column-right = { };
            "Mod+WheelScrollLeft".action.focus-column-left = { };
            "Mod+Ctrl+WheelScrollRight".action.move-column-right = { };
            "Mod+Ctrl+WheelScrollLeft".action.move-column-left = { };

            # Alternate column wheel scrolling (Shift variants)
            "Mod+Shift+WheelScrollDown".action.focus-column-right = { };
            "Mod+Shift+WheelScrollUp".action.focus-column-left = { };
            "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = { };
            "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = { };

            # ═══════════════════════════════════════════════════════════════════
            # Screenshots (DMS provides via niri 25.11+ IPC)
            # ═══════════════════════════════════════════════════════════════════
            "Print".action.screenshot = { };
            "Ctrl+Print".action.screenshot-screen = { };
            "Alt+Print".action.screenshot-window = { };

            # ═══════════════════════════════════════════════════════════════════
            # Media Keys (work when locked)
            # ═══════════════════════════════════════════════════════════════════
            "XF86AudioRaiseVolume" = {
              action.spawn = [
                "dms"
                "ipc"
                "audio"
                "increment"
              ];
              allow-when-locked = true;
            };
            "XF86AudioLowerVolume" = {
              action.spawn = [
                "dms"
                "ipc"
                "audio"
                "decrement"
              ];
              allow-when-locked = true;
            };
            "XF86AudioMute" = {
              action.spawn = [
                "dms"
                "ipc"
                "audio"
                "mute"
              ];
              allow-when-locked = true;
            };
            "XF86AudioMicMute" = {
              action.spawn = [
                "dms"
                "ipc"
                "audio"
                "micmute"
              ];
              allow-when-locked = true;
            };
            "XF86AudioPlay" = {
              action.spawn = [
                "dms"
                "ipc"
                "mpris"
                "playPause"
              ];
              allow-when-locked = true;
            };
            "XF86AudioStop" = {
              action.spawn = [
                "dms"
                "ipc"
                "mpris"
                "stop"
              ];
              allow-when-locked = true;
            };
            "XF86AudioNext" = {
              action.spawn = [
                "dms"
                "ipc"
                "mpris"
                "next"
              ];
              allow-when-locked = true;
            };
            "XF86AudioPrev" = {
              action.spawn = [
                "dms"
                "ipc"
                "mpris"
                "previous"
              ];
              allow-when-locked = true;
            };

            # Brightness keys
            "XF86MonBrightnessUp" = {
              action.spawn = [
                "dms"
                "ipc"
                "brightness"
                "increment"
              ];
              allow-when-locked = true;
            };
            "XF86MonBrightnessDown" = {
              action.spawn = [
                "dms"
                "ipc"
                "brightness"
                "decrement"
              ];
              allow-when-locked = true;
            };

            # ═══════════════════════════════════════════════════════════════════
            # System Control
            # ═══════════════════════════════════════════════════════════════════
            "Mod+Shift+P" = {
              action.power-off-monitors = { };
              hotkey-overlay.title = "Power Off Monitors";
            };

            # Safety escape hatch - CRITICAL: prevents apps from hijacking shortcuts
            "Mod+Shift+Escape" = {
              action.toggle-keyboard-shortcuts-inhibit = { };
              allow-inhibiting = false;
              hotkey-overlay.title = "Toggle Shortcut Inhibitor";
            };

            # Quit with confirmation
            "Ctrl+Alt+Delete" = {
              action.quit = { };
              hotkey-overlay.title = "Quit Niri";
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

          # Window rules (processed in order, last non-null value per property wins)
          window-rules =
            let
              r = 12.0;
            in
            [
              # Global: rounded corners (Material You aesthetic via DMS)
              {
                geometry-corner-radius = {
                  top-left = r;
                  top-right = r;
                  bottom-left = r;
                  bottom-right = r;
                };
                clip-to-geometry = true;
              }

              # Float dialog/utility windows
              {
                matches = [
                  { app-id = "xdg-desktop-portal-gtk"; }
                  { app-id = "xdg-desktop-portal-gnome"; }
                  { app-id = "^pinentry-"; }
                  { app-id = "gcr-prompter"; }
                  { app-id = "nm-connection-editor"; }
                  { app-id = "blueman-manager"; }
                  { app-id = "^pavucontrol$"; }
                  { app-id = "^pwvucontrol$"; }
                  { app-id = "org.gnome.Calculator"; }
                  { app-id = "zenity"; }
                ];
                open-floating = true;
              }

              # 1Password: float + hide from screencasts
              {
                matches = [ { app-id = "^1password$"; } ];
                open-floating = true;
                block-out-from = "screencast";
              }

              # Firefox/Chromium picture-in-picture
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

              # Steam games: fullscreen + VRR (AW3423DWF)
              {
                matches = [ { app-id = "^steam_app_"; } ];
                open-fullscreen = true;
                variable-refresh-rate = true;
              }

              # Gamescope
              {
                matches = [ { app-id = "^gamescope$"; } ];
                open-fullscreen = true;
                variable-refresh-rate = true;
              }

              # Steam client
              {
                matches = [ { app-id = "^steam$"; } ];
                default-column-width = {
                  proportion = 0.65;
                };
              }

              # Inactive window transparency
              {
                matches = [ { is-active = false; } ];
                opacity = 0.95;
              }
            ];

          # Startup commands
          # Note: DMS is launched via programs.dank-material-shell.niri.enableSpawn
          spawn-at-startup = [
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
                "HDMI-A-1"
                "off"
              ];
            }
          ];
        };
      };
    };
}
