{
  lib,
  system,
}:
let
  platformLib = (import ../../../lib/functions.nix { inherit lib; }).withSystem system;

  # Helper: Get nx package with fallback logic
  # nx-latest should be available from overlays/npm-packages.nix overlay
  # Fallback to nodePackages.nx if overlay isn't applied or package doesn't exist
  getNxPackage = pkgs: pkgs.nx-latest or (pkgs.nodePackages.nx or null);
in
{
  inherit platformLib getNxPackage;
}
