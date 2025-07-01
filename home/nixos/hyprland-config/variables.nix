{
  ...
}:

{
  wayland.windowManager.hyprland.settings = {
    "$mainMod" = "SUPER";
    "$terminal" = "ghostty";
    "$fileManager" = "ghostty -e yazi";
    "$menu" = "fuzzel --launch-prefix='uwsm app -- '";

    input = {
      kb_layout = "us";
      follow_mouse = 1;
      sensitivity = 0;
      touchpad = {
        natural_scroll = false;
      };
    };
    gestures = {
      workspace_swipe = false;
    };
    dwindle = {
      pseudotile = true;
      preserve_split = true;
    };
    master = {
      new_status = "master";
    };
  };
}
