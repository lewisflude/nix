#!/usr/bin/env bash
# Diagnose Ironbar CSS Issues
# This script programmatically identifies visual issues in Ironbar

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Ironbar CSS Diagnostic Tool ===${NC}"
echo

# 1. Check for GTK CSS parser errors in logs
echo -e "${BLUE}[1] Checking GTK CSS Parser Errors from Logs${NC}"
if journalctl --user -u ironbar.service -n 200 --no-pager 2>/dev/null | grep -i "Theme parser error"; then
    echo -e "${YELLOW}Found CSS parser warnings/errors${NC}"
else
    echo -e "${GREEN}No CSS parser errors found in recent logs${NC}"
fi
echo

# 2. Validate ironbar config
echo -e "${BLUE}[2] Validating Ironbar Configuration${NC}"
if ironbar --validate-config -c ~/.config/ironbar/config.json -t ~/.config/ironbar/style.css 2>&1; then
    echo -e "${GREEN}Configuration validation passed${NC}"
else
    echo -e "${RED}Configuration validation failed${NC}"
fi
echo

# 3. Extract unsupported CSS properties from logs
echo -e "${BLUE}[3] Unsupported CSS Properties${NC}"
journalctl --user -u ironbar.service -n 500 --no-pager 2>/dev/null | \
    grep "No property named" | \
    awk -F'"' '{print $2}' | \
    sort -u | \
    while read -r prop; do
        echo -e "${YELLOW}  - $prop${NC}"
    done
echo

# 4. Check for common CSS antipatterns in the source
echo -e "${BLUE}[4] Checking for Common CSS Antipatterns${NC}"
CSS_FILE="$HOME/.config/nix/modules/shared/features/theming/applications/desktop/ironbar-home/css.nix"

if [ -f "$CSS_FILE" ]; then
    # Check for -webkit/-moz properties
    if grep -n "\-webkit-\|\-moz-" "$CSS_FILE" > /dev/null 2>&1; then
        echo -e "${YELLOW}Found browser-specific CSS prefixes (not supported in GTK):${NC}"
        grep -n "\-webkit-\|\-moz-" "$CSS_FILE" | head -10
    fi
    echo

    # Check for unsupported sizing properties on images
    if grep -n "max-width:\|max-height:\|^[[:space:]]*width:\|^[[:space:]]*height:" "$CSS_FILE" | \
       grep -B5 "image\|picture" > /dev/null 2>&1; then
        echo -e "${YELLOW}Found potentially unsupported sizing properties on images:${NC}"
        grep -n "max-width:\|max-height:\|width:\|height:" "$CSS_FILE" | head -10
    fi
else
    echo -e "${RED}CSS source file not found: $CSS_FILE${NC}"
fi
echo

# 5. Check for potential specificity conflicts
echo -e "${BLUE}[5] Checking for CSS Specificity Issues${NC}"
if [ -f "$CSS_FILE" ]; then
    # Look for duplicate selectors (potential conflicts)
    echo "Checking for duplicate class definitions..."
    grep -o '\.[a-zA-Z0-9_-]*' "$CSS_FILE" | \
        grep -v "^\.$" | \
        sort | uniq -d | head -10 | \
        while read -r selector; do
            count=$(grep -c "$selector" "$CSS_FILE" 2>/dev/null || echo "0")
            if [ "$count" -gt 5 ]; then
                echo -e "${YELLOW}  $selector appears $count times (may have conflicting rules)${NC}"
            fi
        done
fi
echo

# 6. Live inspector check
echo -e "${BLUE}[6] GTK Inspector Status${NC}"
if pgrep -f "ironbar" > /dev/null; then
    echo -e "${GREEN}Ironbar is running${NC}"
    echo "You can open GTK Inspector with: ironbar inspect"
    echo "This allows real-time CSS debugging and property inspection"
else
    echo -e "${YELLOW}Ironbar is not running${NC}"
fi
echo

# 7. Summary of known issues from recent fixes
echo -e "${BLUE}[7] Known Visual Issues (from git history)${NC}"
cd ~/.config/nix
git log -1 --stat modules/shared/features/theming/applications/desktop/ironbar-home/css.nix 2>/dev/null | \
    grep "FIX" || echo "No recent FIX comments in latest commit"
echo

echo -e "${BLUE}=== Diagnostic Complete ===${NC}"
echo
echo -e "${BLUE}Suggested Actions:${NC}"
echo "1. Review CSS parser errors above"
echo "2. Remove unsupported properties (-webkit, -moz, width/height on images)"
echo "3. Use 'ironbar inspect' to debug visual issues in real-time"
echo "4. Check for specificity conflicts in repeated selectors"
echo "5. Test changes with 'ironbar reload' for live updates"
