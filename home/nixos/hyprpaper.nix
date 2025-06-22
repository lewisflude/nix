{ ... }: {
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
      splash_offset = 2.0;
      
      # Preload wallpapers (adjust paths as needed)
      preload = [
        "~/Pictures/wallpapers/default.jpg"
        "~/Pictures/wallpapers/secondary.jpg"
      ];
      
      # Set wallpapers for monitors (adjust monitor names as needed)
      wallpaper = [
        # Main monitor
        "DP-1,~/Pictures/wallpapers/default.jpg"
        # Secondary monitor example
        # "HDMI-A-1,~/Pictures/wallpapers/secondary.jpg"
        # Fallback for any unspecified monitor
        ",~/Pictures/wallpapers/default.jpg"
      ];
    };
  };
}