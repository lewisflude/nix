# Application, Media & System Keybindings
{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) getExe;
  cmd = import ../lib/shell-commands.nix { inherit pkgs lib; };
  brightness = "${config.home.homeDirectory}/bin/brightness";
  screenLocker = getExe pkgs.swaylock-effects;
  terminal = getExe pkgs.ghostty;

  uwsmApp = app: [ (getExe pkgs.uwsm) "app" "--" app ];
  termWith = cmd: [ terminal "-e" cmd ];
  termWithArgs = args: [ terminal "-e" ] ++ args;
  launcher = uwsmApp (getExe pkgs.fuzzel);
in
{
  # System controls
  "Mod+Shift+Slash".action.show-hotkey-overlay = {};
  "Mod+Escape" = { allow-inhibiting = false; action.toggle-keyboard-shortcuts-inhibit = {}; };
  "Super+Alt+L".action.spawn = [ screenLocker "-f" ];
  "Mod+Shift+P".action.power-off-monitors = {};
  "Mod+Shift+D".action.spawn = cmd.system.toggleDisplays;
  "Mod+Shift+E".action.quit = {};
  "Ctrl+Alt+Delete".action.quit = {};
  "Mod+Ctrl+Shift+R".action.spawn = [ "niri" "msg" "action" "reload-config" ];
  "Mod+X".action.spawn = cmd.system.powerMenu;
  "Mod+Alt+S".action.spawn = [ "systemctl" "suspend" ];
  "Mod+Alt+H".action.spawn = [ "systemctl" "hibernate" ];

  # Notifications
  "Mod+N".action.spawn = [ "makoctl" "dismiss" ];
  "Mod+Shift+N".action.spawn = [ "makoctl" "dismiss" "--all" ];
  "Mod+Ctrl+N".action.spawn = [ "makoctl" "invoke" ];

  # Applications
  "F13".action.spawn = [ terminal ];
  "Mod+T".action.spawn = [ terminal ];
  "Mod+D".action.spawn = launcher;
  "Mod+B".action.spawn = uwsmApp (getExe pkgs.google-chrome);
  "Mod+Ctrl+O".action.spawn = uwsmApp (getExe pkgs.obsidian);
  "Mod+M".action.spawn = uwsmApp (getExe pkgs.thunderbird);
  "Mod+E".action.spawn = termWith "yazi";
  "Mod+Shift+O".action.spawn = termWithArgs [ (getExe pkgs.helix) "${config.home.homeDirectory}/.config/nix" ];
  "Mod+V".action.spawn = [ "sh" "-c" "cliphist list | fuzzel --dmenu | cliphist decode" ];

  # Media playback
  "XF86AudioPlay" = { allow-when-locked = true; action.spawn = [ "playerctl" "play-pause" ]; };
  "XF86AudioNext" = { allow-when-locked = true; action.spawn = [ "playerctl" "next" ]; };
  "XF86AudioPrev" = { allow-when-locked = true; action.spawn = [ "playerctl" "previous" ]; };

  # Brightness
  "XF86MonBrightnessUp" = { allow-when-locked = true; action.spawn = [ brightness "up" ]; };
  "XF86MonBrightnessDown" = { allow-when-locked = true; action.spawn = [ brightness "down" ]; };

  # Volume
  "XF86AudioRaiseVolume" = { allow-when-locked = true; action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+" "--limit" "1" ]; };
  "XF86AudioLowerVolume" = { allow-when-locked = true; action.spawn = [ "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-" ]; };
  "XF86AudioMute" = { allow-when-locked = true; action.spawn = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle" ]; };
  "XF86AudioMicMute" = { allow-when-locked = true; action.spawn = [ "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle" ]; };
  "Mod+Alt+V".action.spawn = [ (getExe pkgs.pwvucontrol) ];
  "Mod+Ctrl+V".action.spawn = termWith "pulsemixer";

  # Screenshots
  "Print" = { allow-inhibiting = false; action.spawn = cmd.screenshot.fullScreenCopy; };
  "Mod+Shift+Print" = { allow-inhibiting = false; action.spawn = cmd.screenshot.areaSatty; };
  "Shift+Print" = { allow-inhibiting = false; action.spawn = cmd.screenshot.areaSatty; };
  "Ctrl+Print" = { allow-inhibiting = false; action.spawn = cmd.screenshot.fullScreenSatty; };
  "Alt+Print" = { allow-inhibiting = false; action.spawn = cmd.screenshot.areaClipboard; };
  "Mod+Ctrl+Shift+Print" = { allow-inhibiting = false; action.spawn = cmd.screenshot.areaSaveAndCopy; };
  "Mod+Shift+S" = { allow-inhibiting = false; action.spawn = cmd.screenshot.regionCapture; };
  "Mod+Shift+C".action.spawn = [ (getExe pkgs.hyprpicker) "-a" ];
}
