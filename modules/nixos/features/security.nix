# NixOS-specific security feature configuration
{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.host.features.security;
in
{
  config = mkIf cfg.enable {
    # YubiKey support (pcscd service is Linux-only)
    services.pcscd.enable = mkIf cfg.yubikey true;
  };
}
