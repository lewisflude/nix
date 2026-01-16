# Screenshot Keybindings
# Screenshot capture and clipboard operations
{
  pkgs,
  lib,
  ...
}:
let
  cmd = import ../lib/shell-commands.nix { inherit pkgs lib; };
in
{
  # Full screen - save and copy to clipboard
  "Print" = {
    allow-inhibiting = false;
    action.spawn = cmd.screenshot.fullScreenCopy;
  };

  # Area selection with satty annotation
  "Mod+Shift+Print" = {
    allow-inhibiting = false;
    action.spawn = cmd.screenshot.areaSatty;
  };

  # Area selection with satty annotation (alternative binding)
  "Shift+Print" = {
    allow-inhibiting = false;
    action.spawn = cmd.screenshot.areaSatty;
  };

  # Full screen with satty annotation
  "Ctrl+Print" = {
    allow-inhibiting = false;
    action.spawn = cmd.screenshot.fullScreenSatty;
  };

  # Area to clipboard only (no file save)
  "Alt+Print" = {
    allow-inhibiting = false;
    action.spawn = cmd.screenshot.areaClipboard;
  };

  # Area - save and copy to clipboard
  "Mod+Ctrl+Shift+Print" = {
    allow-inhibiting = false;
    action.spawn = cmd.screenshot.areaSaveAndCopy;
  };

  # Standard region screenshot (Windows/macOS muscle memory)
  "Mod+Shift+S" = {
    allow-inhibiting = false;
    action.spawn = cmd.screenshot.regionCapture;
  };

  # Color picker
  "Mod+Shift+C".action.spawn = [
    (lib.getExe pkgs.hyprpicker)
    "-a"
  ];
}
