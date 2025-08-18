{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;

    # Optimized portals for Wayland-native performance
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
    ];

    # Disable GNOME portal to prevent conflicts
    xdgOpenUsePortal = true;

    # Specific portal assignments for optimal Wayland performance
    config = {
      common = {
        default = [ "gtk" ];
        # WLR handles Wayland-specific features better
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
        "org.freedesktop.impl.portal.Wallpaper" = [ "wlr" ];
        # GTK handles file dialogs and general UI better
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
      };
      niri = {
        default = [ "gtk" ];
        # Same optimized assignments for Niri
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
        "org.freedesktop.impl.portal.Wallpaper" = [ "wlr" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
        # Explicitly disable problematic portal interfaces that might interfere with niri window management
        "org.freedesktop.impl.portal.Inhibit" = [ "gtk" ];
        "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
      };
    };
  };

  # Essential for GTK apps and portals on Wayland
  programs.dconf.enable = true;
}
