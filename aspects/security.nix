# Security Aspect
#
# Combines all security-related configuration in a single file.
# Reads options from config.host.features.security (defined in modules/shared/host-options/features/security.nix)
#
# Platform support:
# - NixOS: pcscd for YubiKey, GPG support
# - Darwin: Minimal (most security config is in security-preferences.nix)
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  cfg = config.host.features.security;
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  config = mkMerge [
    # ================================================================
    # NixOS Configuration
    # ================================================================
    (mkIf (cfg.enable && isLinux) {
      services.pcscd.enable = mkIf cfg.yubikey true;
    })

    # ================================================================
    # Darwin Configuration
    # ================================================================
    (mkIf (cfg.enable && isDarwin) {
      # macOS security is primarily configured via system-preferences
      # YubiKey support works natively on macOS via the system CCID driver
    })

    # ================================================================
    # Assertions (both platforms)
    # ================================================================
    {
      assertions = [
        {
          assertion = cfg.yubikey -> cfg.enable;
          message = "YubiKey support requires security feature to be enabled";
        }
        {
          assertion = cfg.gpg -> cfg.enable;
          message = "GPG support requires security feature to be enabled";
        }
      ];
    }
  ];
}
