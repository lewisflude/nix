# Per-system formatters
# Dendritic pattern: Provides nix fmt for each system
{ inputs, config, ... }:
let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;
  functionsLib = import ../../lib/functions.nix { inherit lib; };
in
{
  perSystem =
    { system, ... }:
    let
      # Get pkgs from module args (set by per-system/pkgs.nix)
      # Use fallback to direct import if needed
      pkgs =
        config._module.args.pkgs or (import nixpkgs {
          inherit system;
          overlays = functionsLib.mkOverlays { inherit inputs system; };
          config = functionsLib.mkPkgsConfig;
        });
    in
    {
      # Formatter for this system
      # Used by `nix fmt` command
      formatter = pkgs.nixfmt;
    };
}
