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

  # Import the SDDM theme package
  sddmTheme = pkgs.callPackage ../../../pkgs/sddm-theme {
    inherit signalLib;
    inherit (cfg) mode;
  };

  # Determine if SDDM should be themed
  shouldTheme =
    cfg.enable && cfg.login.sddm.enable && (config.services.displayManager.sddm.enable or false);
in
{
  config = mkIf shouldTheme {
    # Apply Signal theme to SDDM display manager
    services.displayManager.sddm = {
      # Set the theme
      theme = "signal-${themeMode}";

      # Add theme package to extraPackages
      # This makes the theme available to SDDM
      extraPackages = [ sddmTheme ];

      # Optional: Set additional SDDM settings
      settings = {
        Theme = {
          Current = "signal-${themeMode}";
          ThemeDir = "${sddmTheme}/share/sddm/themes";

          # Disable cursor theme override (use system default)
          CursorTheme = "";
        };
      };
    };

    # Ensure SDDM theme is in system packages
    # This guarantees the theme files are available
    environment.systemPackages = [ sddmTheme ];
  };
}
