{
  config,
  lib,
  ...
}:
let
  cfg = config.host.features.desktop;
in
{

  config = lib.mkIf cfg.enable {

  };
}
