# Validation Test: Function Type Safety
#
# This test validates that signalLib functions are called with correct argument types.
# Specifically, it checks that functions expecting color objects don't receive strings.
#
# Common mistakes this catches:
# - Passing color.hex instead of color to hexWithAlpha
# - Passing color.hex instead of color to hexToRgbSpaceSeparated
# - Passing color.hex instead of color to hexToRgbCommaSeparated

{ pkgs, lib }:

pkgs.runCommand "test-function-type-safety" { } ''
  echo "Validating signalLib function usage patterns..."

  # ============================================================================
  # Check: hexWithAlpha should receive color objects, not strings
  # ============================================================================
  echo "Checking hexWithAlpha usage..."

  # Find all calls to signalLib.hexWithAlpha or hexWithAlpha
  if ${pkgs.ripgrep}/bin/rg -t nix 'hexWithAlpha\s+\w+\.hex' ${../../modules} 2>/dev/null; then
    echo "ERROR: Found hexWithAlpha called with .hex property"
    echo "hexWithAlpha expects a color object, not a hex string"
    echo ""
    echo "Wrong:  signalLib.hexWithAlpha color.hex alpha"
    echo "Right:  signalLib.hexWithAlpha color alpha"
    exit 1
  fi

  # Also check for the pattern where local function calls signalLib
  if ${pkgs.ripgrep}/bin/rg -t nix 'signalLib\.hexWithAlpha\s+\w+\.hex' ${../../modules} 2>/dev/null; then
    echo "ERROR: Found signalLib.hexWithAlpha called with .hex property"
    echo "hexWithAlpha expects a color object, not a hex string"
    echo ""
    echo "Wrong:  signalLib.hexWithAlpha color.hex alpha"
    echo "Right:  signalLib.hexWithAlpha color alpha"
    exit 1
  fi

  echo "✓ hexWithAlpha usage is correct"

  # ============================================================================
  # Check: hexToRgbSpaceSeparated should receive color objects
  # ============================================================================
  echo "Checking hexToRgbSpaceSeparated usage..."

  if ${pkgs.ripgrep}/bin/rg -t nix 'hexToRgbSpaceSeparated\s+\w+\.hex' ${../../modules} 2>/dev/null; then
    echo "ERROR: Found hexToRgbSpaceSeparated called with .hex property"
    echo "hexToRgbSpaceSeparated expects a color object, not a hex string"
    echo ""
    echo "Wrong:  signalLib.hexToRgbSpaceSeparated color.hex"
    echo "Right:  signalLib.hexToRgbSpaceSeparated color"
    exit 1
  fi

  if ${pkgs.ripgrep}/bin/rg -t nix 'signalLib\.hexToRgbSpaceSeparated\s+\w+\.hex' ${../../modules} 2>/dev/null; then
    echo "ERROR: Found signalLib.hexToRgbSpaceSeparated called with .hex property"
    echo "hexToRgbSpaceSeparated expects a color object, not a hex string"
    echo ""
    echo "Wrong:  signalLib.hexToRgbSpaceSeparated color.hex"
    echo "Right:  signalLib.hexToRgbSpaceSeparated color"
    exit 1
  fi

  echo "✓ hexToRgbSpaceSeparated usage is correct"

  # ============================================================================
  # Check: hexToRgbCommaSeparated should receive color objects
  # ============================================================================
  echo "Checking hexToRgbCommaSeparated usage..."

  if ${pkgs.ripgrep}/bin/rg -t nix 'hexToRgbCommaSeparated\s+\w+\.hex' ${../../modules} 2>/dev/null; then
    echo "ERROR: Found hexToRgbCommaSeparated called with .hex property"
    echo "hexToRgbCommaSeparated expects a color object, not a hex string"
    echo ""
    echo "Wrong:  signalLib.hexToRgbCommaSeparated color.hex"
    echo "Right:  signalLib.hexToRgbCommaSeparated color"
    exit 1
  fi

  if ${pkgs.ripgrep}/bin/rg -t nix 'signalLib\.hexToRgbCommaSeparated\s+\w+\.hex' ${../../modules} 2>/dev/null; then
    echo "ERROR: Found signalLib.hexToRgbCommaSeparated called with .hex property"
    echo "hexToRgbCommaSeparated expects a color object, not a hex string"
    echo ""
    echo "Wrong:  signalLib.hexToRgbCommaSeparated color.hex"
    echo "Right:  signalLib.hexToRgbCommaSeparated color"
    exit 1
  fi

  echo "✓ hexToRgbCommaSeparated usage is correct"

  # ============================================================================
  # Check: Conversion functions should not receive uncalled semantic functions
  # ============================================================================
  echo "Checking conversion function argument parentheses..."

  # Pattern: (toFunction semantic.category "name" mode) - WRONG
  # Should be: (toFunction (semantic.category "name" mode)) - RIGHT
  if ${pkgs.ripgrep}/bin/rg -t nix '\(to\w+\s+semantic\.\w+\s+"[^"]+"\s+\w+\)' ${../../modules} 2>/dev/null; then
    echo "ERROR: Found conversion function called with uncalled semantic function"
    echo "Conversion functions expect color objects, not function calls as separate arguments"
    echo ""
    echo "Wrong:  (toZellijColor semantic.multiplayer \"player-1\" themeMode)"
    echo "Right:  (toZellijColor (semantic.multiplayer \"player-1\" themeMode))"
    exit 1
  fi

  echo "✓ Conversion function arguments are correctly parenthesized"

  # ============================================================================
  # Success
  # ============================================================================
  echo ""
  echo "✓ All signalLib function calls have correct argument types"
  touch $out
''
