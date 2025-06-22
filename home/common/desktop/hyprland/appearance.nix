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
    };

    ecosystem = {
      no_donation_nag = true;
      no_update_news = true;
    };
  };
}
