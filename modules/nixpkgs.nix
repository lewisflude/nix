# Nixpkgs configuration and overlays
# Dendritic pattern: Top-level module prepares overlays, lower-level modules consume them.
# nixpkgs.config is sourced from myLib.mkPkgsConfig so module-eval and perSystem pkgs
# stay aligned (single source of truth in modules/lib.nix).
{ config, ... }:
let
  inherit (config) overlaysForSystem myLib;

  nixosOverlays = overlaysForSystem "x86_64-linux";
  darwinOverlays = overlaysForSystem "aarch64-darwin";
in
{
  flake.modules.nixos.nixpkgs =
    { lib, ... }:
    {
      nixpkgs.config = myLib.mkPkgsConfig;
      # Ordered after external NixOS module overlays so our overrides
      # (e.g. wivrn CUDA) take precedence.
      nixpkgs.overlays = lib.mkAfter nixosOverlays;
    };

  flake.modules.darwin.nixpkgs =
    { lib, ... }:
    {
      nixpkgs.config = myLib.mkPkgsConfig;
      nixpkgs.overlays = lib.mkAfter darwinOverlays;
    };
}
