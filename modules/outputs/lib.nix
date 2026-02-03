# Flake library exports
# Dendritic pattern: Makes custom functions available to other flakes
{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  functionsLib = import ../../lib/functions.nix { inherit lib; };
in
{
  # Flake library exports
  # Makes custom functions available to other flakes that import this one
  flake.lib = functionsLib;
}
