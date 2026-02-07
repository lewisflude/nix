# Nixpkgs configuration and overlays
# Dendritic pattern: Top-level module prepares overlays, lower-level modules consume them
{ lib, inputs, ... }:
let
  shared = import ../_shared.nix { inherit lib inputs; };

  # Pre-compute overlays for each system at top-level
  nixosOverlays = shared.overlaysList "x86_64-linux";
  darwinOverlays = shared.overlaysList "aarch64-darwin";
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
      # (e.g. nixpkgs-xr) so our overrides (wivrn/xrizer multilib) see their packages
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
