# Window Management Keybindings
# Window operations: close, maximize, fullscreen, floating, etc.
{
  pkgs,
  lib,
  ...
}:
let
  cmd = import ../lib/shell-commands.nix { inherit pkgs lib; };
in
{
  # Close window
  "Mod+Q".action.close-window = { };

  # Force kill focused window (for unresponsive apps)
  "Mod+Shift+Q".action.spawn = cmd.window.forceKill;

  # Window state toggles
  "Mod+Grave".action.toggle-window-floating = { };
  "Mod+F".action.maximize-column = { };
  "Mod+Shift+F".action.fullscreen-window = { };
  "Mod+Ctrl+Shift+F".action.toggle-windowed-fullscreen = { };
  "Mod+Ctrl+F".action.expand-column-to-available-width = { };
}
