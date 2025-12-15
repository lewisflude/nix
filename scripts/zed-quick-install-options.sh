#!/usr/bin/env bash
# Quick installation options for Zed editor

set -euo pipefail

echo "=================================================="
echo "Faster Ways to Install Zed on Nix-Darwin"
echo "=================================================="
echo ""

echo "CURRENT SITUATION:"
echo "=================="
echo "Your nix build: 15-25 minutes (with doCheck=false)"
echo ""
echo "Let's explore faster options..."
echo ""

echo "=================================================="
echo "OPTION 1: Official Zed Binary (FASTEST)"
echo "=================================================="
echo ""
echo "Time: ~2 minutes"
echo "Method: Download pre-built .dmg from zed.dev"
echo ""
echo "Steps:"
echo "  1. Visit: https://zed.dev/download"
echo "  2. Download macOS .dmg"
echo "  3. Install like any Mac app"
echo ""
echo "Pros:"
echo "  ⚡ INSTANT (just download)"
echo "  ✅ Official build from Zed team"
echo "  🔄 Auto-updates work"
echo "  📦 No compilation needed"
echo ""
echo "Cons:"
echo "  ❌ Not managed by Nix"
echo "  ❌ Won't be in PATH automatically"
echo "  ❌ Separate from your dotfiles config"
echo ""
echo "Install command:"
echo "  curl -L https://zed.dev/api/releases/stable/latest/Zed-aarch64.dmg -o /tmp/Zed.dmg"
echo "  open /tmp/Zed.dmg"
echo ""

echo "=================================================="
echo "OPTION 2: Homebrew (Quick & Easy)"
echo "=================================================="
echo ""
echo "Time: ~2-5 minutes"
echo "Method: Use Homebrew cask"
echo ""
echo "Steps:"
echo "  brew install --cask zed"
echo ""
echo "Pros:"
echo "  ⚡ Fast (pre-built binary)"
echo "  🔄 Easy updates: brew upgrade"
echo "  📦 Familiar for macOS users"
echo ""
echo "Cons:"
echo "  ❌ Not managed by Nix"
echo "  ⚠️  Requires Homebrew installed"
echo "  ❌ Outside your nix config"
echo ""

echo "=================================================="
echo "OPTION 3: Older Cached Nixpkgs (Compromise)"
echo "=================================================="
echo ""
echo "Time: ~30 seconds (if cached)"
echo "Method: Roll back to older nixpkgs with cached Zed"
echo ""
echo "Checking what's available in cache..."
echo ""

# Try to find an older cached version
echo "Attempting to find cached older versions..."
echo ""

# Check a few older nixpkgs commits known to have cached packages
OLD_COMMITS=(
    "nixos-24.05"    # Last stable release
    "nixos-unstable" # Unstable channel
)

for commit in "${OLD_COMMITS[@]}"; do
    echo "Testing: $commit"
    
    # Try to get version
    VERSION=$(nix eval "github:NixOS/nixpkgs/$commit#zed-editor.version" 2>/dev/null || echo "unavailable")
    
    if [ "$VERSION" != "unavailable" ]; then
        echo "  Version available: $VERSION"
        
        # Test if cached
        OUTPATH=$(nix eval --raw "github:NixOS/nixpkgs/$commit#zed-editor.outPath" 2>/dev/null || echo "")
        if [ -n "$OUTPATH" ]; then
            HASH=$(basename "$OUTPATH")
            
            if curl -sf "https://cache.nixos.org/${HASH}.narinfo" > /dev/null 2>&1; then
                echo "  ✅ CACHED in cache.nixos.org!"
                echo ""
                echo "  To use this version:"
                echo "    nix profile install 'github:NixOS/nixpkgs/$commit#zed-editor'"
                echo ""
                FOUND_CACHED=true
            else
                echo "  ❌ Not cached"
            fi
        fi
    fi
    echo ""
done

echo "=================================================="
echo "OPTION 4: Zed Official Flake (Maybe Better?)"
echo "=================================================="
echo ""
echo "Time: Unknown (depends on CI)"
echo "Method: Use Zed's official flake"
echo ""

echo "Your config has this DISABLED:"
echo "  # overlays/default.nix"
echo "  # TODO: Re-enable when zed flake build issues are resolved"
echo ""

echo "The Zed flake might have:"
echo "  - Pre-built CI artifacts"
echo "  - Better caching via GitHub Actions"
echo "  - Might be faster than nixpkgs"
echo ""

echo "To test:"
echo "  nix build 'github:zed-industries/zed' -L"
echo ""

echo "If it works, you could re-enable in overlays/default.nix"
echo ""

echo "=================================================="
echo "OPTION 5: Use AppImage (Linux) or DMG (macOS)"
echo "=================================================="
echo ""
echo "Time: ~2 minutes"
echo "Method: Manual installation outside Nix"
echo ""

echo "For macOS (your platform):"
echo "  1. Download from: https://zed.dev/releases"
echo "  2. Drag Zed.app to /Applications"
echo "  3. Done!"
echo ""

echo "To integrate with Nix later:"
echo "  - Keep using Homebrew/manual install for now"
echo "  - Switch to Nix when cached versions available"
echo "  - Or wait until your build completes once"
echo ""

echo "=================================================="
echo "RECOMMENDATION"
echo "=================================================="
echo ""
echo "For IMMEDIATE use (today):"
echo "  ✅ Download official .dmg from zed.dev"
echo "  ✅ Or: brew install --cask zed"
echo ""
echo "For Nix-managed (eventual):"
echo "  1. Use Homebrew/manual now"
echo "  2. Let Nix build in background: darwin-rebuild switch &"
echo "  3. Switch to Nix version when ready"
echo ""
echo "Best of both worlds:"
echo "  - Get working editor NOW (2 min)"
echo "  - Have Nix version ready later (15-25 min)"
echo "  - Remove manual install when Nix build completes"
echo ""

echo "=================================================="
echo "Quick Install Commands"
echo "=================================================="
echo ""
echo "# Option 1: Official DMG"
echo "curl -L https://zed.dev/api/releases/stable/latest/Zed-aarch64.dmg -o /tmp/Zed.dmg && open /tmp/Zed.dmg"
echo ""
echo "# Option 2: Homebrew"
echo "brew install --cask zed"
echo ""
echo "# Option 3: Try Zed flake"
echo "nix run 'github:zed-industries/zed'"
echo ""
echo "# Option 4: Test older cached version"
echo "nix shell 'github:NixOS/nixpkgs/nixos-24.05#zed-editor'"
echo ""
