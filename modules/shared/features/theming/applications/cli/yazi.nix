{
  config,
  lib,
  themeContext ? null,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.theming.signal;
  theme = themeContext.theme;
in
{
  config = mkIf (cfg.enable && cfg.applications.yazi.enable && theme != null) {
    # Yazi theme configuration would go here
    # Currently using default theme as custom theming requires more complex setup
    # Yazi is configured in home/nixos/yazi.nix
  };
}
