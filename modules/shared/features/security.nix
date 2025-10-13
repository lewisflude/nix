# Security feature module (cross-platform)
# Controlled by host.features.security.*
{
  config,
  lib,
  pkgs,
  hostSystem,
  ...
}:
with lib; let
  cfg = config.host.features.security;
  isLinux = lib.strings.hasSuffix "linux" hostSystem;
in {
  config = mkIf cfg.enable {
    # Install security packages
    home-manager.users.${config.host.username} = {
      home.packages = with pkgs;
        [
          age
          sops
        ]
        ++ optionals cfg.yubikey [
          yubikey-manager
          yubikey-personalization
        ]
        ++ optionals cfg.gpg [
          gnupg
          pinentry-curses
        ]
        ++ optionals cfg.vpn [
          wireguard-tools
        ];

      # GPG configuration
      programs.gpg = mkIf cfg.gpg {
        enable = true;
      };

      services.gpg-agent = mkIf (cfg.gpg && isLinux) {
        enable = true;
        enableSshSupport = true;
        pinentryPackage = pkgs.pinentry-curses;
      };
    };
  };
}
