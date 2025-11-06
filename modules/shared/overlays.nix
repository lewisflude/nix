{
  inputs,
  lib,
  hostSystem,
  ...
}: let
  overlaySet = import ../../overlays {
    inherit inputs;
    system = hostSystem;
  };

  overlaysToApply = lib.attrValues overlaySet;
in {
  # Note: nixpkgs.overlays is NOT set here because we use home-manager.useGlobalPkgs = true
  # Overlays are applied at the system level in lib/system-builders.nix instead
  # This module only exposes overlay information via _module.args for reference

  _module.args.overlayInfo = {
    total = lib.length overlaysToApply;
    names = lib.attrNames overlaySet;
  };
}
