# Nixpkgs configuration and overlays
# Dendritic pattern: Top-level module prepares overlays, lower-level modules consume them
{ config, inputs, ... }:
let
  # Helper to create overlays from inputs (called at top-level with inputs access)
  mkOverlays =
    system:
    let
      overlaySet = import ../../overlays {
        inherit inputs system;
      };
    in
    builtins.attrValues overlaySet;

  # Pre-compute overlays for each system at top-level
  nixosOverlays = mkOverlays "x86_64-linux";
  darwinOverlays = mkOverlays "aarch64-darwin";
in
{
  # NixOS nixpkgs configuration
  flake.modules.nixos.base =
    { lib, ... }:
    {
      nixpkgs.config = {
        allowUnfree = true;
        allowUnfreePredicate = _: true;
        permittedInsecurePackages = [
          # Add insecure packages as needed
        ];
      };

      # Use pre-computed overlays (no inputs access needed here)
      nixpkgs.overlays = nixosOverlays;
    };

  # Darwin nixpkgs configuration
  flake.modules.darwin.base =
    { lib, ... }:
    {
      nixpkgs.config = {
        allowUnfree = true;
        allowUnfreePredicate = _: true;
      };

      # Use pre-computed overlays (no inputs access needed here)
      nixpkgs.overlays = darwinOverlays;
    };
}
