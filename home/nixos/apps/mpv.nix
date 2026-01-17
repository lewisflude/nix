{
  ...
}:
{
  programs.mpv = {
    enable = true;

    # Note: Theming removed - should come from signal-nix when MPV support is added
    # Using mpv defaults for now
    config = {
      # Wayland output
      vo = "wayland";
      gpu-context = "wayland";
      hwdec = "auto-safe";

      # OSD text styling
      osd-font-size = 24;
      osd-duration = 2000;
      osd-margin-x = 40;
      osd-margin-y = 40;

      # OSD bar styling
      osd-bar-align-y = "0.9";
      osd-bar-w = 100;
      osd-bar-h = 2;
      osd-bar-border-size = 1;
      osd-bar-pos-y = "0.9";

      # Cache settings
      cache = "yes";
      cache-secs = 60;
      demuxer-max-bytes = "500M";
      demuxer-max-back-bytes = "500M";
    };
  };
}
