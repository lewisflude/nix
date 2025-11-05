{
  inputs,
  lib,
  hostSystem,
  ...
}:
let
  # Use hostSystem from specialArgs which is passed in at the top level
  # This avoids infinite recursion by not depending on config or pkgs
  overlaySet = import ../../overlays {
    inherit inputs;
    system = hostSystem;
  };

  # Get list of overlays to apply (filter out no-ops)
  overlaysToApply = lib.attrValues overlaySet;
in
{
  nixpkgs.overlays = overlaysToApply;

  # Make overlay info available for debugging
  _module.args.overlayInfo = {
    total = lib.length overlaysToApply;
    names = lib.attrNames overlaySet;
  };
}
