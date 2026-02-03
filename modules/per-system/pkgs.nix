# Per-system pkgs setup
# Dendritic pattern: Sets up pkgs for each system with overlays applied
{ inputs, ... }:
let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;
  functionsLib = import ../../lib/functions.nix { inherit lib; };
in
{
  # Sets up pkgs for each system with overlays applied
  # Other perSystem modules can reference it via config._module.args.pkgs
  perSystem =
    { system, ... }:
    let
      pkgsWithOverlays = import nixpkgs {
        inherit system;
        overlays = functionsLib.mkOverlays { inherit inputs system; };
        config = functionsLib.mkPkgsConfig;
      };
    in
    {
      _module.args.pkgs = pkgsWithOverlays;
    };
}
