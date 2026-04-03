# Nixpkgs configuration and overlays
# Dendritic pattern: Top-level module prepares overlays, lower-level modules consume them
{ config, ... }:
let
  inherit (config) overlaysForSystem;

  # Pre-compute overlays for each system at top-level
  nixosOverlays = overlaysForSystem "x86_64-linux";
  darwinOverlays = overlaysForSystem "aarch64-darwin";
in
{
  # NixOS nixpkgs configuration
  flake.modules.nixos.nixpkgs =
    { lib, ... }:
    {
      nixpkgs.config = {
        allowUnfree = true;
        allowUnfreePredicate = _: true;
        permittedInsecurePackages = [
          # Add insecure packages as needed
        ];
      };

      # Use pre-computed overlays, ordered after external NixOS module overlays
      # so our overrides (e.g. wivrn CUDA) take precedence
      nixpkgs.overlays = lib.mkAfter nixosOverlays;
    };

  # Darwin nixpkgs configuration
  flake.modules.darwin.nixpkgs =
    { lib, ... }:
    {
      nixpkgs.config = {
        allowUnfree = true;
        allowUnfreePredicate = _: true;
      };

      # Use pre-computed overlays
      nixpkgs.overlays = lib.mkAfter darwinOverlays;
    };
}
