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

  # Determine if LightDM should be themed
  shouldTheme =
    cfg.enable
    && cfg.login.lightdm.enable
    && (config.services.xserver.displayManager.lightdm.enable or false);

  # Determine which greeter is in use
  isGtkGreeter = config.services.xserver.displayManager.lightdm.greeters.gtk.enable or false;

in
{
  options.theming.signal.nixos.login.lightdm = {
    backgroundImage = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Custom background image for LightDM login screen.
        If not set, uses solid Signal colors.

        Image should be PNG or JPG format.
        Recommended size: 1920x1080 or higher.
      '';
      example = lib.literalExpression "./path/to/background.png";
    };
  };

  config = mkIf shouldTheme {
    # Install Signal GTK theme system-wide
    environment.systemPackages = [ gtkTheme ];

    # Configure LightDM GTK Greeter (most common greeter)
    services.xserver.displayManager.lightdm.greeters.gtk = mkIf isGtkGreeter {
      # Apply Signal GTK theme
      theme = {
        name = "Signal-${themeMode}";
        package = gtkTheme;
      };

      # Use Adwaita icon theme (neutral, professional)
      iconTheme = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
      };

      # Set background
      extraConfig = ''
        # Signal Design System LightDM Configuration

        # Background
        ${
          if cfg.login.lightdm.backgroundImage != null then
            "background = ${cfg.login.lightdm.backgroundImage}"
          else
            "background = ${(semantic.ui "panel-background" themeMode).hex}"
        }

        # Theme
        theme-name = Signal-${themeMode}
        icon-theme-name = Adwaita

        # Font (using system default)
        font-name = Sans 11

        # Additional appearance settings
        indicators = ~host;~spacer;~clock;~spacer;~session;~a11y;~power
        clock-format = %a, %b %d  %H:%M

        # Panel colors (using Signal colors)
        user-background = false

        # Disable user list for security (optional - user can override)
        # allow-guest = false
      '';
    };

    # For other greeters, we can only set the GTK theme system-wide
    # which LightDM will pick up if it uses GTK
    environment.etc."lightdm/lightdm-gtk-greeter.conf" = mkIf isGtkGreeter {
      text = ''
        [greeter]
        theme-name = Signal-${themeMode}
        icon-theme-name = Adwaita
        ${
          if cfg.login.lightdm.backgroundImage != null then
            "background = ${cfg.login.lightdm.backgroundImage}"
          else
            "background = ${(semantic.ui "panel-background" themeMode).hex}"
        }
        user-background = false
        indicators = ~host;~spacer;~clock;~spacer;~session;~a11y;~power
        clock-format = %a, %b %d  %H:%M
        font-name = Sans 11
        position = 50%,center 50%,center
      '';
    };
  };
}
