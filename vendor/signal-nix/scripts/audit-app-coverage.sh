#!/usr/bin/env bash
# Signal Theme Ecosystem: Application Coverage Audit Script
# Finds discrepancies between documentation and actual module files

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directories
MODULES_DIR="modules"
README="README.md"
THEMING_REF="docs/theming-reference.md"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Signal Theme Ecosystem: Application Coverage Audit${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Find all module files
echo -e "${BLUE}📂 Scanning modules directory...${NC}"
ACTUAL_MODULES=$(find "$MODULES_DIR" -type f -name "*.nix" \
  ! -path "*/common/*" \
  ! -path "*/nixos/common/*" \
  ! -name "tokens.nix" \
  ! -name "default.nix" \
  | sort)

MODULE_COUNT=$(echo "$ACTUAL_MODULES" | wc -l | tr -d ' ')
echo -e "${GREEN}   Found ${MODULE_COUNT} module files${NC}"
echo ""

# Extract application names from modules
echo -e "${BLUE}🔍 Extracting application names from modules...${NC}"
declare -A MODULE_MAP
while IFS= read -r module_path; do
  # Get just the filename without extension
  app_name=$(basename "$module_path" .nix)
  # Get the category from the path
  category=$(dirname "$module_path" | sed "s|$MODULES_DIR/||")
  MODULE_MAP["$app_name"]="$category"
  echo -e "   ${GREEN}✓${NC} $app_name ($category)"
done <<< "$ACTUAL_MODULES"
echo ""

# Check README claims
echo -e "${BLUE}📄 Analyzing README.md claims...${NC}"
README_APPS=$(grep -E "^- \*\*[A-Za-z0-9/-]+\*\*" "$README" | \
  sed -E 's/^- \*\*([A-Za-z0-9/-]+)\*\*.*/\1/' | \
  sort -u)

README_COUNT=$(echo "$README_APPS" | wc -l | tr -d ' ')
echo -e "${GREEN}   Found ${README_COUNT} applications mentioned${NC}"
echo ""

# Find discrepancies
echo -e "${BLUE}🔍 Finding discrepancies...${NC}"
echo ""

# Apps in README but not in modules
echo -e "${YELLOW}📋 Applications claimed in README but MISSING modules:${NC}"
MISSING_COUNT=0
while IFS= read -r app; do
  app_lower=$(echo "$app" | tr '[:upper:]' '[:lower:]' | tr -d ' -')
  
  # Check if module exists with various naming patterns
  found=false
  for module_name in "${!MODULE_MAP[@]}"; do
    module_lower=$(echo "$module_name" | tr '[:upper:]' '[:lower:]' | tr -d ' -')
    if [[ "$module_lower" == "$app_lower" ]]; then
      found=true
      break
    fi
  done
  
  if [[ "$found" == "false" ]]; then
    echo -e "   ${RED}✗${NC} $app"
    ((MISSING_COUNT++))
  fi
done <<< "$README_APPS"

if [[ $MISSING_COUNT -eq 0 ]]; then
  echo -e "   ${GREEN}✓ None - all README apps have modules!${NC}"
fi
echo ""

# Apps in modules but not in README
echo -e "${YELLOW}📋 Modules that exist but NOT mentioned in README:${NC}"
UNDOCUMENTED_COUNT=0
for module_name in "${!MODULE_MAP[@]}"; do
  module_lower=$(echo "$module_name" | tr '[:upper:]' '[:lower:]' | tr -d ' -')
  
  found=false
  while IFS= read -r readme_app; do
    readme_lower=$(echo "$readme_app" | tr '[:upper:]' '[:lower:]' | tr -d ' -')
    if [[ "$module_lower" == "$readme_lower" ]]; then
      found=true
      break
    fi
  done <<< "$README_APPS"
  
  if [[ "$found" == "false" ]]; then
    category="${MODULE_MAP[$module_name]}"
    echo -e "   ${YELLOW}⚠${NC}  $module_name ($category)"
    ((UNDOCUMENTED_COUNT++))
  fi
done

if [[ $UNDOCUMENTED_COUNT -eq 0 ]]; then
  echo -e "   ${GREEN}✓ None - all modules are documented!${NC}"
fi
echo ""

# Check theming-reference.md status markers
echo -e "${BLUE}🎨 Checking theming-reference.md status accuracy...${NC}"
if [[ -f "$THEMING_REF" ]]; then
  echo ""
  echo -e "${YELLOW}📋 Apps marked 🔴 'Not implemented' but have modules:${NC}"
  
  NOT_IMPL_COUNT=0
  # Extract app names marked as not implemented (🔴)
  grep -B2 "Status.*Not implemented\|🔴" "$THEMING_REF" | \
    grep "^###" | \
    sed -E 's/### [🔴🟢]+ //' | \
    sort -u | while IFS= read -r app; do
    
    app_lower=$(echo "$app" | tr '[:upper:]' '[:lower:]' | tr -d ' -')
    
    # Check if module exists
    for module_name in "${!MODULE_MAP[@]}"; do
      module_lower=$(echo "$module_name" | tr '[:upper:]' '[:lower:]' | tr -d ' -')
      if [[ "$module_lower" == "$app_lower" ]]; then
        category="${MODULE_MAP[$module_name]}"
        echo -e "   ${RED}✗${NC} $app (module exists: $module_name in $category)"
        ((NOT_IMPL_COUNT++))
        break
      fi
    done
  done
  
  if [[ $NOT_IMPL_COUNT -eq 0 ]]; then
    echo -e "   ${GREEN}✓ All 'not implemented' markers are accurate!${NC}"
  fi
else
  echo -e "   ${RED}✗ theming-reference.md not found${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "   ${GREEN}Actual modules:${NC} $MODULE_COUNT"
echo -e "   ${GREEN}README claims:${NC} $README_COUNT"
echo -e "   ${RED}Missing modules:${NC} $MISSING_COUNT"
echo -e "   ${YELLOW}Undocumented modules:${NC} $UNDOCUMENTED_COUNT"
if [[ -f "$THEMING_REF" ]]; then
  echo -e "   ${RED}Status conflicts:${NC} Check output above"
fi
echo ""

# Calculate accuracy score
TOTAL_ISSUES=$((MISSING_COUNT + UNDOCUMENTED_COUNT))
if [[ $TOTAL_ISSUES -eq 0 ]]; then
  echo -e "${GREEN}🎉 Perfect documentation accuracy! No discrepancies found.${NC}"
  exit 0
else
  ACCURACY=$(echo "scale=1; (1 - $TOTAL_ISSUES / $MODULE_COUNT) * 100" | bc)
  echo -e "${YELLOW}📊 Documentation accuracy: ${ACCURACY}%${NC}"
  echo -e "${YELLOW}⚠️  Found $TOTAL_ISSUES issues that need attention${NC}"
  exit 1
fi
