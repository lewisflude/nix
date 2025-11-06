{
  pkgs,
  lib,
  system,
  virtualisation ? { },
  ...
}:
let
  platformLib = (import ../../../lib/functions.nix { inherit lib; }).withSystem system;
  dockerEnabled = virtualisation.docker or virtualisation.enableDocker or false;
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
