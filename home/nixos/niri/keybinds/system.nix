# System Keybindings
# System controls, power management, notifications, and system actions
{
  pkgs,
  lib,
  ...
}:
let
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
  "Mod+Shift+D" = {
    action.spawn = [
      "sh"
      "-c"
      "niri msg action power-off-monitors && sleep 2 && niri msg action power-on-monitors"
    ];
  };

  "Mod+Shift+E".action.quit = { };
  "Ctrl+Alt+Delete".action.quit = { };

  "Mod+Ctrl+Shift+R".action.spawn = [
    "niri"
    "msg"
    "action"
    "reload-config"
  ];

  "Mod+X" = {
    action.spawn = [
      "sh"
      "-c"
      ''
        OPTIONS="Logout\nSuspend\nHibernate\nReboot\nShutdown"
        CHOICE=$(echo -e "$OPTIONS" | fuzzel --dmenu --prompt 'Power:')
        case "$CHOICE" in
          Logout) niri msg action quit ;;
          Suspend) systemctl suspend ;;
          Hibernate) systemctl hibernate ;;
          Reboot) systemctl reboot ;;
          Shutdown) systemctl poweroff ;;
        esac
      ''
    ];
  };

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
