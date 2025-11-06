{
  lib,
  host,
  ...
}:
let
  cfg = host.features.development;
in
{

  config = lib.mkIf cfg.enable {

  };
}
