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

  # Import the GRUB theme package with proper dependencies
  grubTheme = pkgs.callPackage ../../../pkgs/grub-theme {
    inherit signalLib;
    inherit (cfg) mode;
  };

  # Determine if GRUB should be themed
  shouldTheme = cfg.enable && cfg.boot.grub.enable && (config.boot.loader.grub.enable or false);

  # Option for custom background image (optional override)
  backgroundOption = mkOption {
    type = types.nullOr types.path;
    default = null;
    description = ''
      Custom background image for GRUB.
      If not set, uses Signal's solid color background.

      Image should be PNG format, recommended size: 1920x1080
    '';
  };
in
{
  options.theming.signal.nixos.boot.grub = {
    customBackground = backgroundOption;
  };

  config = mkIf shouldTheme {
    # Apply Signal theme to GRUB bootloader
    boot.loader.grub = {
      # Set the theme package
      theme = grubTheme;

      # Optional: Set background color as fallback
      # (theme.txt already sets this, but this ensures it's applied)
      backgroundColor = (semantic.ui "panel-background" themeMode).hex;

      # Splash image (if custom background provided)
      splashImage = mkIf (cfg.boot.grub.customBackground != null) cfg.boot.grub.customBackground;
    };
  };
}
