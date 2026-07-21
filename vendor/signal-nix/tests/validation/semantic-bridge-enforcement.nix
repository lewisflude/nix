# Validation: Enforce Semantic Bridge as Single Source of Truth
#
# This test ensures that all modules use the semantic bridge (lib/semantic.nix)
# as the exclusive interface for color access, preventing direct palette access
# that would bypass the semantic layer.
#
# Allowed patterns:
#   ✅ semantic.core "background" mode
#   ✅ semantic.getCategorical "data-viz-01" mode
#   ✅ semantic.getAccent "primary" "Lc60"
#   ✅ semantic.getTonal "black" mode
#
# Forbidden patterns:
#   ❌ signalPalette.tonal.dark."surface-base"
#   ❌ signalPalette.accent.primary.Lc75
#   ❌ palette.categorical.dark."data-viz-01"
#   ❌ Direct access to palette internals

{ pkgs, lib }:

let
  # Base modules directory
  modulesDir = ../../modules;

  # Known exceptions with documentation requirements
  # GTK module has documented architectural reasons for getAccent/getTonal usage
  knownExceptions = [
    "modules/gtk/default.nix" # Requires Lc60 tier for Adwaita spec
  ];

  # Patterns that indicate direct palette access (violations)
  forbiddenPatterns = [
    "signalPalette\\.tonal\\."
    "signalPalette\\.accent\\."
    "signalPalette\\.categorical\\."
    "palette\\.tonal\\."
    "palette\\.accent\\."
    "palette\\.categorical\\."
  ];

  # Scan all module files for violations
  violations = pkgs.runCommand "semantic-bridge-violations" { } ''
    violations_found=0

    echo "Scanning modules for direct palette access violations..."
    echo "================================================================"
    echo ""

    # Check each forbidden pattern
    ${lib.concatMapStringsSep "\n" (pattern: ''
      echo "Checking pattern: ${pattern}"
      if ${pkgs.ripgrep}/bin/rg -i '${pattern}' ${modulesDir} \
         --type nix \
         --line-number \
         --no-heading \
         --color never \
         ${lib.concatMapStringsSep " " (exc: "--glob '!${exc}'") knownExceptions} \
         > /tmp/violations_${lib.replaceStrings [ "." ] [ "_" ] pattern}.txt 2>&1; then
        
        violations_found=1
        echo "❌ VIOLATION: Direct palette access found:"
        cat /tmp/violations_${lib.replaceStrings [ "." ] [ "_" ] pattern}.txt
        echo ""
      fi
    '') forbiddenPatterns}

    if [ $violations_found -eq 1 ]; then
      echo ""
      echo "================================================================"
      echo "❌ SEMANTIC BRIDGE ENFORCEMENT FAILED"
      echo "================================================================"
      echo ""
      echo "Direct palette access detected. All modules must use the semantic"
      echo "bridge as the single source of truth for colors."
      echo ""
      echo "Instead of direct access, use:"
      echo "  • semantic.core \"background\" mode"
      echo "  • semantic.syntax \"keyword\" mode"
      echo "  • semantic.getCategorical \"data-viz-01\" mode  (for raw categorical)"
      echo "  • semantic.getAccent \"primary\" \"Lc60\"        (for tier-specific)"
      echo "  • semantic.getTonal \"black\" mode              (for extreme contrast)"
      echo ""
      echo "See: docs/SEMANTIC_BRIDGE_RULES.md for details"
      echo ""
      exit 1
    fi

    echo "✅ All modules properly use semantic bridge"
    touch $out
  '';
in
violations
