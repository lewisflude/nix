# Test: No Hardcoded Colors
# Phase 3, Task 3.1 - Validation
#
# This test ensures that no modules contain hardcoded color values.
# All colors must come from the signal-palette via semantic bridge.
#
# Fails if any module contains:
# - Hex colors: #RRGGBB
# - OKLCH colors: oklch(L C H)
# - RGB colors: rgb(R, G, B)
# - RGBA colors: rgba(R, G, B, A)

{ pkgs, lib, ... }:

let
  # Import validation library
  validate = import ../../lib/validate.nix { inherit lib; };

  # List all module files to check
  moduleFiles =
    let
      # Get all .nix files in modules directory
      modulesDir = ../../modules;
      findModules =
        dir:
        let
          entries = builtins.readDir dir;
          files = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) entries;
          dirs = lib.filterAttrs (name: type: type == "directory") entries;
        in
        (map (name: "${dir}/${name}") (builtins.attrNames files))
        ++ (lib.concatMap (name: findModules "${dir}/${name}") (builtins.attrNames dirs));
    in
    findModules modulesDir;

  # Check a single file for hardcoded colors
  checkFile =
    file:
    let
      content = builtins.readFile file;
      hasHardcodedColors = validate.findHardcodedColors content;
    in
    if hasHardcodedColors then
      throw ''
        ❌ HARDCODED COLORS DETECTED in ${file}

        This file contains hardcoded color values. All colors must come from
        signal-palette via the semantic bridge.

        Use semantic bridge instead:
          semantic.core "background" mode
          semantic.status "error" mode
          semantic.text "secondary" mode

        See docs/QUICK_REFERENCE.md for available semantic colors.
      ''
    else
      file;

  # Check all modules
  checkedFiles = map checkFile moduleFiles;

in
pkgs.runCommand "no-hardcoded-colors" { } ''
  echo "✅ Checking ${toString (builtins.length moduleFiles)} modules for hardcoded colors..."

  ${lib.concatMapStringsSep "\n" (f: "echo '  ✓ ${f}'") checkedFiles}

  echo ""
  echo "✅ All modules pass hardcoded color validation!"
  echo "   No hardcoded hex, oklch, rgb, or rgba colors found."
  echo ""

  touch $out
''
