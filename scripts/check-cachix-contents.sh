#!/usr/bin/env bash
# Check what's actually available in various caches for zed-editor

set -euo pipefail

echo "=================================================="
echo "Checking What's Available in Caches"
echo "=================================================="
echo ""

# Function to check cache contents
check_cache() {
    local cache_name="$1"
    local cache_url="$2"
    
    echo "Checking $cache_name..."
    echo "URL: $cache_url"
    echo ""
    
    # Try to get cache info
    if curl -sf "${cache_url}/nix-cache-info" > /dev/null 2>&1; then
        echo "  Status: Online and reachable"
        
        # Get some basic info
        curl -s "${cache_url}/nix-cache-info" | head -n 5
        echo ""
    else
        echo "  Status: Cannot access cache info"
        echo ""
        return 1
    fi
}

# Check the main caches
echo "1. Official NixOS Cache"
echo "========================"
check_cache "cache.nixos.org" "https://cache.nixos.org"

echo "2. Zed Cachix"
echo "=============="
check_cache "zed.cachix.org" "https://zed.cachix.org"

echo "3. Nix Community Cachix"
echo "======================="
check_cache "nix-community.cachix.org" "https://nix-community.cachix.org"

echo ""
echo "=================================================="
echo "Why Your Zed Version Might Not Be Cached"
echo "=================================================="
echo ""

echo "Possible reasons:"
echo ""
echo "1. VERSION TOO RECENT"
echo "   - Binary caches typically lag behind latest releases"
echo "   - Zed 0.215.3 may be very recent"
echo ""

echo "2. CUSTOM OVERLAY APPLIED"
echo "   - Your config uses: zed-editor.overrideAttrs { doCheck = false; }"
echo "   - This changes the derivation hash"
echo "   - Cache has the original, not your modified version"
echo ""

echo "3. DIFFERENT NIXPKGS VERSION"
echo "   - Your flake.lock pins specific nixpkgs commits"
echo "   - Cache might be built from different commits"
echo ""

echo "4. ARCHITECTURE-SPECIFIC"
echo "   - You're on: $(uname -m)"
echo "   - Some caches prioritize x86_64 builds"
echo ""

echo "=================================================="
echo "Checking Your Specific Configuration"
echo "=================================================="
echo ""

# Get the actual derivation
echo "Your Zed derivation:"
ZED_DRV=$(nix eval --raw '.#darwinConfigurations.mercury.pkgs.zed-editor.drvPath' 2>/dev/null || echo "")
if [ -n "$ZED_DRV" ]; then
    echo "  Derivation: $ZED_DRV"
    
    # Show if it has our override
    if nix derivation show "$ZED_DRV" 2>/dev/null | grep -q '"doCheck": false'; then
        echo "  Override: doCheck = false (APPLIED)"
        echo "  This means: Your derivation is DIFFERENT from cache"
    fi
fi

echo ""
echo "To see what the cache has, check nixpkgs source or Zed releases."
echo ""
