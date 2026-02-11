# XDG Desktop Portal Module - Dendritic Pattern
# Portal services for sandboxed applications
_:
{
  flake.modules.nixos.xdgPortal =
    { pkgs, ... }:
    {
      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
        ];
        config = {
          common = {
            default = [ "gtk" ];
          };
          niri = {
            default = [
              "gnome"
              "gtk"
            ];
            "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
          };
        };
      };
    };
}
