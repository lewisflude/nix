{
  inputs,
  ...
}:
let
  nixpkgs = inputs.nixpkgs or (throw "nixpkgs input is required");
  inherit (nixpkgs) lib;
in
{
  # Flake overlays
  # Applied to nixpkgs when this flake is used as an input
  flake.overlays.default =
    final: prev:
    let
      system = prev.stdenv.hostPlatform.system;
      overlaySet = import ../../overlays {
        inherit inputs system;
      };
      overlayList = builtins.attrValues overlaySet;
      inherit (prev.lib) composeExtensions foldl';
    in
    (foldl' composeExtensions (_: _: { }) overlayList) final prev;
}
