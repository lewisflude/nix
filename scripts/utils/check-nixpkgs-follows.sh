#!/usr/bin/env bash
# Check which flake inputs should follow nixpkgs
# This script analyzes your flake.nix and flake.lock to identify inputs that might need follows = "nixpkgs"

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

echo "🔍 Analyzing flake inputs for nixpkgs follows requirements..."
echo ""

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Extract inputs from flake.nix
echo "📋 Inputs defined in flake.nix:"
echo ""

# Check each input
check_input() {
  local input_name=$1
  local has_follows=$2
  local url=$3

  # Skip nixpkgs itself
  if [[ "$input_name" == "nixpkgs" ]]; then
    return
  fi

  # Check if it's a data-only flake (flake = false)
  if grep -A 5 "\"$input_name\"" flake.nix | grep -q "flake = false"; then
    echo -e "${BLUE}✓${NC} $input_name: ${GREEN}Data-only flake${NC} (no follows needed)"
    return
  fi

  # Check if explicitly documented not to follow
  if grep -A 5 "\"$input_name\"" flake.nix | grep -qi "do not follow\|don't follow\|not follow"; then
    echo -e "${BLUE}✓${NC} $input_name: ${YELLOW}Explicitly documented not to follow${NC}"
    return
  fi

  # Determine if it should follow based on usage patterns
  local should_follow=false
  local reason=""

  # Check if input provides modules (needs nixpkgs compatibility)
  if grep -r "inputs\.$input_name.*\.nixosModules\|inputs\.$input_name.*\.darwinModules\|inputs\.$input_name.*\.homeManagerModules\|inputs\.$input_name.*\.homeModules" lib/ modules/ overlays/ 2>/dev/null | head -1 > /dev/null; then
    should_follow=true
    reason="provides NixOS/Darwin/Home Manager modules"
  fi

  # Check if input provides overlays (needs nixpkgs compatibility)
  if grep -r "inputs\.$input_name.*\.overlays" lib/ modules/ overlays/ 2>/dev/null | head -1 > /dev/null; then
    should_follow=true
    reason="provides overlays"
  fi

  # Check if input provides packages (needs nixpkgs compatibility)
  if grep -r "inputs\.$input_name.*\.packages\|inputs\.$input_name.*\.legacyPackages" lib/ modules/ overlays/ 2>/dev/null | head -1 > /dev/null; then
    should_follow=true
    reason="provides packages"
  fi

  # Check if it's a well-known module provider
  local known_modules=("darwin" "home-manager" "sops-nix" "niri" "musnix" "catppuccin" "determinate" "nix-topology" "vpn-confinement")
  for known in "${known_modules[@]}"; do
    if [[ "$input_name" == "$known" ]]; then
      should_follow=true
      reason="known module provider"
      break
    fi
  done

  # Check if it's a well-known overlay provider
  local known_overlays=("rust-overlay" "nur" "chaotic")
  for known in "${known_overlays[@]}"; do
    if [[ "$input_name" == "$known" ]]; then
      # Special case: chaotic explicitly doesn't follow
      if [[ "$input_name" == "chaotic" ]]; then
        should_follow=false
        reason="explicitly documented not to follow (cache reasons)"
      else
        should_follow=true
        reason="known overlay provider"
      fi
      break
    fi
  done

  # Output result
  if [[ "$has_follows" == "true" ]]; then
    if [[ "$should_follow" == "true" ]]; then
      echo -e "${GREEN}✓${NC} $input_name: ${GREEN}Has follows${NC} (correct - $reason)"
    else
      echo -e "${YELLOW}⚠${NC} $input_name: ${YELLOW}Has follows but may not need it${NC}"
    fi
  else
    if [[ "$should_follow" == "true" ]]; then
      echo -e "${RED}✗${NC} $input_name: ${RED}MISSING follows${NC} (should follow - $reason)"
    else
      echo -e "${BLUE}?${NC} $input_name: ${BLUE}No follows${NC} (may be OK - check input's flake.nix)"
    fi
  fi
}

# Parse flake.nix to extract inputs
echo "Analyzing inputs..."
echo ""

# Extract input names and check for follows
while IFS= read -r line; do
  # Match input definitions
  if [[ "$line" =~ ^[[:space:]]*([a-zA-Z0-9_-]+)[[:space:]]*=[[:space:]]*\{ ]]; then
    input_name="${BASH_REMATCH[1]}"

    # Check if this input block has follows
    has_follows=false
    url=""

    # Read ahead to find the input block
    input_block=""
    brace_count=0
    in_block=false

    # This is a simplified check - we'll use a better approach
    if grep -A 10 "\"$input_name\"" flake.nix | grep -q "follows.*nixpkgs"; then
      has_follows=true
    fi

    # Get URL for context
    url=$(grep -A 5 "\"$input_name\"" flake.nix | grep -oP 'url\s*=\s*"\K[^"]+' | head -1 || echo "unknown")

    check_input "$input_name" "$has_follows" "$url"
  fi
done < <(grep -E "^[[:space:]]*[a-zA-Z0-9_-]+[[:space:]]*=" flake.nix | head -30)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Summary:"
echo ""
echo "Rules for when inputs SHOULD follow nixpkgs:"
echo "  1. ✅ Input provides NixOS/Darwin/Home Manager modules"
echo "  2. ✅ Input provides overlays or packages"
echo "  3. ✅ Input is a library/tool that integrates with nixpkgs"
echo ""
echo "Rules for when inputs should NOT follow nixpkgs:"
echo "  1. ❌ Input explicitly documents not to follow (e.g., chaotic-nyx)"
echo "  2. ❌ Input is data-only (flake = false)"
echo "  3. ❌ Input provides its own nixpkgs fork/version"
echo ""
echo "To manually check an input:"
echo "  1. Visit the input's repository"
echo "  2. Check its flake.nix for nixpkgs input"
echo "  3. Check its README for follows recommendations"
echo "  4. If it provides modules/overlays, it likely needs follows"
echo ""
