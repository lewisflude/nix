#!/usr/bin/env bash
# Keyboard Configuration Test Script - macOS
# Tests the v2.0 Ergonomic Hybrid keyboard setup on macOS
#
# Usage: ./scripts/test-keyboard-macos.sh
# Requirements: Karabiner-Elements, VIA (optional)

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

# Test 1: Check if Karabiner-Elements is installed
test_karabiner_installed() {
    print_test "Checking if Karabiner-Elements is installed..."
    
    if [ -d "/Applications/Karabiner-Elements.app" ]; then
        print_pass "Karabiner-Elements is installed"
        return 0
    else
        print_fail "Karabiner-Elements is not installed"
        print_info "Install: brew install --cask karabiner-elements"
        print_info "Or rebuild: darwin-rebuild switch --flake ~/.config/nix"
        return 1
    fi
}

# Test 2: Check if Karabiner-Elements is running
test_karabiner_running() {
    print_test "Checking if Karabiner-Elements is running..."
    
    if pgrep -x "karabiner_console" > /dev/null || pgrep -x "Karabiner-Elements" > /dev/null; then
        print_pass "Karabiner-Elements is running"
        return 0
    else
        print_fail "Karabiner-Elements is not running"
        print_info "Launch: open /Applications/Karabiner-Elements.app"
        return 1
    fi
}

# Test 3: Check if karabiner_grabber is running
test_karabiner_grabber() {
    print_test "Checking if karabiner_grabber is running..."
    
    if pgrep -x "karabiner_grabber" > /dev/null; then
        print_pass "karabiner_grabber is running"
        return 0
    else
        print_fail "karabiner_grabber is not running"
        print_info "This may indicate permission issues"
        print_info "Check: System Settings → Privacy & Security → Input Monitoring"
        return 1
    fi
}

# Test 4: Check if configuration file exists
test_karabiner_config() {
    print_test "Checking if Karabiner configuration exists..."
    
    local config_file="$HOME/.config/karabiner/karabiner.json"
    
    if [ -f "$config_file" ]; then
        print_pass "Karabiner configuration file exists"
        
        # Validate JSON
        if python3 -m json.tool "$config_file" > /dev/null 2>&1; then
            print_pass "Configuration file is valid JSON"
        else
            print_fail "Configuration file is not valid JSON"
            return 1
        fi
        
        return 0
    else
        print_fail "Karabiner configuration file not found"
        print_info "Expected: $config_file"
        print_info "Rebuild: darwin-rebuild switch --flake ~/.config/nix"
        return 1
    fi
}

