{
  pkgs,
  lib,
  system,
  ...
}: let
  platformLib = (import ../../lib/functions.nix {inherit lib;}).withSystem system;
in {
  catppuccin = {
    flavor = "mocha";
    accent = "mauve";
    enable = true;
    waybar.mode = "createLink";
    mako.enable = lib.mkIf platformLib.isLinux true;
    swaync.enable = lib.mkIf platformLib.isLinux true;
    firefox = lib.mkIf platformLib.isLinux {
      profiles = {
        default = {
          enable = true;
          accent = "mauve";
          flavor = "mocha";
        };
      };
    };
  };
  home = lib.optionalAttrs platformLib.isLinux {
    packages = with pkgs; [
      magnetic-catppuccin-gtk
      nwg-look
      iosevka
      nerd-fonts.iosevka
      gtk4
    ];
    pointerCursor = {
      name = "catppuccin-mocha-mauve-cursors";
      package = pkgs.catppuccin-cursors.mochaMauve;
      size = 24;
      gtk.enable = true;
      x11 = {
        enable = true;
        defaultCursor = "left_ptr";
      };
    };
  };
  gtk = lib.mkIf platformLib.isLinux {
    enable = true;
    font = {
      name = "Iosevka";
      package = pkgs.iosevka;
      size = 12;
    };
    theme = {
      name = "Catppuccin-GTK-Dark";
      package = pkgs.magnetic-catppuccin-gtk;
    };
    cursorTheme = {
      name = "catppuccin-mocha-mauve-cursors";
      package = pkgs.catppuccin-cursors.mochaMauve;
      size = 24;
    };
  };
  fonts.fontconfig.enable = lib.mkIf platformLib.isLinux true;
}
