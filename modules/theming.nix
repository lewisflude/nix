# Desktop theming - GTK, Qt, fonts, and signal-nix integration
_: {
  flake.modules.homeManager.theming =
    { lib, pkgs, ... }:
    let
      inherit (pkgs.stdenv) isLinux;
    in
    {
      # =========================================================================
      # Signal Design System (Cross-platform)
      # =========================================================================
      theming.signal.enable = true;

      # =========================================================================
      # Packages
      # =========================================================================
      home.packages = lib.optionals isLinux [
        pkgs.xdg-utils
      ];

      # =========================================================================
      # GTK Overrides (on top of signal-nix) - Linux only
      # =========================================================================
      gtk = lib.mkIf isLinux {
        enable = true;
        gtk4.theme = null;
        iconTheme = lib.mkForce {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
        };
        # Cursor theme managed by home.pointerCursor in niri.nix
        font = lib.mkForce {
          name = "Iosevka";
          package = pkgs.iosevka-bin;
          size = 12;
        };
      };

      # Qt theming - Linux only
      qt.enable = isLinux;

      # Font configuration
      fonts.fontconfig.enable = true;
    };
}
