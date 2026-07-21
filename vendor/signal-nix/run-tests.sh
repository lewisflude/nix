#!/usr/bin/env bash
# Signal-Nix Test Runner
# Convenience script for running tests with various options

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SYSTEM="x86_64-linux"
VERBOSE=false
CATEGORY=""
TEST_NAME=""

# Usage information
usage() {
    cat << EOF
Signal-Nix Test Runner

USAGE:
    $0 [OPTIONS] [TEST_NAME]

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Show verbose output (build logs)
    -s, --system SYSTEM     Target system (default: x86_64-linux)
    -c, --category CATEGORY Run all tests in a category
    -l, --list              List all available tests
    -a, --all               Run all tests (default if no options given)

CATEGORIES:
    happy          Happy path tests
    edge           Edge case tests
    error          Error handling tests
    integration    Integration tests
    performance    Performance tests
    security       Security tests
    unit           Unit tests
    module         Module tests
    validation     Validation tests
    documentation  Documentation tests
    color          Color conversion tests (nix-colorizer)
    activation     Home Manager activation package tests
    nixos-vm       NixOS VM integration tests (Linux only)

EXAMPLES:
    # Run all tests
    $0 --all

    # Run specific test
    $0 happy-basic-dark-mode

    # Run all integration tests
    $0 --category integration

    # Run with verbose output
    $0 --verbose unit-lib-getColors

    # Run on different system
    $0 --system aarch64-linux
EOF
}

# List all tests
list_tests() {
    echo -e "${BLUE}Available Tests:${NC}\n"
    
    echo -e "${GREEN}Happy Path Tests:${NC}"
    echo "  - happy-basic-dark-mode"
    echo "  - happy-basic-light-mode"
    echo "  - happy-auto-mode-defaults-dark"
    echo "  - happy-color-structure"
    echo "  - happy-syntax-colors-complete"
    echo "  - happy-brand-governance-functional-override"
    echo ""
    
    echo -e "${GREEN}Edge Case Tests:${NC}"
    echo "  - edge-empty-brand-colors"
    echo "  - edge-lightness-boundaries"
    echo "  - edge-chroma-boundaries"
    echo "  - edge-contrast-extreme-values"
    echo "  - edge-all-modules-disabled"
    echo "  - edge-ironbar-profiles"
    echo "  - edge-case-multiple-terminals"
    echo "  - edge-case-brand-governance"
    echo ""
    
    echo -e "${GREEN}Error Handling Tests:${NC}"
    echo "  - error-invalid-theme-mode"
    echo "  - error-brand-governance-invalid-policy"
    echo "  - error-color-manipulation-throws"
    echo ""
    
    echo -e "${GREEN}Integration Tests:${NC}"
    echo "  - integration-module-lib-interaction"
    echo "  - integration-colors-and-syntax"
    echo "  - integration-brand-with-colors"
    echo "  - integration-theme-resolution-consistency"
    echo "  - integration-auto-enable-logic"
    echo "  - integration-example-basic"
    echo "  - integration-example-auto-enable"
    echo "  - integration-example-full-desktop"
    echo "  - integration-example-custom-brand"
    echo "  - integration-helix-builds"
    echo "  - integration-ghostty-builds"
    echo ""
    
    echo -e "${GREEN}Performance Tests:${NC}"
    echo "  - performance-color-lookups"
    echo "  - performance-theme-resolution-cached"
    echo "  - performance-large-brand-colors"
    echo "  - performance-module-evaluation"
    echo ""
    
    echo -e "${GREEN}Security Tests:${NC}"
    echo "  - security-color-hex-validation"
    echo "  - security-no-code-injection"
    echo "  - security-mode-enum-validation"
    echo "  - security-brand-policy-enum-validation"
    echo "  - security-no-path-traversal"
    echo ""
    
    echo -e "${GREEN}Unit Tests:${NC}"
    echo "  - unit-lib-resolveThemeMode"
    echo "  - unit-lib-isValidResolvedMode"
    echo "  - unit-lib-getThemeName"
    echo "  - unit-lib-getColors"
    echo "  - unit-lib-getSyntaxColors"
    echo ""
    
    echo -e "${GREEN}Module Tests:${NC}"
    echo "  - module-common-evaluates"
    echo "  - module-helix-dark"
    echo "  - module-helix-light"
    echo "  - module-ghostty-evaluates"
    echo "  - module-bat-evaluates"
    echo "  - module-fzf-evaluates"
    echo "  - module-gtk-evaluates"
    echo "  - module-ironbar-evaluates"
    echo ""
    
    echo -e "${GREEN}Validation Tests:${NC}"
    echo "  - validation-theme-names"
    echo "  - validation-no-auto-theme-names"
    echo "  - accessibility-contrast-estimation"
    echo ""
    
    echo -e "${GREEN}Documentation Tests:${NC}"
    echo "  - documentation-examples-valid-nix"
    echo "  - documentation-readme-references"
    echo ""
    
    echo -e "${GREEN}Color Conversion Tests (nix-colorizer):${NC}"
    echo "  - color-conversion-hex-to-rgb"
    echo "  - color-conversion-hex-with-alpha"
    echo "  - color-conversion-validation"
    echo ""
}

