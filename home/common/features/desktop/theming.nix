{
  lib,
  systemConfig,
  ...
}:
let
  cfg = systemConfig.host.features.desktop;
in
{

  config = lib.mkIf cfg.enable {

  };
}
