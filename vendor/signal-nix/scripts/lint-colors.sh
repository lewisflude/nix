#!/usr/bin/env bash
# Signal-Nix Color Linter
# Checks for hardcoded colors in uncommitted changes
#
# Usage:
#   ./scripts/lint-colors.sh              # Check staged changes
#   ./scripts/lint-colors.sh --all        # Check all files
#   ./scripts/lint-colors.sh file.nix     # Check specific file

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Patterns to detect
HEX_PATTERN='#[0-9a-fA-F]{6}'
OKLCH_PATTERN='oklch\([0-9.]+ [0-9.]+ [0-9.]+\)'
RGB_PATTERN='rgb\([0-9]+,\s*[0-9]+,\s*[0-9]+\)'
RGBA_PATTERN='rgba\([0-9]+,\s*[0-9]+,\s*[0-9]+,\s*[0-9.]+\)'

# Counter for issues found
issues_found=0

# Function to check a file for hardcoded colors
check_file() {
    local file="$1"
    local found_in_file=0

    # Skip non-.nix files
    if [[ ! "$file" =~ \.nix$ ]]; then
        return 0
    fi

    # Skip files in certain directories
    if [[ "$file" =~ ^(tests/|examples/|docs/) ]]; then
        return 0
    fi

    # Check for hex colors
    if grep -nE "$HEX_PATTERN" "$file" > /dev/null 2>&1; then
        if [ $found_in_file -eq 0 ]; then
            echo -e "${RED}✗${NC} $file"
            found_in_file=1
        fi
        echo -e "  ${YELLOW}Hex colors:${NC}"
        grep -nE "$HEX_PATTERN" "$file" | sed 's/^/    /'
        issues_found=$((issues_found + 1))
    fi

    # Check for oklch colors
    if grep -nE "$OKLCH_PATTERN" "$file" > /dev/null 2>&1; then
        if [ $found_in_file -eq 0 ]; then
            echo -e "${RED}✗${NC} $file"
            found_in_file=1
        fi
        echo -e "  ${YELLOW}OKLCH colors:${NC}"
        grep -nE "$OKLCH_PATTERN" "$file" | sed 's/^/    /'
        issues_found=$((issues_found + 1))
    fi

    # Check for rgb/rgba colors
    if grep -nE "$RGB_PATTERN|$RGBA_PATTERN" "$file" > /dev/null 2>&1; then
        if [ $found_in_file -eq 0 ]; then
            echo -e "${RED}✗${NC} $file"
            found_in_file=1
        fi
        echo -e "  ${YELLOW}RGB/RGBA colors:${NC}"
        grep -nE "$RGB_PATTERN|$RGBA_PATTERN" "$file" | sed 's/^/    /'
        issues_found=$((issues_found + 1))
    fi

    if [ $found_in_file -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $file"
    fi
}

# Main logic
main() {
    echo -e "${BLUE}Signal-Nix Color Linter${NC}"
    echo "Checking for hardcoded colors..."
    echo ""

    if [ $# -eq 0 ]; then
        # Check staged files by default
        echo "Mode: Checking staged files (use --all to check everything)"
        echo ""

        staged_files=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || echo "")

        if [ -z "$staged_files" ]; then
            echo -e "${YELLOW}No staged files found. Staging all changes...${NC}"
            # Check working directory changes instead
            changed_files=$(git diff --name-only --diff-filter=ACM 2>/dev/null || echo "")

            if [ -z "$changed_files" ]; then
                echo -e "${GREEN}No modified files to check.${NC}"
                exit 0
            fi

            for file in $changed_files; do
                if [ -f "$file" ]; then
                    check_file "$file"
                fi
            done
        else
            for file in $staged_files; do
                if [ -f "$file" ]; then
                    check_file "$file"
                fi
            done
        fi
    elif [ "$1" == "--all" ]; then
        # Check all module files
        echo "Mode: Checking all module files"
        echo ""

        find modules/ -name "*.nix" -type f | while read -r file; do
            check_file "$file"
        done
    else
        # Check specific files
        echo "Mode: Checking specified files"
        echo ""

        for file in "$@"; do
            if [ -f "$file" ]; then
                check_file "$file"
            else
                echo -e "${RED}✗${NC} File not found: $file"
                issues_found=$((issues_found + 1))
            fi
        done
    fi

    echo ""
    if [ $issues_found -eq 0 ]; then
        echo -e "${GREEN}✓ No hardcoded colors found!${NC}"
        echo ""
        echo "All modules use the semantic bridge correctly."
        exit 0
    else
        echo -e "${RED}✗ Found $issues_found file(s) with hardcoded colors${NC}"
        echo ""
        echo "Fix these issues by using the semantic bridge:"
        echo ""
        echo "  ❌ DON'T: background = \"#1a1b1e\";"
        echo "  ✅ DO:    background = semantic.core \"background\" mode;"
        echo ""
        echo "See docs/QUICK_REFERENCE.md for all available semantic colors."
        exit 1
    fi
}

main "$@"
