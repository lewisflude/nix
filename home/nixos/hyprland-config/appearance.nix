{
  wayland.windowManager.hyprland.settings = {
    general = {
      allow_tearing = true;
      gaps_in = 6;
      gaps_out = 12;
      gaps_workspaces = 6;
      border_size = 2;
      resize_on_border = true;
      extend_border_grab_area = 15;
      hover_icon_on_border = true;
      layout = "dwindle";
      "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
      "col.inactive_border" = "rgba(595959aa)";
    };

    decoration = {
      rounding = 6;
      active_opacity = 1.0;
      inactive_opacity = 0.9;
      fullscreen_opacity = 1.0;
      blur = {
        enabled = true;
        size = 3;
        passes = 1;
        ignore_opacity = true;
      };
      drop_shadow = true;
      shadow_range = 4;
      shadow_render_power = 3;
      "col.shadow" = "rgba(1a1a1aee)";
    };

    # Animations
    animations = {
      enabled = true;
      bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
      animation = [
        "windows, 1, 7, myBezier"
        "windowsOut, 1, 7, default, popin 80%"
        "border, 1, 10, default"
        "borderangle, 1, 8, default"
        "fade, 1, 7, default"
        "workspaces, 1, 6, default"
      ];
    };

    ecosystem = {
      no_donation_nag = true;
      no_update_news = true;
    };
  };
}
