{
  lib,
  systemConfig,
  pkgs,
  hostSystem,
  ...
}:
let
  cfg = systemConfig.host.features.security;
  platformLib = (import ../../../../lib/functions.nix { inherit lib; }).withSystem hostSystem;
  inherit (platformLib) isDarwin isLinux;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.age
      pkgs.sops
    ]
    ++ lib.optionals cfg.yubikey (
      [
        pkgs.yubikey-manager
        pkgs.yubikey-personalization
        pkgs.pcsc-tools
      ]
      ++ lib.optionals isDarwin [
        pkgs.terminal-notifier
      ]
      ++ lib.optionals isLinux [
        pkgs.yubioath-flutter
      ]
    );
    # Note: GPG is configured in home/common/gpg.nix, imported via profiles/base.nix
  };
}
