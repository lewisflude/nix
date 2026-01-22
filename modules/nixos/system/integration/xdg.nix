{ pkgs, ... }:
{
  # XDG Desktop Portal configuration optimized for Niri
  # Uses GNOME portal for comprehensive feature support
  # Recommended by Niri author for full feature support including:
  # - Window-level screencasting (not just full screen)
  # - Ability to hide sensitive windows from casts
  # - Better compatibility with Electron apps (Discord, Teams, etc.)
  # - Modern GTK 4 UI with 17 portal interfaces
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    xdgOpenUsePortal = false;
    config = {
      # Niri-specific configuration
      niri = {
        default = [ "gnome" ];
        # Use GTK portal for file picker and app chooser
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
      };

      # Fallback configuration for other Wayland sessions
      common = {
        default = [ "gnome" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
      };
    };
  };

  # Required for GNOME portal to work properly
  programs.dconf.enable = true;
}
