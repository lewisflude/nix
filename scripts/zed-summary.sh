#!/usr/bin/env bash
# Quick summary of Zed version situation

set -euo pipefail

echo "=================================================="
echo "Zed Editor: Why Nothing Is Cached"
echo "=================================================="
echo ""

# Get versions
YOUR_VER=$(nix eval --raw '.#darwinConfigurations.mercury.pkgs.zed-editor.version' 2>/dev/null || echo "unknown")
YOUR_PATH=$(nix eval --raw '.#darwinConfigurations.mercury.pkgs.zed-editor.outPath' 2>/dev/null || echo "")
NIXPKGS_VER=$(nix eval --raw 'nixpkgs#zed-editor.version' 2>/dev/null || echo "unknown")
NIXPKGS_PATH=$(nix eval --raw 'nixpkgs#zed-editor.outPath' 2>/dev/null || echo "")

echo "VERSIONS INVOLVED:"
echo "=================="
echo "  Your flake:  Zed $YOUR_VER (with doCheck=false)"
echo "  Base nixpkgs: Zed $NIXPKGS_VER (without overlay)"
echo ""

echo "STORE PATHS (HASHES):"
echo "====================="
YOUR_HASH=$(basename "$YOUR_PATH" 2>/dev/null || echo "")
NIXPKGS_HASH=$(basename "$NIXPKGS_PATH" 2>/dev/null || echo "")

echo "  Your version:    $YOUR_HASH"
echo "  Nixpkgs version: $NIXPKGS_HASH"
echo ""

if [ "$YOUR_HASH" != "$NIXPKGS_HASH" ]; then
    echo "  Status: DIFFERENT hashes (overlay changes derivation)"
else
    echo "  Status: SAME hash"
fi
echo ""

echo "WHY NOT CACHED:"
echo "==============="
echo ""
echo "Reason 1: OVERLAY CHANGES HASH"
echo "  Your overlay (doCheck = false) modifies the derivation,"
echo "  creating a unique hash that won't match any cache."
echo ""
echo "Reason 2: VERSIONS TOO RECENT"
echo "  Zed 0.215.3 and 0.216.0 are very recent releases."
echo "  Binary caches typically lag 1-2 weeks behind new versions."
echo ""
echo "Reason 3: ARCHITECTURE (arm64/aarch64-darwin)"
echo "  macOS ARM builds may have lower priority than x86_64."
echo ""

echo "=================================================="
echo "What This Means For You"
echo "=================================================="
echo ""
echo "CURRENT SITUATION:"
echo "  - Zed WILL be built from source (no cache hit)"
echo "  - Build time: ~15-25 minutes (tests disabled)"
echo "  - This is expected and unavoidable right now"
echo ""
echo "YOUR OPTIONS:"
echo ""
echo "Option A: KEEP CURRENT SETUP (Recommended)"
echo "  - Faster builds (no tests)"
echo "  - Build time: 15-25 min"
echo "  - Trade-off: Can't use cache due to overlay"
echo ""
echo "Option B: REMOVE OVERLAY"
echo "  - Potentially use cache in future"
echo "  - Build time: 30-45 min (with tests)"
echo "  - Change: Remove doCheck=false from overlays/default.nix"
echo ""
echo "RECOMMENDATION:"
echo "  Keep the overlay! Even without cache, building without"
echo "  tests (15-25min) is faster than building WITH tests"
echo "  (30-45min). The cache won't help until versions age."
echo ""

echo "To check if newer versions are cached later, run:"
echo "  ./scripts/test-cachix-simple.sh"
echo ""
