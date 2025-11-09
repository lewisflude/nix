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
  config = mkIf (cfg.enable && cfg.applications.zellij.enable && theme != null) {
    # Zellij theme configuration would go here
    # Currently using default theme as custom theming requires KDL format
    # Zellij is configured in home/common/apps/zellij.nix
  };
}
