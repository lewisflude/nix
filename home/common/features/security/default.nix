# Security feature module
# Dendritic pattern: Uses osConfig and pkgs.stdenv instead of systemConfig/hostSystem
{
  lib,
  osConfig ? {},
  pkgs,
  ...
}:
let
  cfg = osConfig.host.features.security or {};
  # Use pkgs.stdenv for platform detection instead of hostSystem parameter
  isDarwin = pkgs.stdenv.isDarwin;
  isLinux = pkgs.stdenv.isLinux;
in
{
  config = lib.mkIf (cfg.enable or false) {
    home.packages = [
      pkgs.age
      pkgs.sops
    ]
    ++ lib.optionals (cfg.yubikey or false) (
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
