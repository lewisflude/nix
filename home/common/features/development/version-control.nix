{
  lib,
  systemConfig,
  ...
}:
let
  cfg = systemConfig.host.features.development;
in
{

  config = lib.mkIf cfg.enable {

  };
}
