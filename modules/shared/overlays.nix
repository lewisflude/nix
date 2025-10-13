{
  config,
  inputs,
  lib,
  ...
}: let
  system = config.nixpkgs.hostPlatform.system;
  overlaySet = import ../../overlays {
    inherit inputs system;
  };
  
  # Get list of overlays to apply (filter out no-ops)
  overlaysToApply = lib.attrValues overlaySet;
in {
  nixpkgs.overlays = overlaysToApply;

  # Make overlay info available for debugging
  _module.args.overlayInfo = {
    total = lib.length overlaysToApply;
    names = lib.attrNames overlaySet;
  };
}
