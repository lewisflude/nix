#!/usr/bin/env bash
# Check what will be built vs cached for a NixOS system
# Usage: ./check-what-builds.sh [hostname]
# Example: ./check-what-builds.sh jupiter

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

HOST="${1:-jupiter}"
TARGET=".#nixosConfigurations.${HOST}.config.system.build.toplevel"

echo -e "${BLUE}?? Checking What Will Build vs Cache${NC}"
echo "=================================================="
echo ""
echo -e "Target: ${CYAN}$TARGET${NC}"
echo ""

# Method 1: Use nix build --dry-run with --print-build-logs
echo -e "${CYAN}Method 1: Dry-run build analysis${NC}"
echo ""

TEMP_LOG=$(mktemp)
trap "rm -f '$TEMP_LOG'" EXIT

echo "Running dry-run build (this may take a moment)..."
nix build --dry-run --print-build-logs "$TARGET" > "$TEMP_LOG" 2>&1 || true

# Count different types of operations
BUILDING=$(grep -c "will be built" "$TEMP_LOG" || echo "0")
DOWNLOADING=$(grep -cE "(copying|downloading|substituting)" "$TEMP_LOG" || echo "0")
QUERYING=$(grep -c "querying" "$TEMP_LOG" || echo "0")

echo ""
echo -e "${CYAN}?? Summary:${NC}"
echo -e "  ${YELLOW}Will build:${NC} $BUILDING"
echo -e "  ${GREEN}Will download:${NC} $DOWNLOADING"
echo -e "  ${CYAN}Querying caches:${NC} $QUERYING"

# Show what will be built
if [ "$BUILDING" -gt 0 ]; then
  echo ""
  echo -e "${YELLOW}?? Packages that will be built (first 20):${NC}"
  grep "will be built" "$TEMP_LOG" | head -20 | sed 's/^/  /'
fi

# Show Rust-related builds
echo ""
echo -e "${CYAN}?? Rust-related packages:${NC}"
grep -i "rust.*will be built" "$TEMP_LOG" | head -20 | sed 's/^/  /' || echo "  (none found in first pass)"

echo ""
echo ""

# Method 2: Check specific Rust packages
echo -e "${CYAN}Method 2: Checking specific Rust toolchain packages${NC}"
echo ""

# Check if fenix is available
echo "Checking fenix packages..."
if nix eval --raw "$TARGET" --apply 'x: x.pkgs.fenix.stable.toolchain or null' 2>/dev/null | grep -q "fenix"; then
  echo -e "  ${GREEN}? fenix available${NC}"

  # Try to check if it's substitutable
  FENIX_PATH=$(nix eval --raw "$TARGET" --apply 'x: x.pkgs.fenix.stable.toolchain.outPath' 2>/dev/null || echo "")
  if [ -n "$FENIX_PATH" ]; then
    echo "  Checking substitutability of fenix toolchain..."
    if nix path-info --json "$FENIX_PATH" 2>/dev/null | jq -e '.[] | select(.substitutable == true)' > /dev/null 2>&1; then
      echo -e "    ${GREEN}? fenix toolchain is substitutable (from cache)${NC}"
    else
      echo -e "    ${YELLOW}? fenix toolchain needs building${NC}"
    fi
  fi
# Also check for rust-overlay (legacy)
elif nix eval --raw "$TARGET" --apply 'x: x.pkgs.rust-bin.stable.latest.default or null' 2>/dev/null | grep -q "rust-bin"; then
  echo -e "  ${YELLOW}? rust-bin available from rust-overlay (legacy)${NC}"
else
  echo -e "  ${YELLOW}? fenix not found (may not be using fenix)${NC}"
fi

# Check nixpkgs Rust packages
echo ""
echo "Checking nixpkgs Rust packages..."
for pkg in "rustc" "cargo" "rustfmt" "clippy" "rust-analyzer"; do
  echo -n "  $pkg: "
  if nix eval --raw "nixpkgs#$pkg.outPath" 2>/dev/null > /dev/null; then
    PKG_PATH=$(nix eval --raw "nixpkgs#$pkg.outPath" 2>/dev/null)
    if nix path-info --json "$PKG_PATH" 2>/dev/null | jq -e '.[] | select(.substitutable == true)' > /dev/null 2>&1; then
      echo -e "${GREEN}? substitutable${NC}"
    else
      echo -e "${YELLOW}? needs building${NC}"
    fi
  else
    echo -e "${RED}? not found${NC}"
  fi
done

echo ""
echo -e "${CYAN}?? To see real-time build progress:${NC}"
echo "  nix build --print-build-logs $TARGET"
echo ""
echo -e "${CYAN}?? To see detailed cache queries:${NC}"
echo "  nix build --print-build-logs -L $TARGET 2>&1 | grep -E '(substituting|building|downloading)'"
