# Per-system formatters
# Dendritic pattern: Provides nix fmt for each system
{ inputs, config, lib, ... }:
let
  inherit (inputs) nixpkgs;
  shared = import ../_shared.nix { inherit lib inputs; };
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
          overlays = shared.overlaysList system;
          config = shared.myLib.mkPkgsConfig;
        });
    in
    {
      # Formatter for this system
      # Used by `nix fmt` command
      formatter = pkgs.nixfmt;
    };
}
