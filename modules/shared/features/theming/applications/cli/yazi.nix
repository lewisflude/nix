{
  config,
  lib,
  pkgs,
  themeContext ? null,
  signalPalette ? null, # Backward compatibility
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  # Use themeContext if available, otherwise fall back to signalPalette for backward compatibility
  theme = themeContext.theme or signalPalette;
in
{
  config = mkIf (cfg.enable && cfg.applications.yazi.enable && theme != null) {
    # Yazi theme configuration would go here
    # Currently using default theme as custom theming requires more complex setup
    # Yazi is configured in home/nixos/yazi.nix
  };
}
