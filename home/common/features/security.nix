{
  lib,
  host,
  pkgs,
  hostSystem,
  ...
}: let
  cfg = host.features.security;
  isLinux = lib.strings.hasSuffix "linux" hostSystem;
in {
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs;
      [
        age
        sops
      ]
      ++ lib.optionals cfg.yubikey [
        yubikey-manager
        yubikey-personalization
      ]
      ++ lib.optionals cfg.gpg [
        gnupg
        pinentry-curses
      ]
      ++ lib.optionals cfg.vpn [
        wireguard-tools
      ];

    programs.gpg = lib.mkIf cfg.gpg {
      enable = true;
    };

    services.gpg-agent = lib.mkIf (cfg.gpg && isLinux) {
      enable = true;
      enableSshSupport = true;
      pinentryPackage = pkgs.pinentry-curses;
    };
  };
}
