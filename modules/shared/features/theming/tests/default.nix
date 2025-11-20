{ lib }:
let
  # Import all test modules
  paletteTests = import ./palette.nix { inherit lib; };
  modeTests = import ./mode.nix { inherit lib; };
  semanticTests = import ./semantic.nix { inherit lib; };
  applicationsTests = import ./applications.nix { inherit lib; };
  optionsTests = import ./options.nix { inherit lib; };
  snapshotsTests = import ./snapshots.nix { inherit lib; };
in
# Combine all tests
lib.recursiveUpdate
  (lib.recursiveUpdate (lib.recursiveUpdate (lib.recursiveUpdate (lib.recursiveUpdate paletteTests modeTests) semanticTests) applicationsTests) optionsTests)
  snapshotsTests
