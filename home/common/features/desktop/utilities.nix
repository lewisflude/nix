{
  lib,
  systemConfig,
  pkgs,
  ...
}:
let
  cfg = systemConfig.host.features.desktop;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = lib.optionals cfg.utilities [
      pkgs.xdg-utils
    ];
  };
}
