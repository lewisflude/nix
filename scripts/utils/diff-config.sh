#!/usr/bin/env bash
# Preview configuration changes before applying updates
# Usage: ./scripts/utils/diff-config.sh [config-name]
#
# This script compares your current system configuration with the new one
# to show what will change during a rebuild.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Detect system and configuration
detect_system() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "darwin"
  else
    echo "nixos"
  fi
}

detect_config() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "darwinConfigurations.$(hostname -s)"
  else
    echo "nixosConfigurations.$(hostname)"
  fi
}

SYSTEM_TYPE=$(detect_system)
CONFIG="${1:-$(detect_config)}"

echo -e "${BLUE}🔍 Comparing configuration: ${GREEN}$CONFIG${NC}"
echo ""

# Build the new configuration
echo -e "${YELLOW}⏱️  Building new configuration...${NC}"
NEW_CONFIG="/tmp/nix-config-new"
rm -rf "$NEW_CONFIG"

if ! nix build ".#$CONFIG.config.system.build.toplevel" -o "$NEW_CONFIG" 2>&1 | grep -v "warning:"; then
  echo -e "${RED}❌ Failed to build new configuration${NC}"
  exit 1
fi

echo -e "${GREEN}✓ New configuration built${NC}"
echo ""

# Find current system
if [ "$SYSTEM_TYPE" = "darwin" ]; then
  CURRENT_SYSTEM="/run/current-system"
  if [ ! -L "$CURRENT_SYSTEM" ]; then
    CURRENT_SYSTEM="$(readlink /nix/var/nix/profiles/system)"
  fi
else
  CURRENT_SYSTEM="/run/current-system"
fi

if [ ! -e "$CURRENT_SYSTEM" ]; then
  echo -e "${YELLOW}⚠️  No current system found, showing new configuration details only${NC}"
  echo ""
  echo -e "${BLUE}New configuration packages:${NC}"
  nix-store -q --requisites "$NEW_CONFIG" | wc -l | xargs echo "Total derivations:"
  exit 0
fi

# Check if nvd is available
if command -v nvd &> /dev/null; then
  echo -e "${BLUE}📊 Detailed diff using nvd:${NC}"
  echo ""
  nvd diff "$CURRENT_SYSTEM" "$NEW_CONFIG"
else
  echo -e "${YELLOW}⚠️  nvd not found, using basic diff${NC}"
  echo -e "${BLUE}   Install nvd with: nix-env -iA nixpkgs.nvd${NC}"
  echo ""
  
  # Basic diff without nvd
  echo -e "${BLUE}📦 Package changes:${NC}"
  
  CURRENT_PKGS=$(nix-store -q --requisites "$CURRENT_SYSTEM" | sort)
  NEW_PKGS=$(nix-store -q --requisites "$NEW_CONFIG" | sort)
  
  # Count changes
  ADDED=$(comm -13 <(echo "$CURRENT_PKGS") <(echo "$NEW_PKGS") | wc -l)
  REMOVED=$(comm -23 <(echo "$CURRENT_PKGS") <(echo "$NEW_PKGS") | wc -l)
  COMMON=$(comm -12 <(echo "$CURRENT_PKGS") <(echo "$NEW_PKGS") | wc -l)
  
  echo -e "  ${GREEN}+${ADDED} packages added${NC}"
  echo -e "  ${RED}-${REMOVED} packages removed${NC}"
  echo -e "  ${CYAN}=${COMMON} packages unchanged${NC}"
  echo ""
  
  # Show sample of added packages
  if [ "$ADDED" -gt 0 ]; then
    echo -e "${GREEN}Sample of added packages:${NC}"
    comm -13 <(echo "$CURRENT_PKGS") <(echo "$NEW_PKGS") | head -10 | while read pkg; do
      echo -e "  ${GREEN}+${NC} $(basename "$pkg")"
    done
    if [ "$ADDED" -gt 10 ]; then
      echo -e "  ${CYAN}... and $(( ADDED - 10 )) more${NC}"
    fi
    echo ""
  fi
  
  # Show sample of removed packages
  if [ "$REMOVED" -gt 0 ]; then
    echo -e "${RED}Sample of removed packages:${NC}"
    comm -23 <(echo "$CURRENT_PKGS") <(echo "$NEW_PKGS") | head -10 | while read pkg; do
      echo -e "  ${RED}-${NC} $(basename "$pkg")"
    done
    if [ "$REMOVED" -gt 10 ]; then
      echo -e "  ${CYAN}... and $(( REMOVED - 10 )) more${NC}"
    fi
    echo ""
  fi
fi

# Size comparison
CURRENT_SIZE=$(du -sh "$CURRENT_SYSTEM" 2>/dev/null | cut -f1 || echo "unknown")
NEW_SIZE=$(du -sh "$NEW_CONFIG" 2>/dev/null | cut -f1 || echo "unknown")

echo -e "${BLUE}💾 Configuration size:${NC}"
echo -e "  Current: ${YELLOW}$CURRENT_SIZE${NC}"
echo -e "  New:     ${YELLOW}$NEW_SIZE${NC}"
echo ""

# Git information
if git -C "$REPO_ROOT" rev-parse --git-dir > /dev/null 2>&1; then
  echo -e "${BLUE}📝 Git status:${NC}"
  echo -e "  Branch:  ${CYAN}$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD)${NC}"
  echo -e "  Commit:  ${CYAN}$(git -C "$REPO_ROOT" rev-parse --short HEAD)${NC}"
  
  if ! git -C "$REPO_ROOT" diff-index --quiet HEAD --; then
    echo -e "  Status:  ${YELLOW}⚠️  Uncommitted changes${NC}"
  else
    echo -e "  Status:  ${GREEN}✓ Clean${NC}"
  fi
  echo ""
fi

echo -e "${GREEN}✓ Configuration comparison complete${NC}"
echo ""
echo -e "${BLUE}💡 Next steps:${NC}"
if [ "$SYSTEM_TYPE" = "darwin" ]; then
  echo -e "   ${CYAN}darwin-rebuild switch --flake ~/.config/nix${NC}"
else
  echo -e "   ${CYAN}sudo nixos-rebuild switch --flake ~/.config/nix#$(hostname)${NC}"
fi
echo ""
echo -e "${YELLOW}⚠️  Always review changes before applying them to your system${NC}"

# Cleanup
rm -rf "$NEW_CONFIG"
