#!/usr/bin/env bash
# Test Cachix and FlakeHub cache connectivity
# Usage: ./test-caches.sh

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

echo -e "${BLUE}🧪 Testing Binary Cache Connectivity${NC}"
echo "=========================================="
echo ""

# Get configured substituters from nix show-config
echo -e "${CYAN}📋 Configured Substituters:${NC}"
SUBSTITUTERS=$(nix show-config 2>/dev/null | grep "^substituters" | cut -d'=' -f2- | tr ' ' '\n' | grep -v '^$' || echo "")
TRUSTED=$(nix show-config 2>/dev/null | grep "^trusted-substituters" | cut -d'=' -f2- | tr ' ' '\n' | grep -v '^$' || echo "")

# Also extract caches from flake.nix (if it exists)
FLAKE_CACHES=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Try to find flake.nix relative to script location or workspace root
FLAKE_NIX="${SCRIPT_DIR}/../../flake.nix"
if [ ! -f "$FLAKE_NIX" ]; then
  # Try workspace root (if script is in a subdirectory)
  FLAKE_NIX="${SCRIPT_DIR}/../../../flake.nix"
fi
if [ -f "$FLAKE_NIX" ]; then
  # Extract URLs from extra-substituters array in flake.nix
  # This handles both quoted and unquoted URLs, and stops at the closing bracket
  FLAKE_CACHES=$(awk '/extra-substituters\s*=\s*\[/ {
    in_array=1
    next
  }
  in_array {
    # Extract https:// URLs (handles both "https://..." and https://...)
    gsub(/[" ]/, "", $0)
    if (match($0, /https:\/\/[^ ]+/, m)) {
      print m[0]
    }
    # Stop at closing bracket
    if (/\];/) {
      in_array=0
    }
  }' "$FLAKE_NIX" 2>/dev/null | grep -v '^$' || echo "")
fi

# Combine all caches and remove duplicates
ALL_CACHES=$(echo -e "$SUBSTITUTERS\n$TRUSTED\n$FLAKE_CACHES" | sort -u | grep -v '^$')

if [ -z "$ALL_CACHES" ]; then
  echo -e "${RED}❌ No substituters configured${NC}"
  exit 1
fi

echo "$ALL_CACHES" | while read -r cache; do
  echo "  • $cache"
done
echo ""

# Test each cache
echo -e "${CYAN}🔍 Testing Cache Connectivity...${NC}"
echo ""

WORKING=0
FAILED=0
FAILED_CACHES=()

# Test HTTP connectivity to each cache
for cache in $ALL_CACHES; do
  # Extract hostname from URL
  HOST=$(echo "$cache" | sed 's|https\?://||' | cut -d'/' -f1)

  echo -n "Testing $cache ... "

  # Test basic connectivity (HEAD request to root)
  if curl -sSf --max-time 5 --head "$cache" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Working${NC}"
    WORKING=$((WORKING + 1))
  else
    echo -e "${RED}✗ Failed${NC}"
    FAILED=$((FAILED + 1))
    FAILED_CACHES+=("$cache")
  fi
done

echo ""
echo -e "${CYAN}📊 Results:${NC}"
echo -e "  ${GREEN}Working:${NC} $WORKING"
echo -e "  ${RED}Failed:${NC} $FAILED"
echo ""

# Test actual substitution with a common package
echo -e "${CYAN}🧪 Testing Actual Package Substitution...${NC}"
echo ""

# Try to build/download a simple package that should be in cache
TEST_PACKAGE="nix"
echo -e "Testing substitution with package: ${CYAN}$TEST_PACKAGE${NC}"

# Try to realize a path that should be in cache
if nix-build --no-out-link -E "with import <nixpkgs> {}; $TEST_PACKAGE" 2>&1 | grep -qE "(copying|downloading).*from.*cache"; then
  echo -e "${GREEN}✓ Package substitution working${NC}"

  # Show which cache was used
  CACHE_USED=$(nix-build --no-out-link -E "with import <nixpkgs> {}; $TEST_PACKAGE" 2>&1 | grep -oE "https://[^/]*\.(cachix\.org|cache\.nixos\.org|garnix\.io)" | head -1 || echo "")
  if [ -n "$CACHE_USED" ]; then
    echo -e "  Cache used: ${CYAN}$CACHE_USED${NC}"
  fi
else
  echo -e "${YELLOW}⚠ Package substitution test inconclusive (may need to build from source)${NC}"
fi

echo ""

# Test Cachix specifically
echo -e "${CYAN}🎯 Testing Cachix Access...${NC}"
if command -v cachix &> /dev/null; then
  CACHIX_VERSION=$(cachix --version 2>/dev/null || echo "unknown")
  echo -e "  Cachix CLI: ${GREEN}installed${NC} (version: $CACHIX_VERSION)"

  # Test personal cache if configured
  if echo "$ALL_CACHES" | grep -q "lewisflude.cachix.org"; then
    echo -n "  Testing personal cache (lewisflude.cachix.org) ... "
    if curl -sSf --max-time 5 "https://lewisflude.cachix.org" > /dev/null 2>&1; then
      echo -e "${GREEN}✓ Accessible${NC}"
    else
      echo -e "${RED}✗ Not accessible${NC}"
    fi
  fi
else
  echo -e "  Cachix CLI: ${YELLOW}not installed${NC}"
fi

echo ""

# Test FlakeHub (note: FlakeHub uses API, not binary cache)
echo -e "${CYAN}🌐 Testing FlakeHub API...${NC}"
if echo "$ALL_CACHES" | grep -q "cache.flakehub.com"; then
  echo -n "  Testing FlakeHub cache ... "
  if curl -sSf --max-time 5 "https://cache.flakehub.com" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Accessible${NC}"
  else
    echo -e "${RED}✗ Not accessible${NC}"
  fi
else
  echo -e "  ${YELLOW}Note:${NC} FlakeHub uses API for flakes, not binary cache"
  echo -n "  Testing FlakeHub API ... "
  if curl -sSf --max-time 5 "https://api.flakehub.com" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Accessible${NC}"
  else
    echo -e "${RED}✗ Not accessible${NC}"
  fi
fi

echo ""

# Summary
if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}✅ All caches are accessible!${NC}"
  exit 0
elif [ $FAILED -lt $((WORKING + FAILED)) ]; then
  echo -e "${YELLOW}⚠️  Some caches failed, but others are working${NC}"
  if [ ${#FAILED_CACHES[@]} -gt 0 ]; then
    echo -e "${YELLOW}Failed caches:${NC}"
    for cache in "${FAILED_CACHES[@]}"; do
      echo "  • $cache"
    done
  fi
  exit 0
else
  echo -e "${RED}❌ All caches failed! Check your network connection.${NC}"
  exit 1
fi
