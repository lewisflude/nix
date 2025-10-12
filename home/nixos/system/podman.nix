{
  pkgs,
  lib,
  system,
  virtualisation ? {},
  modulesVirtualisation ? {},
  ...
}: let
  platformLib = import ../../../lib/functions.nix {inherit lib system;};
  podmanEnabled = platformLib.getVirtualisationFlag {
    inherit modulesVirtualisation virtualisation;
    flagName = "enablePodman";
    default = true;
  };
in {
  home.packages =
    if podmanEnabled
    then
      with pkgs; [
        podman
        podman-compose
      ]
    else [];
}
