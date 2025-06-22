{ ... }: {
  wayland.windowManager.hyprland.settings = {
    # Auto-start applications
    exec-once = [
      # Desktop environment essentials
      "waybar &"                    # Status bar
      "mako &"                      # Notification daemon
      "hyprpaper &"                 # Wallpaper daemon
      "hypridle &"                  # Idle management
      
      # Desktop utilities
      "nwg-dock-hyprland &"         # Dock
      "nwg-drawer &"                # Application drawer
      "clipse -daemon &"            # Clipboard manager daemon
      
      # Authentication agent
      "/run/current-system/sw/libexec/polkit-gnome-authentication-agent-1 &"
      
      # Audio routing (adjust device IDs as needed)
      # "pw-link \"Apogee Symphony Desktop:capture_FL\" \"PipeWire ALSA [Audio]:playback_FL\" &"
      # "pw-link \"Apogee Symphony Desktop:capture_FR\" \"PipeWire ALSA [Audio]:playback_FR\" &"
      
      # System services
      "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &"
      "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &"
      
      # Hardware-specific services (uncomment as needed)
      # "ratbagd &"                 # Gaming mouse configuration
      # "solaar -w hide &"          # Logitech device manager
      
      # Wlroots screen sharing
      "systemctl --user start xdg-desktop-portal-wlr &"
    ];
  };
}