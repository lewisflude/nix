{ pkgs, ... }: {
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # Start other services
      "hyprpanel"
      "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      "systemctl --user enable --now waybar.service"
      "systemctl --user enable --now ratbagd.service"
      "systemctl --user enable --now sunshine"
      "pw-link 'Main-Output-Proxy:monitor_FL' 'alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX0'"
      "pw-link 'Main-Output-Proxy:monitor_FR' 'alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0:playback_AUX1'"
      "nwg-dock-hyprland -d"
      "nwg-drawer -r"
      "clipse -listen"
    ];
  };
}
