{pkgs, ...}: {
  xdg.portal = {
    enable = true;

    # Optimized portals for Wayland-native performance
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
    ];

    # Specific portal assignments for optimal Wayland performance
    config = {
      common = {
        default = ["gtk"];
        # WLR handles Wayland-specific features better
        "org.freedesktop.impl.portal.Screenshot" = ["wlr"];
        "org.freedesktop.impl.portal.ScreenCast" = ["wlr"];
        "org.freedesktop.impl.portal.Wallpaper" = ["wlr"];
        # GTK handles file dialogs and general UI better
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
        "org.freedesktop.impl.portal.AppChooser" = ["gtk"];
      };
      niri = {
        default = ["gtk"];
        # Same optimized assignments for Niri
        "org.freedesktop.impl.portal.Screenshot" = ["wlr"];
        "org.freedesktop.impl.portal.ScreenCast" = ["wlr"];
        "org.freedesktop.impl.portal.Wallpaper" = ["wlr"];
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
        "org.freedesktop.impl.portal.AppChooser" = ["gtk"];
      };
    };
  };

  # Essential for GTK apps and portals on Wayland
  programs.dconf.enable = true;
}
