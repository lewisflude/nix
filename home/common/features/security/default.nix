{
  lib,
  host,
  pkgs,
  hostSystem,
  ...
}:
let
  cfg = host.features.security;
  platformLib = (import ../../../../lib/functions.nix { inherit lib; }).withSystem hostSystem;
  inherit (platformLib) isDarwin isLinux;
in
{
  config = lib.mkIf cfg.enable {
    home.packages =
      with pkgs;
      [
        age
        sops
      ]
      ++ lib.optionals cfg.yubikey (
        [
          yubikey-manager
          yubikey-personalization
          pcsc-tools
        ]
        ++ lib.optionals isDarwin [
          terminal-notifier
        ]
        ++ lib.optionals isLinux [
          yubioath-flutter
        ]
      );
    # Note: GPG is configured in home/common/gpg.nix, imported via profiles/base.nix
  };
}
