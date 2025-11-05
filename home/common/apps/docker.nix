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
  dockerEnabled = platformLib.getVirtualisationFlag {
    inherit modulesVirtualisation virtualisation;
    flagName = "enableDocker";
    default = false;
  };
  linuxPackages =
    if dockerEnabled then
      with pkgs;
      [
        docker-client
        docker-compose
        docker-credential-helpers
      ]
    else
      [ ];
in
{
  home.packages = platformLib.platformPackages linuxPackages [ ];
}
