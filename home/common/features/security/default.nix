{
  lib,
  host,
  pkgs,
  ...
}:
let
  cfg = host.features.security;
in
{
  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        age
        sops
      ]
      ++ lib.optionals cfg.yubikey [
        # yubikey-manager provided by platform-specific yubikey.nix files
        yubikey-personalization
      ]
      ++ lib.optionals cfg.gpg [
        # gnupg and pinentry provided by gpg.nix
      ];

    programs.gpg = lib.mkIf cfg.gpg {
      enable = true;
    };

    # GPG agent configuration moved to gpg.nix to avoid duplication
  };
}
