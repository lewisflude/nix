{ pkgs, ... }:
{
  home.packages = with pkgs; [
    polkit_gnome
  ];

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # Authentication agent
      "uwsm app -- ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"

      "systemctl enable - -user com.mitchellh.ghostty.service"

      # UI components
      "systemctl - -user enable - -now hyprpolkitagent.service"
      "uwsm app -- nwg-dock-hyprland -d"
      "uwsm app -- nwg-drawer -r"

      # Audio routing for Apogee Symphony Desktop
      "pw-link 'Main-Output-Proxy:monitor_FL' 'alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX0'"
      "pw-link 'Main-Output-Proxy:monitor_FR' 'alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX1'"
    ];
  };
}
