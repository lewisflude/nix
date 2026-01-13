# VR Feature Configuration - Main File
# Combines all VR configuration modules
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.host.features.vr;

  runtime = import ./runtime.nix { inherit config lib; };
  tools = import ./tools.nix { inherit config pkgs lib; };
  steam = import ./steam.nix { inherit config pkgs lib; };
  wivrn = import ./wivrn.nix { inherit config pkgs lib; };
  virtualMonitors = import ./virtual-monitors.nix { inherit config pkgs lib; };
  immersed = import ./immersed.nix { inherit config pkgs lib; };
  performance = import ./performance.nix { inherit config lib; };
  alvr = import ./alvr.nix { inherit config pkgs lib; };
  steamvr = import ./steamvr.nix { inherit config lib; };
in
{
  config = lib.mkMerge [
    runtime
    tools
    steam
    wivrn
    virtualMonitors
    immersed
    performance
    alvr
    steamvr

    {
      assertions = [
        {
          assertion = cfg.steamvr -> cfg.enable;
          message = "SteamVR requires VR feature to be enabled";
        }
        {
          assertion = cfg.wivrn.enable -> cfg.enable;
          message = "WiVRn requires VR feature to be enabled";
        }
        {
          assertion = cfg.alvr -> cfg.enable;
          message = "ALVR requires VR feature to be enabled";
        }
        {
          assertion = cfg.immersed.enable -> cfg.enable;
          message = "Immersed requires VR feature to be enabled";
        }
        {
          assertion = cfg.virtualMonitors.enable -> cfg.enable;
          message = "Virtual Monitors require VR feature to be enabled";
        }
      ];
    }
  ];
}
