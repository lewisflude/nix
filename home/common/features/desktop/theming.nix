{
  lib,
  host,
  ...
}:
let
  cfg = host.features.desktop;
in
{

  config = lib.mkIf cfg.enable {

  };
}
