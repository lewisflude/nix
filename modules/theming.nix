# Desktop theming - GTK, Qt, and fonts
_: {
  flake.modules.homeManager.theming =
    { lib, pkgs, ... }:
    let
      inherit (pkgs.stdenv.hostPlatform) isLinux;
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
        # signal-nix owns GTK colours (gtk3/gtk4 extraCss) AND the icon theme
        # (it sets Adwaita itself), so no iconTheme here. gtk.enable above is what
        # lets signal's autoEnable detect and theme GTK; the font stays ours since
        # signal does not set gtk.font.
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
