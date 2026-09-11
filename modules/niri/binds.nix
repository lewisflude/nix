# Niri key bindings.
#
# Sizing and focus binds follow niri's own default config where a default
# exists, so the upstream wiki and the hotkey overlay describe this session
# accurately. Divergences are the DMS IPC binds, the vim-direction navigation,
# and the scroll binds.
#
# Mod+Tab and Alt+Tab are deliberately left unbound: niri's recent-windows
# switcher claims them by default and DMS themes it through dms/alttab.kdl.
_: {
  flake.modules.homeManager.niri =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      programs.niri.settings.binds =
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
        in
        {
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
          # Tells the window it is fullscreen without resizing it — for
          # screencasting browser-based presentations without the browser UI.
          "Mod+Ctrl+Shift+F" = mkTitled "toggle-windowed-fullscreen" "Windowed Fullscreen";
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

          # Swap the focused window with its neighbour, keeping both in place
          # in the strip — unlike move-column-*, which carries the whole column.
          "Mod+Alt+H" = mkTitled "swap-window-left" "Swap Window Left";
          "Mod+Alt+L" = mkTitled "swap-window-right" "Swap Window Right";

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
          "Mod+Shift+R" = mkTitled "switch-preset-column-width-back" "Cycle Column Width Presets (Back)";
          "Mod+Ctrl+Shift+R" = mkTitled "switch-preset-window-height" "Cycle Window Height Presets";
          "Mod+Ctrl+R" = mkTitled "reset-window-height" "Reset Window Height";
          "Mod+C" = mkTitled "center-column" "Center Column";
          "Mod+Shift+C" = mkTitled "center-window" "Center Window";
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
    };
}
