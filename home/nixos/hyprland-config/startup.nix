{ pkgs, ... }:
{
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # Authentication agent
      "uwsm app --${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"

      # UI components
      "uwsm app -- waybar"
      "uwsm app -- nwg-dock-hyprland -- -d"
      "uwsm app -- nwg-drawer -- -r"

      # Utilities
      "uwsm app -- clipse -- -listen"

      # Audio routing for Apogee Symphony Desktop
      "pw-link 'Main-Output-Proxy:monitor_FL' 'alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX0'"
      "pw-link 'Main-Output-Proxy:monitor_FR' 'alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX1'"
    ];
  };
}
