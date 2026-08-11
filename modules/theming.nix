# Desktop theming - GTK, Qt, and fonts
_: {
  flake.modules.homeManager.theming =
    { lib, pkgs, ... }:
    let
      inherit (pkgs.stdenv) isLinux;
    in
    {
      # =========================================================================
      # Packages
      # =========================================================================
      home.packages = lib.optionals isLinux [
        pkgs.xdg-utils
      ];

      # =========================================================================
      # GTK - Linux only
      # =========================================================================
      gtk = lib.mkIf isLinux {
        enable = true;
        gtk4.theme = null;
        # Set explicitly since signal-nix was removed. It used to apply exactly
        # this pair, so naming it here keeps icons unchanged rather than falling
        # back to whatever the GTK default resolves to.
        iconTheme = {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
        };
        # Cursor theme managed by home.pointerCursor in niri.nix
        font = {
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
