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

  # Import the Plymouth theme package
  plymouthTheme = pkgs.callPackage ../../../pkgs/plymouth-theme {
    inherit signalLib;
    inherit (cfg) mode;
  };

  # Determine if Plymouth should be themed
  shouldTheme = cfg.enable && cfg.boot.plymouth.enable && (config.boot.plymouth.enable or false);
in
{
  config = mkIf shouldTheme {
    # Apply Signal theme to Plymouth boot splash
    boot.plymouth = {
      # Set the theme name
      theme = "signal-${themeMode}";

      # Add our theme package to themePackages
      themePackages = [ plymouthTheme ];

      # Optional: Set logo if user provides one
      # (Our theme uses text-based logo by default)
      logo = mkIf (cfg.boot.plymouth.logo != null) cfg.boot.plymouth.logo;
    };

    # Ensure Plymouth is properly integrated with boot
    # These settings ensure smooth transitions and proper rendering
    boot.kernelParams = [
      "quiet" # Suppress kernel messages
      "splash" # Enable splash screen
    ];
  };

  # Add option for custom logo
  options.theming.signal.nixos.boot.plymouth = {
    logo = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Custom logo image for Plymouth splash screen.
        If not set, uses Signal text branding.

        Image should be PNG format, transparent background recommended.
        Recommended size: 256x256 pixels.
      '';
      example = lib.literalExpression "./path/to/logo.png";
    };
  };
}
