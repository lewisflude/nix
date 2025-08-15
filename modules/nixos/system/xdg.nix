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
      common.default = [
        "wlr"
        "gtk"
      ];
      niri.default = [
        "wlr"
        "gtk"
      ];
      gtk.default = "gtk";
    };
  };

  # Optional but often helpful when using GTK apps & portals:
  programs.dconf.enable = true;
}
