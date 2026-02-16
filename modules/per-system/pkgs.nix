# Per-system pkgs setup
# Dendritic pattern: Sets up pkgs for each system with overlays applied
{ config, inputs, ... }:
let
  inherit (inputs) nixpkgs;
  inherit (config) myLib overlaysForSystem;
in
{
  # Sets up pkgs for each system with overlays applied
  # Other perSystem modules can reference it via config._module.args.pkgs
  perSystem =
    { system, ... }:
    let
      pkgsWithOverlays = import nixpkgs {
        inherit system;
        overlays = overlaysForSystem system;
        config = myLib.mkPkgsConfig;
      };
    in
    {
      _module.args.pkgs = pkgsWithOverlays;
    };
}
