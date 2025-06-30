{ pkgs, ... }:
{
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # Start other services
      "uwsm app hyprpanel"
      "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      "uwsm app waybar"
      "systemctl --user enable --now ratbagd.service"
      "systemctl --user enable --now sunshine"
      "pw-link 'Main-Output-Proxy:monitor_FL' 'alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX0'"
      "pw-link 'Main-Output-Proxy:monitor_FR' 'alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX1'"
      "uwsm app nwg-dock-hyprland -- -d"
      "uwsm app nwg-drawer -- -r"
      "uwsm app clipse -- -listen"
    ];
  };
}
