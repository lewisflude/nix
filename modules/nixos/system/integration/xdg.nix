{ pkgs, ... }:
{
  # XDG Desktop Portal configuration optimized for Niri
  # Uses GNOME portal for advanced screencasting features (window-level sharing)
  # while keeping GTK for lighter UI elements
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome # Recommended by Niri author for full feature support
    ];
    xdgOpenUsePortal = true;
    config = {
      # Niri-specific configuration (hybrid approach)
      niri = {
        default = [ "gtk" ];

        # GNOME portal for advanced features:
        # - Window-level screencasting (not just full screen)
        # - Ability to hide sensitive windows from casts
        # - Better compatibility with Electron apps (Discord, Teams, etc.)
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];

        # GTK portal for lightweight UI elements
        # Avoids pulling in heavy GNOME UI dependencies
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.Settings" = [ "gtk" ];

        # Session management
        "org.freedesktop.impl.portal.Inhibit" = [ "gtk" ];
        "org.freedesktop.impl.portal.Notification" = [ "gtk" ];
      };

      # Fallback configuration for other Wayland sessions
      common = {
        default = [ "gtk" ];
      };
    };
  };

  # Required for GTK portal to work properly
  programs.dconf.enable = true;
}
