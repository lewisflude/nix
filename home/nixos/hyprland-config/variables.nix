{ config, ... }:
{
  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";
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

  xdg.configFile."uwsm/env".text = ''
    export GDK_BACKEND=wayland,x11
    export GDK_SCALE=1.25
    export GDK_DPI_SCALE=0.8
    export QT_QPA_PLATFORM=wayland;xcb
    export SDL_VIDEODRIVER=wayland
    export CLUTTER_BACKEND=wayland
    export QT_AUTO_SCREEN_SCALE_FACTOR=1
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export QT_QPA_PLATFORMTHEME=qt5ct
    export GTK_THEME=Catppuccin-GTK-Dark
    export XCURSOR_THEME=catppuccin-mocha-mauve-cursors
    export XCURSOR_SIZE=24
  '';

  xdg.configFile."uwsm/env-hyprland".text = ''
    export GBM_BACKEND=nvidia-drm
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export LIBVA_DRIVER_NAME=nvidia
    export __GL_GSYNC_ALLOWED=1
    export __GL_VRR_ALLOWED=0
  '';
}
