{
  inputs ? {},
  lib,
  ...
}: {
  nixpkgs.overlays = lib.optionals (inputs ? nvidia-patch) [
    inputs.nvidia-patch.overlays.default
  ];
}
