#!/usr/bin/env bash
# Analyze NixOS system configuration size
# Usage: ./scripts/utils/analyze-system-size.sh [hostname]

set -euo pipefail

HOSTNAME="${1:-jupiter}"
FLAKE_PATH="${2:-.}"

echo "Analyzing NixOS configuration size for: $HOSTNAME"
echo "=========================================="
echo ""

# Get the derivation path
echo "Getting derivation path..."
if [ "$FLAKE_PATH" = "." ]; then
    DRV_PATH=$(nix eval --raw ".#nixosConfigurations.$HOSTNAME.config.system.build.toplevel.drvPath" 2>/dev/null || true)
else
    DRV_PATH=$(nix eval --raw "$FLAKE_PATH#nixosConfigurations.$HOSTNAME.config.system.build.toplevel.drvPath" 2>/dev/null || true)
fi

if [ -z "$DRV_PATH" ]; then
    echo "Error: Could not get derivation path. Make sure the configuration evaluates correctly."
    exit 1
fi

echo "Derivation: $DRV_PATH"
echo ""

# Count total derivations in closure
echo "Counting derivations in closure..."
TOTAL_DRVS=$(nix-store -qR "$DRV_PATH" 2>/dev/null | wc -l)
echo "Total derivations: $TOTAL_DRVS"
echo ""

# Try to get size information if the system is built
if [ "$FLAKE_PATH" = "." ]; then
    BUILT_PATH=$(nix eval --raw ".#nixosConfigurations.$HOSTNAME.config.system.build.toplevel" 2>/dev/null || echo "")
else
    BUILT_PATH=$(nix eval --raw "$FLAKE_PATH#nixosConfigurations.$HOSTNAME.config.system.build.toplevel" 2>/dev/null || echo "")
fi

if [ -n "$BUILT_PATH" ] && [ -e "$BUILT_PATH" ]; then
    echo "System is built. Analyzing closure sizes..."
    echo ""

    # Get size of entire closure
    echo "Getting closure size information..."
    nix path-info -rS "$BUILT_PATH" 2>/dev/null | sort -k2 -rn | head -50 | \
        awk '{printf "%-12s %s\n", $2, $1}' | \
        column -t -s' ' | head -30

    echo ""
    echo "Total closure size:"
    nix path-info -rS "$BUILT_PATH" 2>/dev/null | awk '{sum+=$2} END {print sum " bytes (" sum/1024/1024/1024 " GB)"}'
else
    echo "System is not built yet. To get size information, you need to build it first:"
    if [ "$FLAKE_PATH" = "." ]; then
        echo "  nix build .#nixosConfigurations.$HOSTNAME.config.system.build.toplevel"
        echo ""
        echo "Or use nix-tree on the derivation:"
        echo "  nix-tree --derivation $DRV_PATH"
        echo ""
        echo "To use nix-tree interactively (after building):"
        echo "  nix-tree .#nixosConfigurations.$HOSTNAME.config.system.build.toplevel"
    else
        echo "  nix build $FLAKE_PATH#nixosConfigurations.$HOSTNAME.config.system.build.toplevel"
        echo ""
        echo "Or use nix-tree on the derivation:"
        echo "  nix-tree --derivation $DRV_PATH"
        echo ""
        echo "To use nix-tree interactively (after building):"
        echo "  nix-tree $FLAKE_PATH#nixosConfigurations.$HOSTNAME.config.system.build.toplevel"
    fi
fi
echo ""
echo "Note: nix-tree works best when the system is built. If not built, use --derivation flag."
