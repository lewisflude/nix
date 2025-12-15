#!/usr/bin/env bash
# Check what Zed versions are available in different sources

set -euo pipefail

echo "=================================================="
echo "Available Zed Editor Versions"
echo "=================================================="
echo ""

echo "1. YOUR CURRENT FLAKE (with overlay)"
echo "====================================="
ZED_VERSION=$(nix eval --raw '.#darwinConfigurations.mercury.pkgs.zed-editor.version' 2>/dev/null || echo "unknown")
ZED_PATH=$(nix eval --raw '.#darwinConfigurations.mercury.pkgs.zed-editor.outPath' 2>/dev/null || echo "")
echo "  Version: $ZED_VERSION"
echo "  Store path: $ZED_PATH"

# Check if it has our override
if nix eval --json '.#darwinConfigurations.mercury.pkgs.zed-editor.drvAttrs' 2>/dev/null | grep -q '"doCheck":false'; then
    echo "  Customization: doCheck = false (tests disabled)"
    echo "  Cache impact: Different hash from upstream"
else
    echo "  Customization: None"
fi
echo ""

echo "2. NIXPKGS (without your overlay)"
echo "=================================="
# Get version from nixpkgs directly
NIXPKGS_VERSION=$(nix eval --raw 'nixpkgs#zed-editor.version' 2>/dev/null || echo "unavailable")
NIXPKGS_PATH=$(nix eval --raw 'nixpkgs#zed-editor.outPath' 2>/dev/null || echo "")
echo "  Version: $NIXPKGS_VERSION"
echo "  Store path: $NIXPKGS_PATH"

if [ "$ZED_PATH" = "$NIXPKGS_PATH" ]; then
    echo "  Status: SAME as your flake"
else
    echo "  Status: DIFFERENT from your flake"
    echo "  Reason: Your overlay changes the derivation"
fi
echo ""

echo "3. CHECK IF NIXPKGS VERSION IS CACHED"
echo "======================================"
if [ -n "$NIXPKGS_PATH" ] && [ "$NIXPKGS_PATH" != "" ]; then
    NIXPKGS_HASH=$(basename "$NIXPKGS_PATH")
    
    echo "  Testing cache.nixos.org..."
    if curl -sf "https://cache.nixos.org/${NIXPKGS_HASH}.narinfo" > /dev/null 2>&1; then
        echo "    FOUND in cache.nixos.org!"
        echo "    (But you won't get it because of your overlay)"
    else
        echo "    NOT in cache.nixos.org"
    fi
    
    echo ""
    echo "  Testing zed.cachix.org..."
    if curl -sf "https://zed.cachix.org/${NIXPKGS_HASH}.narinfo" > /dev/null 2>&1; then
        echo "    FOUND in zed.cachix.org!"
        echo "    (But you won't get it because of your overlay)"
    else
        echo "    NOT in zed.cachix.org"
    fi
else
    echo "  Cannot test - nixpkgs path unavailable"
fi
echo ""

echo "4. NIXPKGS COMMIT INFO"
echo "======================"
# Try to get the nixpkgs commit
NIXPKGS_REV=$(nix flake metadata --json 2>/dev/null | jq -r '.locks.nodes.nixpkgs.locked.rev // "unknown"' 2>/dev/null || echo "unknown")
if [ "$NIXPKGS_REV" != "unknown" ]; then
    echo "  Commit: $NIXPKGS_REV"
    echo "  Short: ${NIXPKGS_REV:0:7}"
    echo "  GitHub: https://github.com/NixOS/nixpkgs/commit/$NIXPKGS_REV"
else
    echo "  Commit: Cannot determine"
fi
echo ""

echo "=================================================="
echo "Summary"
echo "=================================================="
echo ""
echo "Your configuration uses Zed $ZED_VERSION with custom overlay."
echo ""
echo "The overlay (doCheck = false) changes the derivation hash,"
echo "which means even if the base version is cached, YOUR version"
echo "will need to be built because it's technically different."
echo ""
echo "This is a trade-off:"
echo "  PRO: Faster builds (no tests = ~50% time saved)"
echo "  CON: Cannot use binary cache for this package"
echo ""
echo "To use the cache instead of speed optimization, remove the"
echo "overlay from overlays/default.nix and restore:"
echo "  inherit (prev) zed-editor;"
echo ""
