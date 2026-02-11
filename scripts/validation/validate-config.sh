#!/usr/bin/env bash
# Configuration validation script for dendritic pattern
# Checks for common antipatterns and validates structure

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error_count=0
warning_count=0

echo "Validating Nix configuration (dendritic pattern)..."
echo

# Check 1: 'with pkgs;' usage (antipattern)
echo "Checking for 'with pkgs;' usage..."
with_pkgs_count=$(grep -r "with pkgs;" modules/ 2>/dev/null | wc -l || echo "0")
if [ "$with_pkgs_count" -gt 10 ]; then
  echo -e "${YELLOW}WARNING: Found $with_pkgs_count uses of 'with pkgs;'${NC}"
  echo "   Use explicit pkgs.packageName instead"
  ((warning_count++))
else
  echo -e "${GREEN}OK${NC} 'with pkgs;' usage: $with_pkgs_count"
fi

# Check 2: Direct imports of lib/constants.nix (antipattern)
echo "Checking for direct constants imports..."
if grep -r "import.*lib/constants" modules/ hosts/ 2>/dev/null | grep -v "^Binary"; then
  echo -e "${RED}ERROR: Direct import of lib/constants.nix found${NC}"
  echo "   Use config.constants instead"
  ((error_count++))
else
  echo -e "${GREEN}OK${NC} No direct constants imports"
fi

# Check 3: specialArgs usage (antipattern in dendritic)
echo "Checking for specialArgs usage..."
if grep -r "specialArgs\|extraSpecialArgs" modules/ 2>/dev/null | grep -v "^Binary"; then
  echo -e "${RED}ERROR: specialArgs/extraSpecialArgs found${NC}"
  echo "   Use config.* options instead (dendritic pattern)"
  ((error_count++))
else
  echo -e "${GREEN}OK${NC} No specialArgs usage"
fi

# Check 4: Validate flake structure
echo "Checking flake structure..."
if command -v nix &>/dev/null; then
  if nix flake metadata --no-write-lock-file &>/dev/null; then
    echo -e "${GREEN}OK${NC} Flake structure is valid"
  else
    echo -e "${RED}ERROR: Invalid flake structure${NC}"
    ((error_count++))
  fi
else
  echo -e "${YELLOW}INFO: nix command not available, skipping flake validation${NC}"
fi

# Check 5: Required files exist
echo "Checking required infrastructure files..."
required_files=(
  "modules/constants.nix"
  "modules/meta.nix"
  "lib/functions.nix"
  "DENDRITIC_SOURCE_OF_TRUTH.md"
)

for file in "${required_files[@]}"; do
  if [ -f "$file" ]; then
    echo -e "${GREEN}OK${NC} $file exists"
  else
    echo -e "${RED}ERROR: Missing $file${NC}"
    ((error_count++))
  fi
done

# Check 6: Modules are flake-parts modules
echo "Checking module structure..."
non_flake_parts=0
for file in modules/*.nix; do
  if [ -f "$file" ]; then
    # Check if file has flake-parts structure (contains flake. or options. or perSystem)
    if ! grep -q "flake\.\|options\.\|perSystem" "$file" 2>/dev/null; then
      echo -e "${YELLOW}WARNING: $file may not be a flake-parts module${NC}"
      ((non_flake_parts++))
    fi
  fi
done
if [ "$non_flake_parts" -eq 0 ]; then
  echo -e "${GREEN}OK${NC} All modules appear to be flake-parts modules"
fi

# Summary
echo
echo "Validation Summary"
echo "=================="
if [ $error_count -eq 0 ] && [ $warning_count -eq 0 ]; then
  echo -e "${GREEN}All checks passed!${NC}"
  exit 0
elif [ $error_count -eq 0 ]; then
  echo -e "${YELLOW}$warning_count warnings found${NC}"
  echo "Configuration is valid but could be improved"
  exit 0
else
  echo -e "${RED}$error_count errors found${NC}"
  if [ $warning_count -gt 0 ]; then
    echo -e "${YELLOW}$warning_count warnings found${NC}"
  fi
  echo
  echo "Please fix errors before proceeding"
  exit 1
fi
