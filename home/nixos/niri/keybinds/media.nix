# Media Keybindings
# Audio controls, brightness, and media playback
{
  config,
  pkgs,
  lib,
  ...
}:
let
  brightness = "${config.home.homeDirectory}/bin/brightness";
  terminal = lib.getExe pkgs.ghostty;
in
{
  # Audio playback controls
  "XF86AudioPlay" = {
    allow-when-locked = true;
    action.spawn = [
      "playerctl"
      "play-pause"
    ];
  };
  "XF86AudioNext" = {
    allow-when-locked = true;
    action.spawn = [
      "playerctl"
      "next"
    ];
  };
  "XF86AudioPrev" = {
    allow-when-locked = true;
    action.spawn = [
      "playerctl"
      "previous"
    ];
  };

  # Brightness controls
  "XF86MonBrightnessUp" = {
    allow-when-locked = true;
    action.spawn = [
      brightness
      "up"
    ];
  };
  "XF86MonBrightnessDown" = {
    allow-when-locked = true;
    action.spawn = [
      brightness
      "down"
    ];
  };

  # Volume controls
  "XF86AudioRaiseVolume" = {
    allow-when-locked = true;
    action.spawn = [
      "wpctl"
      "set-volume"
      "@DEFAULT_AUDIO_SINK@"
      "0.1+"
      "--limit"
      "1"
    ];
  };
  "XF86AudioLowerVolume" = {
    allow-when-locked = true;
    action.spawn = [
      "wpctl"
      "set-volume"
      "@DEFAULT_AUDIO_SINK@"
      "0.1-"
    ];
  };
  "XF86AudioMute" = {
    allow-when-locked = true;
    action.spawn = [
      "wpctl"
      "set-mute"
      "@DEFAULT_AUDIO_SINK@"
      "toggle"
    ];
  };
  "XF86AudioMicMute" = {
    allow-when-locked = true;
    action.spawn = [
      "wpctl"
      "set-mute"
      "@DEFAULT_AUDIO_SOURCE@"
      "toggle"
    ];
  };

  # Audio mixer shortcuts
  "Mod+Alt+V".action.spawn = [ (lib.getExe pkgs.pwvucontrol) ];
  "Mod+Ctrl+V".action.spawn = [
    terminal
    "-e"
    "pulsemixer"
  ];
}
