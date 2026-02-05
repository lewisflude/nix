# Per-system pkgs setup
# Dendritic pattern: Sets up pkgs for each system with overlays applied
{ inputs, lib, ... }:
let
  inherit (inputs) nixpkgs;
  shared = import ../_shared.nix { inherit lib inputs; };
in
{
  # Sets up pkgs for each system with overlays applied
  # Other perSystem modules can reference it via config._module.args.pkgs
  perSystem =
    { system, ... }:
    let
      pkgsWithOverlays = import nixpkgs {
        inherit system;
        overlays = shared.overlaysList system;
        config = shared.myLib.mkPkgsConfig;
      };
    in
    {
      _module.args.pkgs = pkgsWithOverlays;
    };
}
