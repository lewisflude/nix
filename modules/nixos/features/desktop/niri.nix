{
  config,
  lib,
  inputs,
  hostSystem,
  ...
}:
let
  cfg = config.host.features.desktop;
  inherit (inputs.niri.packages.${hostSystem}) niri-unstable;
in
{
  config = lib.mkIf cfg.enable {
    programs.niri = {
      enable = true;
      package = niri-unstable;
    };
  };
}
