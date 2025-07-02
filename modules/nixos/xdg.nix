{
  pkgs,
  system,
  ...
}:
{
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-gnome
    ];
    config = {
      common.default = "gtk";
      pantheon.default = "gtk";
      gtk.default = "gtk";
    };
  };
}
