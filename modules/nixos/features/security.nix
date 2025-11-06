{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.host.features.security;
in
{
  config = mkIf cfg.enable {

    services.pcscd.enable = mkIf cfg.yubikey true;
  };
}
