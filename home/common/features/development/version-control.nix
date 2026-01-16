{
  lib,
  systemConfig,
  ...
}:
let
  cfg = systemConfig.host.features.development;
in
{
  imports = [
    ../../apps/gh.nix
  ];

  config = lib.mkIf cfg.enable {

  };
}
