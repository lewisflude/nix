{
  inputs,
  config,
  ...
}:
let
  # Helper to safely get pog overlay if available
  getPogOverlay =
    system:
    if
      inputs ? pog
      && inputs.pog ? overlays
      && inputs.pog.overlays ? ${system}
      && inputs.pog.overlays.${system} ? default
    then
      inputs.pog.overlays.${system}.default
    else
      (_final: _prev: { });
in
{
  # Provides pog overlay extension for packages that need it
  # Sets config._module.args.pkgsWithPog for modules that require pog
  perSystem =
    { system, ... }:
    {
      _module.args.pkgsWithPog = config._module.args.pkgs.extend (getPogOverlay system);
    };
}
