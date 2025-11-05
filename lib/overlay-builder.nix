# Overlay builder that combines all overlays into a single overlay function
# This is used by flake.overlays.default to export overlays following flake-parts conventions
#
# The overlay function signature is: final: prev: { ... }
# This file imports overlays/default.nix and combines them into a single overlay
{
  inputs,
  system,
}: final: prev: let
  # Import all overlays for this system
  overlaySet = import ../overlays {
    inherit inputs;
    inherit system;
  };

  # Convert overlay set to list
  overlayList = builtins.attrValues overlaySet;

  # Compose all overlays using foldl' and composeExtensions
  # This applies each overlay in sequence, with each overlay seeing the result
  # of all previous overlays applied
  inherit (prev.lib) composeExtensions foldl';
in
  # Apply all overlays by folding composeExtensions
  # This is the standard nixpkgs way to compose multiple overlays
  (foldl' composeExtensions (_: _: {}) overlayList) final prev
