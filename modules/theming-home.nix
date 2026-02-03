# Desktop theming - GTK, Qt, fonts, and signal-nix integration
{ config, ... }:
{
  flake.modules.homeManager.theming =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.isLinux {
      # Signal-nix theming (GTK theme)
      theming.signal = {
        enable = true;
        autoEnable = true;
        mode = "dark";

        # Enable ironbar colors (required when using colors.ironbar in config)
        ironbar.enable = true;

        # Niri compositor theming
        desktop.compositors.niri = {
          enable = true;
          exportKdl = true; # Generates signal-colors.kdl for DMS integration
        };
      };

      # Theme utilities and desktop utilities
      home.packages = [
        pkgs.nwg-look
        pkgs.iosevka-bin
        pkgs.nerd-fonts.iosevka
        pkgs.xdg-utils
      ];

      # GTK configuration
      gtk = {
        enable = true;
        # Override signal-nix's GTK defaults with custom settings
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

      # Qt theming (handled by signal-nix via autoEnable)
      qt.enable = true;

      # Font configuration
      fonts.fontconfig.enable = true;
    };
}
