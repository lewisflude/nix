{
  wayland.windowManager.hyprland.settings = {
    # Variables
    "$mod" = "SUPER";
    "$terminal" = "ghostty";
    "$fileManager" = "ghostty -e yazi";
    "$menu" = "fuzzel --launch-prefix='uwsm app -- '";

    monitor = [ ",preferred,auto,1" ];

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
