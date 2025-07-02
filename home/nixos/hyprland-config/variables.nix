{
  pkgs,
  ...
}:

let
  builtGhostty = "${pkgs.ghostty}/bin/ghostty";

in

{
  wayland.windowManager.hyprland.settings = {
    "$mainMod" = "SUPER";
    "$terminal" = builtGhostty;
    "$fileManager" = builtGhostty + " -e yazi";
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
