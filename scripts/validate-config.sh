#!/usr/bin/env bash
# Configuration validation script
# Checks for common antipatterns and boundary violations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error_count=0
warning_count=0

echo "🔍 Validating Nix configuration..."
echo

# Check 1: Podman in home-manager
echo "Checking for podman in home-manager..."
if grep -r "home.packages.*podman" home/ 2>/dev/null | grep -v "podman-desktop"; then
  echo -e "${RED}❌ ERROR: Podman found in home-manager${NC}"
  echo "   Container runtimes should be at system-level only"
  ((error_count++))
else
  echo -e "${GREEN}✓${NC} No podman in home-manager"
fi

# Check 2: Graphics packages duplicated in home
echo "Checking for duplicate graphics packages..."
if grep -r "vulkan-tools\|mesa-demos" home/ 2>/dev/null; then
  echo -e "${YELLOW}⚠ WARNING: Graphics tools found in home-manager${NC}"
  echo "   These are likely already in system config"
  ((warning_count++))
else
  echo -e "${GREEN}✓${NC} No duplicate graphics packages"
fi

# Check 3: Hardcoded timezones
echo "Checking for hardcoded timezones..."
if grep -r "time.timeZone\s*=" modules/nixos/features/ modules/shared/features/ 2>/dev/null; then
  echo -e "${YELLOW}⚠ WARNING: Hardcoded timezone found in feature modules${NC}"
  echo "   Timezones should be per-host or use constants"
  ((warning_count++))
else
  echo -e "${GREEN}✓${NC} No hardcoded timezones in feature modules"
fi

# Check 4: 'with pkgs;' usage (informational)
echo "Checking for 'with pkgs;' usage..."
with_pkgs_count=$(grep -r "with pkgs;" home/ modules/ 2>/dev/null | wc -l || echo "0")
if [ "$with_pkgs_count" -gt 50 ]; then
  echo -e "${YELLOW}⚠ INFO: Found $with_pkgs_count uses of 'with pkgs;'${NC}"
  echo "   Consider migrating to explicit pkgs.packageName"
else
  echo -e "${GREEN}✓${NC} 'with pkgs;' usage: $with_pkgs_count (acceptable)"
fi

# Check 5: Docker in home-manager (informational - can be legitimate for CLI)
echo "Checking for docker in home-manager..."
if grep -r "home.packages.*docker" home/ 2>/dev/null | grep -v "docker-client" | grep -v "docker-compose"; then
  echo -e "${YELLOW}⚠ INFO: Docker found in home-manager${NC}"
  echo "   Ensure this is docker-client, not docker daemon"
  ((warning_count++))
else
  echo -e "${GREEN}✓${NC} No problematic docker packages"
fi

# Check 6: Validate flake structure
echo "Checking flake structure..."
if command -v nix &> /dev/null; then
  if nix flake metadata --no-write-lock-file &> /dev/null; then
    echo -e "${GREEN}✓${NC} Flake structure is valid"
  else
    echo -e "${RED}❌ ERROR: Invalid flake structure${NC}"
    ((error_count++))
  fi
else
  echo -e "${YELLOW}⚠ INFO: nix command not available, skipping flake validation${NC}"
fi

# Check 7: Required files exist
echo "Checking required infrastructure files..."
required_files=(
  "lib/constants.nix"
  "lib/validators.nix"
  "lib/functions.nix"
  "docs/CODE_REVIEW_REMEDIATION.md"
)

for file in "${required_files[@]}"; do
  if [ -f "$file" ]; then
    echo -e "${GREEN}✓${NC} $file exists"
  else
    echo -e "${RED}❌ ERROR: Missing $file${NC}"
    ((error_count++))
  fi
done

# Summary
echo
echo "═══════════════════════════════════════"
echo "Validation Summary"
echo "═══════════════════════════════════════"
if [ $error_count -eq 0 ] && [ $warning_count -eq 0 ]; then
  echo -e "${GREEN}✅ All checks passed!${NC}"
  exit 0
elif [ $error_count -eq 0 ]; then
  echo -e "${YELLOW}⚠ $warning_count warnings found${NC}"
  echo "Configuration is valid but could be improved"
  exit 0
else
  echo -e "${RED}❌ $error_count errors found${NC}"
  if [ $warning_count -gt 0 ]; then
    echo -e "${YELLOW}⚠ $warning_count warnings found${NC}"
  fi
  echo
  echo "Please fix errors before proceeding"
  exit 1
fi
