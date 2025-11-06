#!/usr/bin/env bash
# Check what will be built vs what will be substituted from cache
# Usage: ./check-build-vs-cache.sh [target]
# Example: ./check-build-vs-cache.sh .#nixosConfigurations.jupiter.config.system.build.toplevel

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

TARGET="${1:-.#nixosConfigurations.jupiter.config.system.build.toplevel}"

echo -e "${BLUE}?? Analyzing Build vs Cache Substitution${NC}"
echo "=================================================="
echo ""
echo -e "Target: ${CYAN}$TARGET${NC}"
echo ""

# Get the derivation path
echo -e "${CYAN}?? Getting derivation path...${NC}"
DRV_PATH=$(nix eval --raw "$TARGET.drvPath" 2>&1 || echo "")

if [ -z "$DRV_PATH" ] || [[ "$DRV_PATH" == *"error"* ]]; then
  echo -e "${RED}? Could not get derivation path${NC}"
  echo "Trying alternative method..."

  # Alternative: try to realize the path
  echo -e "${CYAN}?? Realizing target to get store path...${NC}"
  STORE_PATH=$(nix build --no-link --print-out-paths "$TARGET" 2>&1 | tail -1 || echo "")

  if [ -z "$STORE_PATH" ]; then
    echo -e "${RED}? Could not realize target${NC}"
    echo ""
    echo "Trying to check specific Rust packages instead..."
    echo ""

    # Check specific Rust packages
    echo -e "${CYAN}Checking Rust toolchain packages...${NC}"
    echo ""

    for pkg in "rustc" "cargo" "rustfmt" "clippy" "rust-analyzer"; do
      echo -n "Checking $pkg... "
      if nix path-info --json "nixpkgs#$pkg" 2>/dev/null | jq -e '.[] | select(.substitutable == true)' > /dev/null 2>&1; then
        echo -e "${GREEN}? Substitutable${NC}"
      elif nix path-info --json "nixpkgs#$pkg" 2>/dev/null | jq -e '.[] | select(.substitutable == false)' > /dev/null 2>&1; then
        echo -e "${YELLOW}? Needs building${NC}"
      else
        echo -e "${RED}? Not found${NC}"
      fi
    done

    exit 0
  fi

  DRV_PATH=$(nix path-info --derivation "$STORE_PATH" 2>/dev/null || echo "")
fi

if [ -z "$DRV_PATH" ]; then
  echo -e "${RED}? Could not determine derivation path${NC}"
  exit 1
fi

echo -e "${GREEN}? Derivation: ${DRV_PATH}${NC}"
echo ""

# Get all closure paths
echo -e "${CYAN}?? Analyzing closure...${NC}"
TEMP_FILE=$(mktemp)
trap "rm -f '$TEMP_FILE'" EXIT

# Get all paths in closure with substitutability info
nix path-info --json -r "$DRV_PATH" > "$TEMP_FILE" 2>&1 || {
  echo -e "${YELLOW}? Could not get full closure info, trying store path method...${NC}"

  # Alternative: use nix-store
  if [ -n "${STORE_PATH:-}" ]; then
    nix-store --query --requisites "$STORE_PATH" > "$TEMP_FILE" 2>/dev/null || true
  fi
}

# Analyze the JSON if we got it
if jq -e . "$TEMP_FILE" > /dev/null 2>&1; then
  echo ""
  echo -e "${CYAN}?? Substitutability Analysis:${NC}"
  echo ""

  TOTAL=$(jq 'length' "$TEMP_FILE")
  SUBSTITUTABLE=$(jq '[.[] | select(.substitutable == true)] | length' "$TEMP_FILE")
  NEEDS_BUILD=$(jq '[.[] | select(.substitutable == false)] | length' "$TEMP_FILE")

  echo -e "  Total paths: ${CYAN}$TOTAL${NC}"
  echo -e "  ${GREEN}? Substitutable from cache: $SUBSTITUTABLE${NC}"
  echo -e "  ${YELLOW}? Needs building: $NEEDS_BUILD${NC}"

  if [ "$TOTAL" -gt 0 ]; then
    HIT_RATE=$(awk "BEGIN {printf \"%.1f\", ($SUBSTITUTABLE / $TOTAL) * 100}")
    echo -e "  Cache hit rate: ${CYAN}${HIT_RATE}%${NC}"
  fi

  echo ""
  echo -e "${CYAN}?? Packages that need building (first 20):${NC}"
  jq -r 'to_entries[] | select(.value.substitutable == false) | "  \(.key)"' "$TEMP_FILE" | head -20

  echo ""
  echo -e "${CYAN}?? Packages from cache (first 10):${NC}"
  jq -r 'to_entries[] | select(.value.substitutable == true) | "  \(.key)"' "$TEMP_FILE" | head -10

  # Check specifically for Rust packages
  echo ""
  echo -e "${CYAN}?? Rust-related packages:${NC}"
  jq -r 'to_entries[] | select(.key | contains("rust")) | "  \(if .value.substitutable then "?" else "?" end) \(.key)"' "$TEMP_FILE" | head -20

else
  echo -e "${YELLOW}? Could not parse JSON output${NC}"
  echo "Raw output (first 50 lines):"
  head -50 "$TEMP_FILE"
fi

echo ""
echo -e "${CYAN}?? Tip: Run with verbose build to see real-time substitution:${NC}"
echo "  nix build --print-build-logs $TARGET"
