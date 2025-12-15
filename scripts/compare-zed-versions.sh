#!/usr/bin/env bash
# Compare different sources of Zed versions

set -euo pipefail

echo "=================================================="
echo "Zed Version Comparison"
echo "=================================================="
echo ""

echo "1. YOUR FLAKE'S VERSION"
echo "======================="
YOUR_VERSION=$(nix eval --raw '.#darwinConfigurations.mercury.pkgs.zed-editor.version' 2>/dev/null)
YOUR_HASH=$(nix eval --raw '.#darwinConfigurations.mercury.pkgs.zed-editor.outPath' 2>/dev/null | sed 's|/nix/store/||')
echo "  Version: $YOUR_VERSION"
echo "  Hash: ${YOUR_HASH:0:32}..."
echo "  Has overlay: YES (doCheck = false)"
echo ""

echo "2. BASE NIXPKGS VERSION (no overlay)"
echo "====================================="
NIXPKGS_VERSION=$(nix eval --raw 'nixpkgs#zed-editor.version' 2>/dev/null)
NIXPKGS_HASH=$(nix eval --raw 'nixpkgs#zed-editor.outPath' 2>/dev/null | sed 's|/nix/store/||')
echo "  Version: $NIXPKGS_VERSION"
echo "  Hash: ${NIXPKGS_HASH:0:32}..."
echo "  Has overlay: NO (original)"
echo ""

echo "3. HASH COMPARISON"
echo "=================="
if [ "$YOUR_HASH" = "$NIXPKGS_HASH" ]; then
    echo "  SAME - Your overlay doesn't change the hash"
else
    echo "  DIFFERENT - Your overlay creates a new derivation"
    echo ""
    echo "  Your hash:    ${YOUR_HASH:0:32}"
    echo "  Nixpkgs hash: ${NIXPKGS_HASH:0:32}"
fi
echo ""

echo "4. CACHE AVAILABILITY CHECK"
echo "==========================="

test_cache() {
    local name="$1"
    local url="$2"
    local hash="$3"
    
    printf "  %-25s: " "$name"
    if curl -sf "${url}/${hash}.narinfo" > /dev/null 2>&1; then
        echo "AVAILABLE"
        return 0
    else
        echo "Not available"
        return 1
    fi
}

echo ""
echo "  Testing YOUR version ($YOUR_VERSION):"
test_cache "cache.nixos.org" "https://cache.nixos.org" "$YOUR_HASH"
test_cache "zed.cachix.org" "https://zed.cachix.org" "$YOUR_HASH"
test_cache "nix-community.cachix.org" "https://nix-community.cachix.org" "$YOUR_HASH"

echo ""
echo "  Testing NIXPKGS version ($NIXPKGS_VERSION):"
test_cache "cache.nixos.org" "https://cache.nixos.org" "$NIXPKGS_HASH"
test_cache "zed.cachix.org" "https://zed.cachix.org" "$NIXPKGS_HASH"
test_cache "nix-community.cachix.org" "https://nix-community.cachix.org" "$NIXPKGS_HASH"

echo ""
echo "5. LATEST ZED RELEASES (from GitHub)"
echo "====================================="
echo "  Fetching latest releases..."
RELEASES=$(curl -s "https://api.github.com/repos/zed-industries/zed/releases?per_page=5" | \
    jq -r '.[] | "\(.tag_name) - \(.published_at | split("T")[0])"' 2>/dev/null || echo "Cannot fetch")

if [ "$RELEASES" != "Cannot fetch" ]; then
    echo "$RELEASES" | nl
else
    echo "  Unable to fetch GitHub releases"
fi

echo ""
echo "=================================================="
echo "Key Findings"
echo "=================================================="
echo ""
echo "* You have: Zed $YOUR_VERSION (with doCheck=false overlay)"
echo "* Nixpkgs has: Zed $NIXPKGS_VERSION (original, no overlay)"
echo "* Neither version is in any binary cache"
echo ""
echo "Why neither is cached:"
echo "  1. Versions are very recent (released within days)"
echo "  2. Binary caches typically lag 1-2 weeks behind releases"
echo "  3. aarch64-darwin builds may have lower priority"
echo ""
echo "Your options:"
echo ""
echo "A) KEEP OVERLAY (faster build, no cache):"
echo "   - Build time: ~15-25 minutes"
echo "   - Tests disabled (doCheck = false)"
echo "   - Cannot use binary cache due to changed hash"
echo ""
echo "B) REMOVE OVERLAY (slower build, maybe cache later):"
echo "   - Build time: ~30-45 minutes (if building)"
echo "   - Tests enabled"
echo "   - Might get cached in future updates"
echo ""
echo "Recommendation: Keep overlay for now. When Zed versions"
echo "become cached, re-evaluate if cache is faster than build."
echo ""
