# NixOS-specific security feature configuration
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.host.features.security;
in {
  config = mkIf cfg.enable {
    # YubiKey support (pcscd service is Linux-only)
    services.pcscd.enable = mkIf cfg.yubikey true;
  };
}
