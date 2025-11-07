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
      ];
    # Note: GPG is configured in home/common/gpg.nix, imported via profiles/base.nix
  };
}
