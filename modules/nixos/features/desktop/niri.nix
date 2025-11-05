{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.host.features.desktop;
in
{
  config = lib.mkIf cfg.enable {
    programs.niri = {
      enable = true;
      package = pkgs.niri-unstable;
    };
  };
}
