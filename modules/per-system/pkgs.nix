# Per-system pkgs setup
# Dendritic pattern: Sets up pkgs for each system with overlays applied
{ config, inputs, ... }:
let
  inherit (inputs) nixpkgs;
  inherit (config) myLib overlayList;
in
{
  # Sets up pkgs for each system with overlays applied
  # Other perSystem modules can reference it via config._module.args.pkgs
  perSystem =
    { system, ... }:
    let
      pkgsWithOverlays = import nixpkgs {
        inherit system;
        overlays = overlayList;
        config = myLib.mkPkgsConfig;
      };
    in
    {
      _module.args.pkgs = pkgsWithOverlays;
    };
}
