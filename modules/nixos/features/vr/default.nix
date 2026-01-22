# VR Feature Configuration - Main File
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.host.features.vr;

  wivrn = import ./wivrn.nix { inherit config pkgs lib; };
  immersed = import ./immersed.nix { inherit config pkgs lib; };
  steamvr = import ./steamvr.nix { inherit config pkgs lib; };
  performance = import ./performance.nix { inherit config lib; };
in
{
  config = lib.mkMerge [
    wivrn
    immersed
    steamvr
    performance

    {
      assertions = [
        {
          assertion = cfg.wivrn.enable -> cfg.enable;
          message = "WiVRn requires VR feature to be enabled";
        }
        {
          assertion = cfg.immersed.enable -> cfg.enable;
          message = "Immersed requires VR feature to be enabled";
        }
      ];
    }
  ];
}
