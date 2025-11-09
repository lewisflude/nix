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
  config = mkIf (cfg.enable && cfg.applications.zellij.enable && theme != null) {
    # Zellij theme configuration would go here
    # Currently using default theme as custom theming requires KDL format
    # Zellij is configured in home/common/apps/zellij.nix
  };
}
