{
  pkgs,
  lib,
  system,
  ...
}:
let
  platformLib = (import ../../lib/functions.nix { inherit lib; }).withSystem system;
  signal-theme = pkgs.callPackage ../../pkgs/signal-theme.nix { };
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
    theme = {
      name = "Signal";
      package = signal-theme;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "DMZ-White";
      package = pkgs.vanilla-dmz;
    };
    font = {
      name = "Iosevka";
      package = pkgs.iosevka-bin;
      size = 12;
    };
  };

  fonts.fontconfig.enable = lib.mkIf platformLib.isLinux true;
}