# Get tests by category
get_tests_by_category() {
    local category=$1
    case $category in
        happy)
            echo "happy-basic-dark-mode happy-basic-light-mode happy-auto-mode-defaults-dark happy-color-structure happy-syntax-colors-complete happy-brand-governance-functional-override"
            ;;
        edge)
            echo "edge-empty-brand-colors edge-lightness-boundaries edge-chroma-boundaries edge-contrast-extreme-values edge-all-modules-disabled edge-ironbar-profiles edge-case-multiple-terminals edge-case-brand-governance"
            ;;
        error)
            echo "error-invalid-theme-mode error-brand-governance-invalid-policy error-color-manipulation-throws"
            ;;
        integration)
            echo "integration-module-lib-interaction integration-colors-and-syntax integration-brand-with-colors integration-theme-resolution-consistency integration-auto-enable-logic integration-example-basic integration-example-auto-enable integration-example-full-desktop integration-example-custom-brand integration-helix-builds integration-ghostty-builds"
            ;;
        performance)
            echo "performance-color-lookups performance-theme-resolution-cached performance-large-brand-colors performance-module-evaluation"
            ;;
        security)
            echo "security-color-hex-validation security-no-code-injection security-mode-enum-validation security-brand-policy-enum-validation security-no-path-traversal"
            ;;
        unit)
            echo "unit-lib-resolveThemeMode unit-lib-isValidResolvedMode unit-lib-getThemeName unit-lib-getColors unit-lib-getSyntaxColors"
            ;;
        module)
            echo "module-common-evaluates module-helix-dark module-helix-light module-ghostty-evaluates module-bat-evaluates module-fzf-evaluates module-gtk-evaluates module-ironbar-evaluates"
            ;;
        validation)
            echo "validation-theme-names validation-no-auto-theme-names accessibility-contrast-estimation"
            ;;
        documentation)
            echo "documentation-examples-valid-nix documentation-readme-references"
            ;;
        color)
            echo "color-conversion-hex-to-rgb color-conversion-hex-with-alpha color-conversion-validation"
            ;;
        activation)
            echo "activation-helix-dark activation-helix-light activation-alacritty-dark activation-ghostty-dark activation-multi-module activation-auto-enable"
            ;;
        nixos-vm)
            # NixOS VM tests (Linux only)
            if [[ "$SYSTEM" != *"linux"* ]]; then
                echo -e "${YELLOW}Warning: NixOS VM tests only run on Linux${NC}" >&2
                echo ""
            else
                echo "nixos-vm-console-colors nixos-vm-sddm nixos-vm-plymouth nixos-vm-grub nixos-vm-integration nixos-vm-light-mode"
            fi
            ;;
        *)
            echo -e "${RED}Unknown category: $category${NC}" >&2
            exit 1
            ;;
    esac
}

