#!/usr/bin/env bash
# Monitor cache hits during Nix builds
# Usage: ./monitor-cache-hits.sh [build-command]
# Example: ./monitor-cache-hits.sh "nix build .#nixosConfigurations.jupiter"

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

BUILD_CMD="${1:-nix build .#nixosConfigurations.jupiter.config.system.build.toplevel}"

echo -e "${BLUE}📊 Monitoring Cache Hits${NC}"
echo -e "${CYAN}Build command:${NC} $BUILD_CMD"
echo ""

# Counters
CACHE_HITS=0
CACHE_MISSES=0
BUILDING=0
TOTAL_DOWNLOADED=0

# Create temporary files for parsing
TEMP_LOG=$(mktemp)
trap "rm -f '$TEMP_LOG'" EXIT

echo -e "${CYAN}Starting build and monitoring...${NC}"
echo ""

# Run build and capture output
eval "$BUILD_CMD" 2>&1 | tee "$TEMP_LOG" | while IFS= read -r line; do
  # Check for cache hits (downloading from cache)
  if echo "$line" | grep -qE "(copying|downloading).*from.*cachix|substituter|cache"; then
    CACHE_HITS=$((CACHE_HITS + 1))
    echo -e "${GREEN}✓ Cache hit:${NC} $line"
  # Check for building from source
  elif echo "$line" | grep -qE "building.*derivation|building.*path"; then
    BUILDING=$((BUILDING + 1))
    echo -e "${YELLOW}⚠ Building:${NC} $line"
  # Check for cache misses (querying but not found)
  elif echo "$line" | grep -qE "querying|checking.*cache"; then
    # This is just a query, not necessarily a miss
    :
  fi
done

echo ""
echo -e "${BLUE}📈 Summary${NC}"
echo ""

# Analyze the log file
CACHE_HITS=$(grep -cE "(copying|downloading).*from.*cachix|substituter.*cache" "$TEMP_LOG" || echo "0")
BUILDING=$(grep -cE "building.*derivation|building.*path" "$TEMP_LOG" || echo "0")
DOWNLOADED=$(grep -E "downloaded.*from.*cachix" "$TEMP_LOG" | awk '{sum+=$2} END {print sum}' || echo "0")

echo -e "${GREEN}Cache hits (downloaded):${NC} $CACHE_HITS"
echo -e "${YELLOW}Building from source:${NC} $BUILDING"

if [[ $CACHE_HITS -gt 0 ]] || [[ $BUILDING -gt 0 ]]; then
  TOTAL=$((CACHE_HITS + BUILDING))
  if [[ $TOTAL -gt 0 ]]; then
    HIT_RATE=$(awk "BEGIN {printf \"%.1f\", ($CACHE_HITS / $TOTAL) * 100}")
    echo -e "${CYAN}Cache hit rate:${NC} ${HIT_RATE}%"
  fi
fi

echo ""
echo -e "${CYAN}Cache servers used:${NC}"
grep -oE "https://[^/]*\.cachix\.org" "$TEMP_LOG" 2>/dev/null | sort -u | while read -r cache; do
  COUNT=$(grep -c "$cache" "$TEMP_LOG" || echo "0")
  echo "  $cache: $COUNT hits"
done

echo ""
echo -e "${CYAN}Top 10 largest downloads:${NC}"
grep -E "downloaded.*from.*cachix" "$TEMP_LOG" 2>/dev/null | \
  awk '{print $2, $0}' | \
  sort -rn | \
  head -10 | \
  awk '{print "  " $2 " " $3 " " $4 " " $5}'