# Test 5: Verify configuration content
test_karabiner_config_content() {
    print_test "Verifying Karabiner configuration content..."
    
    local config_file="$HOME/.config/karabiner/karabiner.json"
    local errors=0
    
    if [ ! -f "$config_file" ]; then
        print_fail "Configuration file not found, skipping content check"
        return 1
    fi
    
    # Check for Caps Lock rule
    if grep -q "Caps Lock" "$config_file"; then
        print_pass "Caps Lock remapping rule found"
    else
        print_fail "Caps Lock remapping rule not found"
        ((errors++))
    fi
    
    # Check for F13 rule
    if grep -q "F13" "$config_file" || grep -q "f13" "$config_file"; then
        print_pass "F13 remapping rule found"
    else
        print_fail "F13 remapping rule not found"
        ((errors++))
    fi
    
    # Check for Right Option navigation
    if grep -q "right_option" "$config_file"; then
        print_pass "Right Option navigation layer found"
    else
        print_fail "Right Option navigation layer not found"
        ((errors++))
    fi
    
    # Check for HJKL mappings
    if grep -q "arrow" "$config_file"; then
        print_pass "Arrow key mappings found"
    else
        print_fail "Arrow key mappings not found"
        ((errors++))
    fi
    
    if [ $errors -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Test 6: Check for VIA installation
test_via_installation() {
    print_test "Checking for VIA installation..."
    
    if [ -d "/Applications/VIA.app" ]; then
        print_pass "VIA is installed"
        return 0
    else
        print_fail "VIA is not installed"
        print_info "Install: brew install --cask via"
        print_info "Or rebuild: darwin-rebuild switch --flake ~/.config/nix"
        return 1
    fi
}

# Test 7: Check firmware file existence
test_firmware_file() {
    print_test "Checking for firmware configuration file..."
    
    local firmware_file="$HOME/.config/nix/docs/reference/mnk88-universal.layout.json"
    
    if [ -f "$firmware_file" ]; then
        print_pass "Firmware file exists: $firmware_file"
        
        # Validate JSON
        if python3 -m json.tool "$firmware_file" > /dev/null 2>&1; then
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

# Test 8: Check macOS permissions
test_permissions() {
    print_test "Checking accessibility permissions (requires manual verification)..."
    
    print_info "Please verify the following permissions are granted:"
    print_info "1. System Settings → Privacy & Security → Accessibility"
    print_info "   - Karabiner-Elements should be enabled"
    print_info "2. System Settings → Privacy & Security → Input Monitoring"
    print_info "   - karabiner_grabber should be enabled"
    print_info "   - karabiner_observer should be enabled"
    print_info ""
    print_info "Cannot automatically test (requires System APIs)"
    
    # We'll count this as a pass since we can't programmatically check
    print_pass "Permission check reminder displayed"
    return 0
}

# Manual test instructions
manual_tests() {
    print_header "MANUAL TESTING INSTRUCTIONS"
    
    echo "The following tests require manual verification:"
    echo ""
    echo "1. CAPS LOCK TAP TEST"
    echo "   - Open TextEdit or any text editor"
    echo "   - Tap Caps Lock quickly (don't hold)"
    echo "   - Expected: Escape key behavior (no visible output)"
    echo "   - In vim: Should exit insert mode"
    echo ""
    echo "2. CAPS LOCK HOLD TEST"
    echo "   - Hold Caps Lock + Space"
    echo "   - Expected: Spotlight search opens (Cmd+Space)"
    echo "   - Try: Caps Lock + W (close window)"
    echo "   - Try: Caps Lock + C/V (copy/paste)"
    echo ""
    echo "3. NAVIGATION LAYER TEST"
    echo "   - Open TextEdit with multiple lines"
    echo "   - Hold Right Option + H"
    echo "   - Expected: Cursor moves left (arrow key)"
    echo "   - Try: Right Option + J (down), K (up), L (right)"
    echo ""
    echo "4. PAGE NAVIGATION TEST"
    echo "   - Open a long document"
    echo "   - Hold Right Option + U"
    echo "   - Expected: Page up"
    echo "   - Try: Right Option + A (start of line), E (end of line)"
    echo ""
    echo "5. WORD NAVIGATION TEST"
    echo "   - Open TextEdit with several words"
    echo "   - Hold Right Option + W"
    echo "   - Expected: Jump to next word (Option+Right)"
    echo "   - Try: Right Option + B (previous word)"
    echo ""
    echo "6. EDIT SHORTCUTS TEST"
    echo "   - Type some text in TextEdit"
    echo "   - Hold Right Option + C"
    echo "   - Expected: Copy (Cmd+C behavior)"
    echo "   - Try: Right Option + V (paste), X (cut), Z (undo)"
    echo ""
    echo "7. MEDIA CONTROLS TEST"
    echo "   - Start playing music"
    echo "   - Hold Right Option + F8"
    echo "   - Expected: Play/Pause"
    echo "   - Try: Right Option + F5/F6 (volume), F9 (next track)"
    echo ""
    echo "8. F13 BACKUP TEST"
    echo "   - Hold F13 + Space"
    echo "   - Expected: Spotlight opens (same as Caps+Space)"
    echo ""
    echo "For detailed testing:"
    echo "  - Open Karabiner-Elements"
    echo "  - Go to: Log → Show log messages"
    echo "  - Press keys and observe events"
    echo ""
}

# Additional diagnostic info
diagnostic_info() {
    print_header "DIAGNOSTIC INFORMATION"
    
    echo "Karabiner-Elements Location:"
    if [ -d "/Applications/Karabiner-Elements.app" ]; then
        echo "  ✓ /Applications/Karabiner-Elements.app"
    else
        echo "  ✗ Not found"
    fi
    
    echo ""
    echo "Running Processes:"
    ps aux | grep -i karabiner | grep -v grep || echo "  (no Karabiner processes found)"
    
    echo ""
    echo "Configuration Files:"
    if [ -f "$HOME/.config/karabiner/karabiner.json" ]; then
        local size=$(stat -f%z "$HOME/.config/karabiner/karabiner.json")
        echo "  ✓ karabiner.json ($size bytes)"
    else
        echo "  ✗ karabiner.json not found"
    fi
    
    echo ""
    echo "VIA Installation:"
    if [ -d "/Applications/VIA.app" ]; then
        echo "  ✓ /Applications/VIA.app"
    else
        echo "  ✗ VIA not installed"
    fi
    
    echo ""
}

# Main test execution
main() {
    print_header "macOS Keyboard Configuration Test Suite"
    print_info "Testing v2.0 Ergonomic Hybrid Configuration"
    echo ""
    
    # Run automated tests
    test_karabiner_installed || true
    test_karabiner_running || true
    test_karabiner_grabber || true
    test_karabiner_config || true
    test_karabiner_config_content || true
    test_via_installation || true
    test_firmware_file || true
    test_permissions || true
    
    # Display diagnostic info
    diagnostic_info
    
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
        echo "  1. Rebuild darwin config: darwin-rebuild switch --flake ~/.config/nix"
        echo "  2. Launch Karabiner: open /Applications/Karabiner-Elements.app"
        echo "  3. Grant permissions: System Settings → Privacy & Security"
        echo "  4. View config: cat ~/.config/karabiner/karabiner.json"
        echo "  5. Check logs: Open Karabiner-Elements → Log"
        exit 1
    fi
}

# Run main function
main
