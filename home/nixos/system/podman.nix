{
  pkgs,
  lib,
  system,
  virtualisation ? { },
  modulesVirtualisation ? { },
  ...
}:
let
  platformLib = (import ../../../lib/functions.nix { inherit lib; }).withSystem system;
  podmanEnabled = platformLib.getVirtualisationFlag {
    inherit modulesVirtualisation virtualisation;
    flagName = "enablePodman";
    default = false;
  };
in
{
  home.packages =
    if podmanEnabled then
      with pkgs;
      [
        podman
        podman-compose
      ]
    else
      [ ];
}
