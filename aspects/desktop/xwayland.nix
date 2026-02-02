# XWayland Configuration
# Legacy X11 application support on Wayland
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
    programs.xwayland.enable = true;
  };
}
