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
    ];
  };

  gtk = lib.mkIf platformLib.isLinux {
    enable = true;
    # GTK theme now handled by signal-nix
    # Override signal-nix's GTK defaults with custom settings
    # Note: gtk-compat.nix handles signal-nix's invalid gtk.gtk4Theme option
    iconTheme = lib.mkForce {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
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

  # Qt theming handled by signal-nix (via autoEnable)
  # Just enable Qt to activate the integration
  qt.enable = lib.mkIf platformLib.isLinux true;

  fonts.fontconfig.enable = lib.mkIf platformLib.isLinux true;
}
