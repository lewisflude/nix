# Library functions module
# Dendritic pattern: Exposes utility functions
# Imports from _shared.nix (same directory) instead of ../../lib
{ lib, inputs, ... }:
let
  shared = import ./_shared.nix { inherit lib inputs; };
in
{
  # Export as flake.lib for external consumers
  flake.lib = shared.myLib;
}
