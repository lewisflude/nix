# Niri Keybindings - Consolidated
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) recursiveUpdate;
  cmd = import ../lib/shell-commands.nix { inherit pkgs lib; };

  coreBinds = {
  # Window management
  "Mod+Q".action.close-window = {};
  "Mod+Shift+Q".action.spawn = cmd.window.forceKill;
  "Mod+Grave".action.toggle-window-floating = {};
  "Mod+F".action.maximize-column = {};
  "Mod+Shift+F".action.fullscreen-window = {};
  "Mod+Ctrl+Shift+F".action.toggle-windowed-fullscreen = {};
  "Mod+Ctrl+F".action.expand-column-to-available-width = {};

  # Window navigation
  "Mod+Down".action.focus-window-down = {};
  "Mod+Up".action.focus-window-up = {};
  "Mod+J".action.focus-window-down = {};
  "Mod+K".action.focus-window-up = {};
  "Mod+Ctrl+Down".action.move-window-down = {};
  "Mod+Ctrl+Up".action.move-window-up = {};
  "Mod+Ctrl+J".action.move-window-down = {};
  "Mod+Ctrl+K".action.move-window-up = {};

  # Workspace navigation
  "Mod+Page_Down".action.focus-workspace-down = {};
  "Mod+Page_Up".action.focus-workspace-up = {};
  "Mod+U".action.focus-workspace-up = {};
  "Mod+I".action.focus-workspace-down = {};
  "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = {};
  "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = {};
  "Mod+Ctrl+U".action.move-column-to-workspace-up = {};
  "Mod+Ctrl+I".action.move-column-to-workspace-down = {};
  "Mod+Shift+Page_Down".action.move-workspace-down = {};
  "Mod+Shift+Page_Up".action.move-workspace-up = {};
  "Mod+Shift+U".action.move-workspace-up = {};
  "Mod+Shift+I".action.move-workspace-down = {};
  "Alt+Tab".action.focus-window-or-workspace-down = {};
  "Alt+Shift+Tab".action.focus-window-or-workspace-up = {};
  "Mod+O".action.toggle-overview = {};

  # Column layout
  "Mod+R".action.switch-preset-column-width = {};
  "Mod+Minus".action.set-column-width = "-10%";
  "Mod+Equal".action.set-column-width = "+10%";
  "Mod+Shift+R".action.switch-preset-window-height = {};
  "Mod+Ctrl+R".action.reset-window-height = {};
  "Mod+Shift+Minus".action.set-window-height = "-10%";
  "Mod+Shift+Equal".action.set-window-height = "+10%";
  "Mod+C".action.center-column = {};
  "Mod+Ctrl+C".action.center-visible-columns = {};
  "Mod+BracketLeft".action.consume-or-expel-window-left = {};
  "Mod+BracketRight".action.consume-or-expel-window-right = {};
  "Mod+Comma".action.consume-window-into-column = {};
  "Mod+Period".action.expel-window-from-column = {};
  "Mod+W".action.toggle-column-tabbed-display = {};
  "Mod+Left".action.focus-column-left = {};
  "Mod+Right".action.focus-column-right = {};
  "Mod+H".action.focus-column-left = {};
  "Mod+L".action.focus-column-right = {};
  "Mod+Home".action.focus-column-first = {};
  "Mod+End".action.focus-column-last = {};
  "Mod+Ctrl+Home".action.move-column-to-first = {};
  "Mod+Ctrl+End".action.move-column-to-last = {};
  "Mod+Ctrl+Left".action.move-column-left = {};
  "Mod+Ctrl+Right".action.move-column-right = {};
  "Mod+Ctrl+H".action.move-column-left = {};
  "Mod+Ctrl+L".action.move-column-right = {};
  "F16".action.maximize-column = {};
  "F18".action.center-column = {};
  "F17".action.set-column-width = "50%";
  "F19".action.set-column-width = "50%";

  # Monitor management
  "Mod+Shift+Left".action.focus-monitor-left = {};
  "Mod+Shift+Down".action.focus-monitor-down = {};
  "Mod+Shift+Up".action.focus-monitor-up = {};
  "Mod+Shift+Right".action.focus-monitor-right = {};
  "Mod+Shift+H".action.focus-monitor-left = {};
  "Mod+Shift+J".action.focus-monitor-down = {};
  "Mod+Shift+K".action.focus-monitor-up = {};
  "Mod+Shift+L".action.focus-monitor-right = {};
  "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = {};
  "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = {};
  "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = {};
  "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = {};
  "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = {};
  "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = {};
  "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = {};
  "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = {};
  "Mod+Alt+O".action.spawn = cmd.monitor.showOutputInfo;

  # Mouse controls
  "Mod+WheelScrollDown" = { cooldown-ms = 150; action.focus-column-right = {}; };
  "Mod+WheelScrollUp" = { cooldown-ms = 150; action.focus-column-left = {}; };
  "Mod+Ctrl+WheelScrollDown" = { cooldown-ms = 150; action.move-column-right = {}; };
  "Mod+Ctrl+WheelScrollUp" = { cooldown-ms = 150; action.move-column-left = {}; };
  "Mod+Shift+WheelScrollDown" = { cooldown-ms = 150; action.focus-workspace-down = {}; };
  "Mod+Shift+WheelScrollUp" = { cooldown-ms = 150; action.focus-workspace-up = {}; };
  "Mod+Ctrl+Shift+WheelScrollDown" = { cooldown-ms = 150; action.move-column-to-workspace-down = {}; };
  "Mod+Ctrl+Shift+WheelScrollUp" = { cooldown-ms = 150; action.move-column-to-workspace-up = {}; };
  "Mod+WheelScrollRight" = { cooldown-ms = 150; action.focus-column-right = {}; };
  "Mod+WheelScrollLeft" = { cooldown-ms = 150; action.focus-column-left = {}; };
  "Mod+Ctrl+WheelScrollRight" = { cooldown-ms = 150; action.move-column-right = {}; };
  "Mod+Ctrl+WheelScrollLeft" = { cooldown-ms = 150; action.move-column-left = {}; };
  };

  appsBinds = import ./apps.nix { inherit config pkgs lib; };
in
recursiveUpdate coreBinds appsBinds
