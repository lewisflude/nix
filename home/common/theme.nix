{
  pkgs,
  lib,
  system,
  ...
}:
let
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;
  # signal-theme now provided by signal flake
in
{

  home = lib.optionalAttrs platformLib.isLinux {
    packages = [
      pkgs.nwg-look

      pkgs.iosevka-bin
      pkgs.nerd-fonts.iosevka
      pkgs.gtk4
    ];
  };

  gtk = lib.mkIf platformLib.isLinux {
    enable = true;
    # GTK theme now handled by signal flake
    # Override signal flake's GTK defaults with custom settings
    iconTheme = lib.mkForce {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = lib.mkForce {
      name = "DMZ-White";
      package = pkgs.vanilla-dmz;
    };
    font = lib.mkForce {
      name = "Iosevka";
      package = pkgs.iosevka-bin;
      size = 12;
    };
  };

  # Qt theming to match GTK Signal theme
  qt = lib.mkIf platformLib.isLinux {
    enable = true;
    platformTheme.name = "adwaita"; # Use Adwaita platform theme to match GTK
    style = {
      name = "adwaita-dark"; # Match dark mode of Signal theme
      package = pkgs.adwaita-qt;
    };
  };

  fonts.fontconfig.enable = lib.mkIf platformLib.isLinux true;
}
