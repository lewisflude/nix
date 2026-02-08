# XDG Desktop Portal Module - Dendritic Pattern
# Portal services for sandboxed applications
{ ... }:
{
  flake.modules.nixos.xdgPortal =
    { pkgs, lib, ... }:
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
