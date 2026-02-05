# Overlays module - exports flake.overlays.default
# Dendritic pattern: Imports from _shared.nix (same directory) instead of ../../overlays
{ lib, inputs, ... }:
let
  shared = import ./_shared.nix { inherit lib inputs; };
in
{
  # Flake overlays - applied to nixpkgs when this flake is used as an input
  flake.overlays.default =
    final: prev:
    let
      inherit (prev.stdenv.hostPlatform) system;
      overlayList = shared.overlaysList system;
      inherit (prev.lib) composeExtensions foldl';
    in
    (foldl' composeExtensions (_: _: { }) overlayList) final prev;
}