# Run a single test
run_test() {
    local test_name=$1
    local build_args=()
    
    if [[ "$VERBOSE" == "true" ]]; then
        build_args+=(--print-build-logs)
    fi
    
    echo -e "${BLUE}Running test: ${test_name}${NC}"
    
    # Start timing
    local start_time=$(date +%s)
    
    if nix build ".#checks.${SYSTEM}.${test_name}" "${build_args[@]}" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo -e "${GREEN}✓ ${test_name} passed (${duration}s)${NC}"
        
        # Output structured result for CI parsing
        if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
            echo "::notice title=Test Passed (${test_name})::Test passed in ${duration}s"
        fi
        
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo -e "${RED}✗ ${test_name} failed (${duration}s)${NC}"
        
        # Output structured failure for CI parsing
        if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
            echo "::error title=Test Failed (${test_name})::Test failed after ${duration}s"
        fi
        
        return 1
    fi
}

# Run multiple tests
run_tests() {
    local tests=("$@")
    local passed=0
    local failed=0
    local total=${#tests[@]}
    local total_duration=0
    
    echo -e "${BLUE}Running ${total} tests...${NC}\n"
    
    # Start overall timing
    local overall_start=$(date +%s)
    
    for test in "${tests[@]}"; do
        local test_start=$(date +%s)
        
        if run_test "$test"; then
            ((passed++))
        else
            ((failed++))
        fi
        
        local test_end=$(date +%s)
        local test_duration=$((test_end - test_start))
        total_duration=$((total_duration + test_duration))
        
        echo ""
    done
    
    local overall_end=$(date +%s)
    local overall_duration=$((overall_end - overall_start))
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Total:    ${total}"
    echo -e "${GREEN}Passed:   ${passed}${NC}"
    if [[ $failed -gt 0 ]]; then
        echo -e "${RED}Failed:   ${failed}${NC}"
    else
        echo -e "Failed:   0"
    fi
    echo -e "Duration: ${overall_duration}s"
    echo -e "========================================${NC}"
    
    # Output structured summary for CI
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        if [[ $failed -gt 0 ]]; then
            echo "::error title=Test Suite Failed::${failed} of ${total} tests failed (${overall_duration}s total)"
        else
            echo "::notice title=Test Suite Passed::All ${total} tests passed (${overall_duration}s total)"
        fi
    fi
    
    if [[ $failed -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}

# Run all tests
run_all_tests() {
    echo -e "${BLUE}Running all tests via nix flake check...${NC}\n"
    
    local build_args=()
    if [[ "$VERBOSE" == "true" ]]; then
        build_args+=(--print-build-logs)
    fi
    
    local start_time=$(date +%s)
    
    if nix flake check "${build_args[@]}" --system "$SYSTEM"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo -e "\n${GREEN}✓ All tests passed (${duration}s)${NC}"
        
        if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
            echo "::notice title=All Tests Passed::Complete test suite passed in ${duration}s"
        fi
        
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        echo -e "\n${RED}✗ Some tests failed (${duration}s)${NC}"
        
        if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
            echo "::error title=Tests Failed::Test suite failed after ${duration}s"
        fi
        
        return 1
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -s|--system)
            SYSTEM="$2"
            shift 2
            ;;
        -c|--category)
            CATEGORY="$2"
            shift 2
            ;;
        -l|--list)
            list_tests
            exit 0
            ;;
        -a|--all)
            run_all_tests
            exit $?
            ;;
        *)
            TEST_NAME="$1"
            shift
            ;;
    esac
done

# Main execution
if [[ -n "$CATEGORY" ]]; then
    tests=($(get_tests_by_category "$CATEGORY"))
    run_tests "${tests[@]}"
elif [[ -n "$TEST_NAME" ]]; then
    run_test "$TEST_NAME"
else
    run_all_tests
fi
