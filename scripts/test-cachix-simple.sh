#!/usr/bin/env bash
# Simple test to check if a package is available in various caches
# Usage: ./test-cachix-simple.sh [store-path]

set -euo pipefail

# Get store path from argument or detect zed-editor
STORE_PATH="${1:-}"

if [ -z "$STORE_PATH" ]; then
    echo "Getting Zed editor store path..."
    STORE_PATH=$(nix eval --raw '.#darwinConfigurations.mercury.pkgs.zed-editor.outPath' 2>/dev/null)
fi

echo "Testing cache availability for: $STORE_PATH"
echo ""

# Extract just the hash-name part after /nix/store/
STORE_HASH=$(basename "$STORE_PATH")

# Test various caches
declare -A CACHES=(
    ["Official NixOS"]="https://cache.nixos.org"
    ["Zed Cachix"]="https://zed.cachix.org"
    ["Nix Community"]="https://nix-community.cachix.org"
    ["Chaotic Nyx"]="https://chaotic-nyx.cachix.org"
)

echo "Checking which caches have this package:"
echo "=========================================="
echo ""

for name in "${!CACHES[@]}"; do
    url="${CACHES[$name]}"
    narinfo_url="${url}/${STORE_HASH}.narinfo"
    
    printf "%-20s: " "$name"
    
    if curl -s -f -I "$narinfo_url" > /dev/null 2>&1; then
        echo "✅ AVAILABLE"
        
        # Show some info about the cached package
        if [ "$name" = "Zed Cachix" ]; then
            echo "   → Full URL: $narinfo_url"
            echo "   → Downloading from here will be FAST ⚡"
        fi
    else
        echo "❌ Not available"
    fi
done

echo ""
echo "=========================================="
echo ""

# Check if already in local store
if nix-store --query --valid-paths "$STORE_PATH" 2>/dev/null; then
    echo "✅ Package is already in your local Nix store"
    echo "   (No download needed)"
else
    echo "⚠️  Package is NOT in local store yet"
    echo "   Will be downloaded/built on next system rebuild"
fi

echo ""
