# Monitor/Output Management Keybindings
# Multi-monitor navigation and column movement
{
  pkgs,
  lib,
  ...
}:
let
  cmd = import ../lib/shell-commands.nix { inherit pkgs lib; };
in
{
  # Monitor focus
  "Mod+Shift+Left".action.focus-monitor-left = { };
  "Mod+Shift+Down".action.focus-monitor-down = { };
  "Mod+Shift+Up".action.focus-monitor-up = { };
  "Mod+Shift+Right".action.focus-monitor-right = { };
  "Mod+Shift+H".action.focus-monitor-left = { };
  "Mod+Shift+J".action.focus-monitor-down = { };
  "Mod+Shift+K".action.focus-monitor-up = { };
  "Mod+Shift+L".action.focus-monitor-right = { };

  # Move column to monitor
  "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = { };
  "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = { };
  "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = { };
  "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = { };
  "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = { };
  "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = { };
  "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = { };
  "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = { };

  # Display output info
  "Mod+Alt+O".action.spawn = cmd.monitor.showOutputInfo;
}
