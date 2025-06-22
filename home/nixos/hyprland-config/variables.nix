{
  wayland.windowManager.hyprland.settings = {
    # Variables
    "$mod" = "SUPER";
    "$terminal" = "ghostty";
    "$fileManager" = "ghostty -e yazi";
    "$menu" = "fuzzel --launch-prefix='uwsm app -- '";

    # Monitor configuration (placeholder - adjust for actual setup)
    monitor = [
      # Main monitor example (adjust resolution/refresh rate as needed)
      "DP-1,3440x1440@165,0x0,1,bitdepth,10,vrr,1"
      # Additional monitors can be added here
    ];

    # Input settings
    input = {
      kb_layout = "us";
      follow_mouse = 1;
      sensitivity = 0; # -1.0 - 1.0, 0 means no modification

      touchpad = {
        natural_scroll = false;
      };
    };

    # Gestures
    gestures = {
      workspace_swipe = false;
    };

    # Dwindle layout settings
    dwindle = {
      pseudotile = true; # Master switch for pseudotiling
      preserve_split = true; # You probably want this
    };

    # Master layout settings
    master = {
      new_status = "master";
    };
  };
}