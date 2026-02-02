# Theme Configuration
# System-wide theming via Signal NixOS modules
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.features.desktop;
  isLinux = pkgs.stdenv.isLinux;
in
{
  config = lib.mkIf (cfg.enable && isLinux) {
    # Enable Signal NixOS theming
    # This provides system-wide GTK theme for login screens, pinentry, etc.
    theming.signal.nixos = {
      enable = true;
      autoEnable = true;
      mode = "dark";
    };
  };
}
