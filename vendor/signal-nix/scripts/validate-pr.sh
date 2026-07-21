#!/usr/bin/env bash
# Signal-Nix PR Validation Script
# Run all validation checks before submitting a PR
#
# Usage:
#   ./scripts/validate-pr.sh
#   ./scripts/validate-pr.sh --fix   # Auto-fix formatting issues

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Counters
checks_passed=0
checks_failed=0
checks_total=0

# Parse arguments
FIX_MODE=false
if [ $# -gt 0 ] && [ "$1" == "--fix" ]; then
    FIX_MODE=true
fi

# Function to run a check
run_check() {
    local name="$1"
    local command="$2"

    checks_total=$((checks_total + 1))
    echo -e "${CYAN}[$checks_total]${NC} ${BOLD}$name${NC}"

    if eval "$command" > /dev/null 2>&1; then
        echo -e "    ${GREEN}✓ Passed${NC}"
        checks_passed=$((checks_passed + 1))
        return 0
    else
        echo -e "    ${RED}✗ Failed${NC}"
        checks_failed=$((checks_failed + 1))
        return 1
    fi
}

# Function to run a check with output
run_check_with_output() {
    local name="$1"
    local command="$2"

    checks_total=$((checks_total + 1))
    echo -e "${CYAN}[$checks_total]${NC} ${BOLD}$name${NC}"

    local output=$(eval "$command" 2>&1)
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo -e "    ${GREEN}✓ Passed${NC}"
        checks_passed=$((checks_passed + 1))
        return 0
    else
        echo -e "    ${RED}✗ Failed${NC}"
        echo "$output" | sed 's/^/    /'
        checks_failed=$((checks_failed + 1))
        return 1
    fi
}

# Header
echo ""
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}${BOLD}  Signal-Nix PR Validation Suite${NC}"
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if $FIX_MODE; then
    echo -e "${YELLOW}Fix mode enabled - will attempt to auto-fix issues${NC}"
    echo ""
fi

# 1. Check for hardcoded colors
echo -e "${BOLD}Color Validation${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
run_check_with_output "No hardcoded colors in modules" "./scripts/lint-colors.sh --all"
echo ""

# 2. Nix flake checks
echo -e "${BOLD}Nix Validation${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
run_check "Flake check (all validation tests)" "nix flake check --no-build"
run_check "Flake metadata valid" "nix flake metadata --json > /dev/null"
run_check "Flake lock file up to date" "nix flake lock --no-update-lock-file"
echo ""

# 3. Code formatting
echo -e "${BOLD}Code Formatting${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if $FIX_MODE; then
    echo -e "${CYAN}[4]${NC} ${BOLD}Format Nix files (nixfmt)${NC}"
    if nixfmt . 2>&1 | grep -q "formatted"; then
        echo -e "    ${GREEN}✓ Files formatted${NC}"
        checks_passed=$((checks_passed + 1))
    else
        echo -e "    ${GREEN}✓ No formatting needed${NC}"
        checks_passed=$((checks_passed + 1))
    fi
    checks_total=$((checks_total + 1))
else
    run_check "Nix files formatted (nixfmt)" "nixfmt --check ."
fi
echo ""

# 4. Linting
echo -e "${BOLD}Static Analysis${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v statix > /dev/null 2>&1; then
    run_check "Statix linter (Nix best practices)" "statix check ."
else
    echo -e "${CYAN}[5]${NC} ${BOLD}Statix linter (Nix best practices)${NC}"
    echo -e "    ${YELLOW}⊘ Skipped (statix not installed)${NC}"
fi
echo ""

# 5. Git checks
echo -e "${BOLD}Git Validation${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
run_check "No uncommitted changes (except untracked)" "[ -z \"\$(git diff --name-only)\" ]"
run_check "No untracked .nix files in modules/" "[ -z \"\$(git ls-files --others --exclude-standard modules/*.nix)\" ]"
echo ""

# 6. Documentation checks
echo -e "${BOLD}Documentation${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
run_check "README.md exists and not empty" "[ -s README.md ]"
run_check "QUICK_REFERENCE.md is up to date" "[ -s docs/QUICK_REFERENCE.md ]"
echo ""

# Summary
echo ""
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Validation Summary${NC}"
echo -e "${BLUE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Total checks:  ${CYAN}$checks_total${NC}"
echo -e "Passed:        ${GREEN}$checks_passed${NC}"
echo -e "Failed:        ${RED}$checks_failed${NC}"
echo ""

if [ $checks_failed -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ All validation checks passed!${NC}"
    echo ""
    echo "Your changes are ready to submit as a PR."
    echo ""
    echo -e "${BOLD}Next steps:${NC}"
    echo "  1. Review your changes: git diff"
    echo "  2. Commit if not already: git commit -am 'your message'"
    echo "  3. Push to your fork: git push origin your-branch"
    echo "  4. Create PR on GitHub"
    echo ""
    exit 0
else
    echo -e "${RED}${BOLD}✗ Some validation checks failed${NC}"
    echo ""
    echo "Please fix the issues above before submitting a PR."
    echo ""

    if ! $FIX_MODE; then
        echo -e "${BOLD}Tips:${NC}"
        echo "  - Run with --fix to auto-format code"
        echo "  - Use ./scripts/lint-colors.sh to find hardcoded colors"
        echo "  - Check individual modules with ./scripts/test-module.sh"
        echo ""
    fi

    exit 1
fi
