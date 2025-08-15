{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;

    # Use GTK for file dialogs; WLR for screencast/screen-share on Wayland
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
    ];

    # Keep defaults simple and compositor-agnostic
    config = {
      common.default = "gtk";
      gtk.default = "gtk";
      # Optional: if you want to be explicit for niri:
      niri.default = "gtk";
    };
  };

  # Optional but often helpful when using GTK apps & portals:
  programs.dconf.enable = true;
}
