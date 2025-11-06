{
  lib,
  system,
}: let
  platformLib = (import ../../../lib/functions.nix {inherit lib;}).withSystem system;

  # Helper: Get nx package with fallback logic
  # nx-latest should be available from overlays/npm-packages.nix overlay
  # Fallback to nodePackages.nx if overlay isn't applied or package doesn't exist
  getNxPackage = pkgs:
    if pkgs ? nx-latest
    then pkgs.nx-latest
    else if pkgs.nodePackages ? nx
    then pkgs.nodePackages.nx
    else null;
in {
  inherit platformLib getNxPackage;
}
