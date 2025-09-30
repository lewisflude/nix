{pkgs, lib, system, ...}: let
  platformLib = import ../../../lib/functions.nix { inherit lib system; };
in {
  home.packages = with pkgs; [
    (platformLib.getVersionedPackage pkgs platformLib.versions.nodejs)
  ];
}
