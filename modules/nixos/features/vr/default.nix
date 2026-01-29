# VR Feature Configuration - Main File
{
  config,
  pkgs,
  lib,
  constants,
  ...
}:
let
  cfg = config.host.features.vr;

  wivrn = import ./wivrn.nix { inherit config pkgs lib constants; };
  alvr = import ./alvr.nix { inherit config pkgs lib; };
  immersed = import ./immersed.nix { inherit config pkgs lib constants; };
  steamvr = import ./steamvr.nix { inherit config pkgs lib constants; };
  performance = import ./performance.nix { inherit config lib constants; };
in
{
  config = lib.mkMerge [
    wivrn
    alvr
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
          assertion = cfg.alvr.enable -> cfg.enable;
          message = "ALVR requires VR feature to be enabled";
        }
        {
          assertion = cfg.alvr.enable -> cfg.steamvr;
          message = "ALVR requires SteamVR to be enabled";
        }
        {
          assertion = cfg.immersed.enable -> cfg.enable;
          message = "Immersed requires VR feature to be enabled";
        }
      ];
    }
  ];
}
