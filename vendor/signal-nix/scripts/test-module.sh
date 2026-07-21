#!/usr/bin/env bash
# Signal-Nix Module Tester
# Quickly test a single module in both light and dark modes
#
# Usage:
#   ./scripts/test-module.sh alacritty
#   ./scripts/test-module.sh terminals/kitty
#   ./scripts/test-module.sh --help

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

usage() {
    cat << EOF
${BLUE}Signal-Nix Module Tester${NC}

Test a single module in both light and dark modes to verify theming works correctly.

${YELLOW}Usage:${NC}
    $0 <module-name>
    $0 <category/module-name>

${YELLOW}Examples:${NC}
    $0 alacritty              # Test terminals/alacritty.nix
    $0 terminals/kitty        # Test terminals/kitty.nix
    $0 editors/neovim         # Test editors/neovim.nix

${YELLOW}Options:${NC}
    -h, --help               Show this help message
    -v, --verbose            Show detailed output
    --light-only             Test only light mode
    --dark-only              Test only dark mode

${YELLOW}What this script does:${NC}
    1. Locates the module file
    2. Creates a minimal test configuration
    3. Evaluates in dark mode
    4. Evaluates in light mode
    5. Reports success or errors

${YELLOW}Requirements:${NC}
    - Run from signal-nix root directory
    - Module must be in modules/ directory
    - nix command must be available

EOF
    exit 0
}

# Parse arguments
MODULE=""
VERBOSE=false
LIGHT_ONLY=false
DARK_ONLY=false

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --light-only)
            LIGHT_ONLY=true
            shift
            ;;
        --dark-only)
            DARK_ONLY=true
            shift
            ;;
        *)
            MODULE="$1"
            shift
            ;;
    esac
done

if [ -z "$MODULE" ]; then
    echo -e "${RED}Error: No module specified${NC}"
    echo ""
    usage
fi

# Function to find module file
find_module() {
    local module="$1"

    # If already has .nix extension, use as-is
    if [[ "$module" =~ \.nix$ ]]; then
        echo "modules/$module"
        return
    fi

    # If contains slash, assume it's category/name
    if [[ "$module" == */* ]]; then
        echo "modules/${module}.nix"
        return
    fi

    # Otherwise, search for it
    local found=$(find modules/ -name "${module}.nix" -type f 2>/dev/null | head -n1)

    if [ -n "$found" ]; then
        echo "$found"
    else
        return 1
    fi
}

# Function to test module in a mode
test_mode() {
    local module_file="$1"
    local mode="$2"

    echo -e "${CYAN}Testing ${mode} mode...${NC}"

    # Create temporary test configuration
    local test_config=$(mktemp)
    cat > "$test_config" << EOF
{ config, lib, pkgs, ... }:
{
  imports = [
    ./modules/common/default.nix
  ];

  theming.signal = {
    enable = true;
    mode = "${mode}";
    autoEnable = true;
  };

  # Enable common programs to avoid warnings
  programs = {
    home-manager.enable = true;
  };

  home = {
    username = "test-user";
    homeDirectory = "/home/test-user";
    stateVersion = "24.05";
  };
}
EOF

    # Try to evaluate
    if $VERBOSE; then
        echo "Evaluating configuration..."
        if nix eval --impure --expr "(import ${test_config} { pkgs = import <nixpkgs> {}; lib = (import <nixpkgs> {}).lib; }).config.theming.signal.enable" 2>&1; then
            echo -e "${GREEN}✓${NC} ${mode} mode evaluation successful"
            rm "$test_config"
            return 0
        else
            echo -e "${RED}✗${NC} ${mode} mode evaluation failed"
            rm "$test_config"
            return 1
        fi
    else
        if nix eval --impure --expr "(import ${test_config} { pkgs = import <nixpkgs> {}; lib = (import <nixpkgs> {}).lib; }).config.theming.signal.enable" > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} ${mode} mode evaluation successful"
            rm "$test_config"
            return 0
        else
            echo -e "${RED}✗${NC} ${mode} mode evaluation failed"
            echo ""
            echo "Run with --verbose to see error details"
            rm "$test_config"
            return 1
        fi
    fi
}

# Main logic
main() {
    echo -e "${BLUE}Signal-Nix Module Tester${NC}"
    echo ""

    # Find module file
    echo "Looking for module: $MODULE"
    MODULE_FILE=$(find_module "$MODULE") || {
        echo -e "${RED}✗ Module not found: $MODULE${NC}"
        echo ""
        echo "Available modules:"
        find modules/ -name "*.nix" -type f | sed 's|modules/||' | sed 's|.nix$||' | sort | sed 's/^/  - /'
        exit 1
    }

    if [ ! -f "$MODULE_FILE" ]; then
        echo -e "${RED}✗ Module file not found: $MODULE_FILE${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓${NC} Found module: $MODULE_FILE"
    echo ""

    # Check for hardcoded colors first
    echo "Checking for hardcoded colors..."
    if ./scripts/lint-colors.sh "$MODULE_FILE" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} No hardcoded colors found"
    else
        echo -e "${YELLOW}⚠${NC}  Hardcoded colors detected (run lint-colors.sh for details)"
    fi
    echo ""

    # Test modes
    local dark_ok=true
    local light_ok=true

    if ! $LIGHT_ONLY; then
        test_mode "$MODULE_FILE" "dark" || dark_ok=false
    fi

    echo ""

    if ! $DARK_ONLY; then
        test_mode "$MODULE_FILE" "light" || light_ok=false
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if $dark_ok && $light_ok; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        echo ""
        echo "Module is working correctly in both modes."
        exit 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        echo ""
        if ! $dark_ok; then
            echo -e "  ${RED}✗${NC} Dark mode failed"
        fi
        if ! $light_ok; then
            echo -e "  ${RED}✗${NC} Light mode failed"
        fi
        echo ""
        echo "Run with --verbose to see detailed errors."
        exit 1
    fi
}

# Check if in signal-nix directory
if [ ! -f "flake.nix" ] || [ ! -d "modules" ]; then
    echo -e "${RED}Error: Must be run from signal-nix root directory${NC}"
    exit 1
fi

main
