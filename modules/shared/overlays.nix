{
  inputs,
  system,
  ...
}: {
  nixpkgs.overlays = import ../../overlays {inherit inputs system;};
}
