# Desktop utilities feature module
# Dendritic pattern: Uses osConfig instead of systemConfig
{
  lib,
  osConfig ? {},
  pkgs,
  ...
}:
let
  cfg = osConfig.host.features.desktop or {};
in
{
  config = lib.mkIf (cfg.enable or false) {
    home.packages = lib.optionals (cfg.utilities or false) [
      pkgs.xdg-utils
    ];
  };
}
