#!/usr/bin/env bash
# Keyboard Configuration Test Script - NixOS
# Tests the v2.0 Ergonomic Hybrid keyboard setup on NixOS
#
# Usage: ./scripts/test-keyboard-nixos.sh
# Requirements: keyd, wev (for manual testing)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================${NC}"
}

# Test 1: Check if keyd service is running
test_keyd_service() {
    print_test "Checking if keyd service is running..."
    
    if systemctl is-active --quiet keyd; then
        print_pass "keyd service is active"
        return 0
    else
        print_fail "keyd service is not running"
        print_info "Try: sudo systemctl start keyd"
        return 1
    fi
}

# Test 2: Check if keyd service is enabled
test_keyd_enabled() {
    print_test "Checking if keyd service is enabled..."
    
    if systemctl is-enabled --quiet keyd; then
        print_pass "keyd service is enabled (will start on boot)"
        return 0
    else
        print_fail "keyd service is not enabled"
        print_info "Try: sudo systemctl enable keyd"
        return 1
    fi
}

# Test 3: Check if keyd configuration exists
test_keyd_config() {
    print_test "Checking if keyd configuration exists..."
    
    if [ -f "/etc/keyd/default.conf" ]; then
        print_pass "keyd configuration file exists"
        return 0
    else
        print_fail "keyd configuration file not found"
        print_info "Expected: /etc/keyd/default.conf"
        return 1
    fi
}

