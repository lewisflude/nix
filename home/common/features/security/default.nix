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

        yubikey-personalization
      ]
      ++ lib.optionals cfg.gpg [

      ];

    programs.gpg = lib.mkIf cfg.gpg {
      enable = true;
    };

  };
}
