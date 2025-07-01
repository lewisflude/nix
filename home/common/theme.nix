{
  pkgs,
  lib,
  system,
  ...
}:
{
  # Base theme configuration (Catppuccin Mocha)
  catppuccin = {
    flavor = "mocha";
    accent = "mauve";
    enable = true;
    waybar.mode = "createLink";
    mako.enable = lib.mkIf (lib.hasInfix "linux" system) false;
  };

  # Linux-specific theme configuration
  home = lib.optionalAttrs (lib.hasInfix "linux" system) {
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
      hyprcursor = {
        enable = true;
        size = 24;
      };
      x11 = {
        enable = true;
        defaultCursor = "left_ptr";
      };
    };
  };

  # GTK configuration (Linux only)
  gtk = lib.mkIf (lib.hasInfix "linux" system) {
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
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "catppuccin-mocha-mauve-cursors";
      package = pkgs.catppuccin-cursors.mochaMauve;
      size = 24;
    };
  };

  # Font configuration (Linux only)
  fonts.fontconfig.enable = lib.mkIf (lib.hasInfix "linux" system) true;
}