# Test 4: Verify keyd configuration content
test_keyd_config_content() {
    print_test "Verifying keyd configuration content..."
    
    local config_file="/etc/keyd/default.conf"
    local errors=0
    
    # Check for Caps Lock remapping
    if grep -q "capslock = overload(super, esc)" "$config_file"; then
        print_pass "Caps Lock remapping configured correctly"
    else
        print_fail "Caps Lock remapping not found or incorrect"
        ((errors++))
    fi
    
    # Check for F13 remapping
    if grep -q "f13 = leftmeta" "$config_file"; then
        print_pass "F13 remapping configured correctly"
    else
        print_fail "F13 remapping not found or incorrect"
        ((errors++))
    fi
    
    # Check for Right Alt layer
    if grep -q "rightalt = layer(nav)" "$config_file"; then
        print_pass "Right Alt navigation layer configured"
    else
        print_fail "Right Alt navigation layer not found"
        ((errors++))
    fi
    
    # Check for navigation layer mappings
    if grep -A 20 "\[nav\]" "$config_file" | grep -q "h = left"; then
        print_pass "Navigation layer mappings present"
    else
        print_fail "Navigation layer mappings not found"
        ((errors++))
    fi
    
    # Check for timing configuration
    if grep -q "overload_tap_timeout" "$config_file"; then
        print_pass "Timing configuration present"
    else
        print_fail "Timing configuration not found (may use defaults)"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Test 5: Check keyd logs for errors
test_keyd_logs() {
    print_test "Checking keyd logs for recent errors..."
    
    local error_count=$(journalctl -u keyd --since "10 minutes ago" --no-pager | grep -i "error" | wc -l)
    
    if [ "$error_count" -eq 0 ]; then
        print_pass "No errors in recent keyd logs"
        return 0
    else
        print_fail "Found $error_count errors in recent keyd logs"
        print_info "View logs: journalctl -u keyd -n 50"
        return 1
    fi
}

# Test 6: Check for VIA/VIAL installation
test_via_installation() {
    print_test "Checking for VIA/VIAL installation..."
    
    local found=0
    
    if command -v vial &> /dev/null; then
        print_pass "VIAL is installed"
        ((found++))
    fi
    
    if command -v via &> /dev/null; then
        print_pass "VIA is installed"
        ((found++))
    fi
    
    if [ $found -eq 0 ]; then
        print_fail "Neither VIA nor VIAL is installed"
        print_info "Install via: home/nixos/system/keyboard.nix"
        return 1
    else
        return 0
    fi
}

# Test 7: Check firmware file existence
test_firmware_file() {
    print_test "Checking for firmware configuration file..."
    
    local firmware_file="$HOME/.config/nix/docs/reference/mnk88-universal.layout.json"
    
    if [ -f "$firmware_file" ]; then
        print_pass "Firmware file exists: $firmware_file"
        
        # Validate JSON
        if jq empty "$firmware_file" 2>/dev/null; then
            print_pass "Firmware file is valid JSON"
        else
            print_fail "Firmware file is not valid JSON"
            return 1
        fi
        
        return 0
    else
        print_fail "Firmware file not found"
        print_info "Expected: $firmware_file"
        return 1
    fi
}

# Manual test instructions
manual_tests() {
    print_header "MANUAL TESTING INSTRUCTIONS"
    
    echo "The following tests require manual verification:"
    echo ""
    echo "1. CAPS LOCK TAP TEST"
    echo "   - Open a terminal or text editor"
    echo "   - Tap Caps Lock quickly (don't hold)"
    echo "   - Expected: Escape key behavior (nothing visible in terminal)"
    echo "   - In vim: Should exit insert mode"
    echo ""
    echo "2. CAPS LOCK HOLD TEST"
    echo "   - Open a terminal"
    echo "   - Hold Caps Lock + T"
    echo "   - Expected: New terminal window opens (Mod+T shortcut)"
    echo ""
    echo "3. NAVIGATION LAYER TEST"
    echo "   - Open a text editor with multiple lines"
    echo "   - Hold Right Alt + H"
    echo "   - Expected: Cursor moves left (arrow key)"
    echo "   - Try: Right Alt + J (down), K (up), L (right)"
    echo ""
    echo "4. PAGE NAVIGATION TEST"
    echo "   - Open a long document"
    echo "   - Hold Right Alt + U"
    echo "   - Expected: Page up"
    echo "   - Try: Right Alt + A (home), E (end)"
    echo ""
    echo "5. WORD NAVIGATION TEST"
    echo "   - Open a text editor with several words"
    echo "   - Hold Right Alt + W"
    echo "   - Expected: Jump to next word (Ctrl+Right)"
    echo "   - Try: Right Alt + B (previous word)"
    echo ""
    echo "6. F13 BACKUP TEST"
    echo "   - Hold F13 + T"
    echo "   - Expected: New terminal window opens (same as Caps+T)"
    echo ""
    echo "For detailed testing, use: wev"
    echo "  - Run: wev"
    echo "  - Press keys and observe output"
    echo "  - Caps Hold should show: KEY_LEFTMETA"
    echo "  - Caps Tap should show: KEY_ESC"
    echo "  - Right Alt + H should show: KEY_LEFT"
    echo ""
}

# Test 8: Check wev installation
test_wev_installation() {
    print_test "Checking for wev installation (manual testing tool)..."
    
    if command -v wev &> /dev/null; then
        print_pass "wev is installed (use: wev)"
        return 0
    else
        print_fail "wev is not installed"
        print_info "Install: nix-shell -p wev"
        return 1
    fi
}

# Main test execution
main() {
    print_header "NixOS Keyboard Configuration Test Suite"
    print_info "Testing v2.0 Ergonomic Hybrid Configuration"
    echo ""
    
    # Run automated tests
    test_keyd_service || true
    test_keyd_enabled || true
    test_keyd_config || true
    test_keyd_config_content || true
    test_keyd_logs || true
    test_via_installation || true
    test_firmware_file || true
    test_wev_installation || true
    
    # Display manual test instructions
    manual_tests
    
    # Summary
    print_header "TEST SUMMARY"
    echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All automated tests passed!${NC}"
        echo "Please complete manual tests above to verify full functionality."
        exit 0
    else
        echo -e "${RED}✗ Some tests failed. Please review errors above.${NC}"
        echo ""
        echo "Common fixes:"
        echo "  1. Rebuild NixOS: sudo nixos-rebuild switch --flake ~/.config/nix"
        echo "  2. Restart keyd: sudo systemctl restart keyd"
        echo "  3. Check logs: journalctl -u keyd -n 50"
        echo "  4. View config: cat /etc/keyd/default.conf"
        exit 1
    fi
}

# Run main function
main
