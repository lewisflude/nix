{
  inputs,
  lib,
  hostSystem,
  ...
}:
let

  overlaySet = import ../../overlays {
    inherit inputs;
    system = hostSystem;
  };

  overlaysToApply = lib.attrValues overlaySet;
in
{
  nixpkgs.overlays = overlaysToApply;

  _module.args.overlayInfo = {
    total = lib.length overlaysToApply;
    names = lib.attrNames overlaySet;
  };
}
