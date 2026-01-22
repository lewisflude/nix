# System Keybindings
# System controls, power management, notifications, and system actions
{
  pkgs,
  lib,
  ...
}:
let
  cmd = import ../lib/shell-commands.nix { inherit pkgs lib; };
  screenLocker = lib.getExe pkgs.swaylock-effects;
in
{
  "Mod+Shift+Slash".action.show-hotkey-overlay = { };
  "Mod+Escape" = {
    allow-inhibiting = false;
    action.toggle-keyboard-shortcuts-inhibit = { };
  };

  # Screen lock - -f flag is required for proper ext-session-lock integration with niri
  "Super+Alt+L".action.spawn = [
    screenLocker
    "-f"
  ];

  "Mod+Shift+P".action.power-off-monitors = { };
  "Mod+Shift+D".action.spawn = cmd.system.toggleDisplays;

  "Mod+Shift+E".action.quit = { };
  "Ctrl+Alt+Delete".action.quit = { };

  "Mod+Ctrl+Shift+R".action.spawn = [
    "niri"
    "msg"
    "action"
    "reload-config"
  ];

  "Mod+X".action.spawn = cmd.system.powerMenu;

  "Mod+Alt+S" = {
    action.spawn = [
      "systemctl"
      "suspend"
    ];
  };

  "Mod+Alt+H" = {
    action.spawn = [
      "systemctl"
      "hibernate"
    ];
  };

  # Notification controls
  "Mod+N" = {
    action.spawn = [
      "makoctl"
      "dismiss"
    ];
  };
  "Mod+Shift+N" = {
    action.spawn = [
      "makoctl"
      "dismiss"
      "--all"
    ];
  };
  "Mod+Ctrl+N" = {
    action.spawn = [
      "makoctl"
      "invoke"
    ];
  };
}
