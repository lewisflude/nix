{
  pkgs,
  lib,
  ...
}:
let
  # Check if we're on Linux using pkgs.stdenv
  isLinux = pkgs.stdenv.isLinux;
in
{

  home.packages = lib.mkIf isLinux [
    pkgs.nwg-look

    pkgs.iosevka-bin
    pkgs.nerd-fonts.iosevka
  ];

  gtk = lib.mkIf isLinux {
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
  qt.enable = lib.mkIf isLinux true;

  fonts.fontconfig.enable = lib.mkIf isLinux true;
}
