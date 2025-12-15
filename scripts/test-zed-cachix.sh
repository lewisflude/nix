#!/usr/bin/env bash
# Test script to verify Zed editor Cachix substituters are working
# Run this AFTER darwin-rebuild switch

set -euo pipefail

echo "=================================================="
echo "Zed Editor Cachix Substituter Test"
echo "=================================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the zed-editor store path from the flake
echo -e "${BLUE}1. Getting Zed editor store path...${NC}"
ZED_PATH=$(nix eval --raw '.#darwinConfigurations.mercury.pkgs.zed-editor.outPath' 2>/dev/null || echo "")

if [ -z "$ZED_PATH" ]; then
    echo -e "${RED}❌ Failed to get Zed editor path${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Zed editor path: ${ZED_PATH}${NC}"
echo ""

# Check if it's already in the local store
echo -e "${BLUE}2. Checking local Nix store...${NC}"
if nix-store --query --valid-paths "$ZED_PATH" 2>/dev/null; then
    echo -e "${GREEN}✓ Zed editor is already in your local store${NC}"
    echo -e "${YELLOW}  (Already downloaded/built)${NC}"
else
    echo -e "${YELLOW}⚠ Zed editor is NOT in local store yet${NC}"
fi
echo ""

# Check system-level substituter configuration
echo -e "${BLUE}3. Checking system-level substituter configuration...${NC}"
if nix config show | grep -q "zed.cachix.org"; then
    echo -e "${GREEN}✓ zed.cachix.org is configured as a substituter${NC}"
else
    echo -e "${RED}❌ zed.cachix.org is NOT configured${NC}"
    echo -e "${YELLOW}  Run 'darwin-rebuild switch --flake .' to apply config${NC}"
fi
echo ""

# Test if zed.cachix.org has the package
echo -e "${BLUE}4. Testing if zed.cachix.org has this Zed version...${NC}"
if curl -s -f -I "https://zed.cachix.org${ZED_PATH}.narinfo" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ zed.cachix.org HAS this Zed version!${NC}"
    echo -e "  ${GREEN}Build will use binary cache ⚡${NC}"
else
    echo -e "${RED}❌ zed.cachix.org does NOT have this version${NC}"
    echo -e "${YELLOW}  Will need to build from source (but tests disabled for speed)${NC}"
fi
echo ""

# Check other important caches
echo -e "${BLUE}5. Testing other configured caches...${NC}"
CACHES=(
    "cache.nixos.org"
    "nix-community.cachix.org"
    "chaotic-nyx.cachix.org"
    "claude-code.cachix.org"
)

for cache in "${CACHES[@]}"; do
    cache_url="https://${cache}"
    if curl -s -f -I "${cache_url}/nix-cache-info" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ ${cache} is reachable${NC}"
    else
        echo -e "${RED}✗ ${cache} is NOT reachable${NC}"
    fi
done
echo ""

# Check if doCheck=false is applied
echo -e "${BLUE}6. Verifying doCheck=false optimization...${NC}"
if nix eval --json '.#darwinConfigurations.mercury.pkgs.zed-editor.drvAttrs' 2>/dev/null | grep -q '"doCheck":false'; then
    echo -e "${GREEN}✓ doCheck is set to false (tests disabled)${NC}"
    echo -e "  ${GREEN}Build will skip expensive test suite ⚡${NC}"
else
    echo -e "${YELLOW}⚠ Could not verify doCheck setting${NC}"
fi
echo ""

# Dry-run build to see what would happen
echo -e "${BLUE}7. Performing dry-run build test...${NC}"
echo -e "${YELLOW}This shows what would be built vs substituted${NC}"
echo ""

nix build ".#darwinConfigurations.mercury.pkgs.zed-editor" --dry-run 2>&1 | grep -E "(will be built|will be fetched|warning)" | head -n 20

echo ""
echo "=================================================="
echo -e "${BLUE}Summary${NC}"
echo "=================================================="
echo ""
echo "To apply configuration changes and use the caches:"
echo -e "  ${YELLOW}darwin-rebuild switch --flake .${NC}"
echo ""
echo "After rebuild, re-run this script to verify caches are active."
echo ""
echo "To test an actual build with verbose output:"
echo -e "  ${YELLOW}nix build --rebuild '.#darwinConfigurations.mercury.pkgs.zed-editor' -L${NC}"
echo ""
