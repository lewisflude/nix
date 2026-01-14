# Window Management Keybindings
# Window operations: close, maximize, fullscreen, floating, etc.
{
  pkgs,
  # lib,
  ...
}:
{
  # Close window
  "Mod+Q".action.close-window = { };

  # Force kill focused window (for unresponsive apps)
  "Mod+Shift+Q".action.spawn = [
    "sh"
    "-c"
    "PID=$(${pkgs.niri}/bin/niri msg focused-window | ${pkgs.jq}/bin/jq -r '.pid // empty'); [ -n \"$PID\" ] && kill -9 \"$PID\""
  ];

  # Window state toggles
  "Mod+Grave".action.toggle-window-floating = { };
  "Mod+F".action.maximize-column = { };
  "Mod+Shift+F".action.fullscreen-window = { };
  "Mod+Ctrl+Shift+F".action.toggle-windowed-fullscreen = { };
  "Mod+Ctrl+F".action.expand-column-to-available-width = { };
}
