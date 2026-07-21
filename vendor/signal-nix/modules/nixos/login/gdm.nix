{
  signalLib,
  signalPalette,
  semantic,
  nix-colorizer,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.theming.signal.nixos;

  # Resolve theme mode
  themeMode = signalLib.resolveThemeMode cfg.mode;

  # Import the GTK theme package
  gtkTheme = pkgs.callPackage ../../../pkgs/gtk-theme {
    inherit signalLib;
    inherit (cfg) mode;
  };

  # Determine if GDM should be themed
  shouldTheme =
    cfg.enable && cfg.login.gdm.enable && (config.services.xserver.displayManager.gdm.enable or false);

in
{
  options.theming.signal.nixos.login.gdm = {
    backgroundImage = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Custom background image for GDM login screen.
        If not set, uses solid Signal colors.

        Image should be in a format supported by GNOME (PNG, JPG, SVG).
        Recommended size: 1920x1080 or higher.
      '';
      example = lib.literalExpression "./path/to/background.png";
    };
  };

  config = mkIf shouldTheme {
    # Install Signal GTK theme system-wide
    environment.systemPackages = [ gtkTheme ];

    # Apply GTK theme to GDM via dconf database
    # This creates a dconf profile that GDM will use
    environment.etc."dconf/db/gdm.d/01-signal-theme" = {
      text = ''
        [org/gnome/desktop/interface]
        gtk-theme='Signal-${themeMode}'
        color-scheme='${if themeMode == "dark" then "prefer-dark" else "prefer-light"}'

        [org/gnome/desktop/background]
        picture-uri='file://${
          if cfg.login.gdm.backgroundImage != null then cfg.login.gdm.backgroundImage else "/dev/null"
        }'
        picture-uri-dark='file://${
          if cfg.login.gdm.backgroundImage != null then cfg.login.gdm.backgroundImage else "/dev/null"
        }'
        primary-color='${(semantic.ui "panel-background" themeMode).hex}'
        secondary-color='${(semantic.ui "element-hover" themeMode).hex}'
      '';
    };

    # Update dconf database
    system.activationScripts.gdm-signal-theme = lib.stringAfter [ "etc" ] ''
      ${pkgs.dconf}/bin/dconf update
    '';

    # Ensure GDM has access to the theme
    # Add theme to GDM user's profile
    systemd.tmpfiles.rules = [
      "L+ /run/gdm/.local/share/themes - - - - ${gtkTheme}/share/themes"
    ];
  };
}
