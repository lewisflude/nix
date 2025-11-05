#!/usr/bin/env bash
# Test actual cache substitution by downloading a real package
# Usage: ./test-cache-substitution.sh [package-name]

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

PACKAGE="${1:-hello}"

echo -e "${BLUE}🧪 Testing Cache Substitution with Real Package${NC}"
echo "=================================================="
echo ""
echo -e "Package: ${CYAN}$PACKAGE${NC}"
echo ""

# Create a temporary directory for the test
TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR'" EXIT

echo -e "${CYAN}📥 Attempting to substitute package...${NC}"
echo ""

# Try to build the package and capture output
LOG_FILE="$TEMP_DIR/build.log"

if nix-build --no-out-link -E "with import <nixpkgs> {}; $PACKAGE" > "$LOG_FILE" 2>&1; then
  echo -e "${GREEN}✓ Package realization succeeded${NC}"
  echo ""

  # Check for cache hits
  if grep -qE "(copying|downloading).*from.*cache|substituter" "$LOG_FILE"; then
    echo -e "${GREEN}✅ Cache substitution detected!${NC}"
    echo ""
    echo -e "${CYAN}Cache hits found:${NC}"

    # Extract cache URLs used
    grep -oE "https://[^/]*\.(cachix\.org|cache\.nixos\.org|garnix\.io|thalheim\.io)" "$LOG_FILE" 2>/dev/null | sort -u | while read -r cache; do
      COUNT=$(grep -c "$cache" "$LOG_FILE" || echo "0")
      echo -e "  ${GREEN}✓${NC} $cache ($COUNT hits)"
    done

    # Show download sizes if available
    if grep -qE "downloaded.*from.*cache" "$LOG_FILE"; then
      echo ""
      echo -e "${CYAN}Download sizes:${NC}"
      grep -E "downloaded.*from.*cache" "$LOG_FILE" | head -5 | while read -r line; do
        echo "  $line"
      done
    fi
  else
    echo -e "${YELLOW}⚠ Package built from source (no cache substitution)${NC}"
    echo "This is normal if the package isn't in cache or cache is unavailable."
  fi
else
  echo -e "${RED}✗ Package realization failed${NC}"
  echo ""
  echo "Error output:"
  tail -20 "$LOG_FILE"
  exit 1
fi

echo ""
echo -e "${CYAN}📊 Build summary:${NC}"
BUILD_COUNT=$(grep -c "building.*derivation" "$LOG_FILE" || echo "0")
SUBST_COUNT=$(grep -cE "(copying|downloading).*from.*cache" "$LOG_FILE" || echo "0")

if [ "$BUILD_COUNT" -gt 0 ] || [ "$SUBST_COUNT" -gt 0 ]; then
  TOTAL=$((BUILD_COUNT + SUBST_COUNT))
  if [ "$TOTAL" -gt 0 ]; then
    HIT_RATE=$(awk "BEGIN {printf \"%.1f\", ($SUBST_COUNT / $TOTAL) * 100}")
    echo -e "  Built from source: ${YELLOW}$BUILD_COUNT${NC}"
    echo -e "  Substituted from cache: ${GREEN}$SUBST_COUNT${NC}"
    echo -e "  Cache hit rate: ${CYAN}${HIT_RATE}%${NC}"
  fi
fi
