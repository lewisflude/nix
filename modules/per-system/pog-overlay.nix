# Per-system pog overlay
# Dendritic pattern: Provides pog overlay extension for packages
{ inputs, ... }:
let
  # Helper to safely get pog overlay if available
  getPogOverlay =
    if inputs ? pog && inputs.pog ? overlays && inputs.pog.overlays ? default then
      inputs.pog.overlays.default
    else
      (_final: _prev: { });
in
{
  # Provides pog overlay extension for packages that need it
  # Sets config._module.args.pkgsWithPog for modules that require pog
  perSystem =
    { pkgs, ... }:
    {
      _module.args.pkgsWithPog = pkgs.extend getPogOverlay;
    };
}
