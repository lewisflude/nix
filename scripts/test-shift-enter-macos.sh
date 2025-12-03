#!/usr/bin/env bash
# Test Shift+Enter handling at different levels on macOS
# This script helps identify WHERE the Shift+Enter is being blocked

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }

print_header "macOS Shift+Enter Deep Diagnostics"

echo ""
print_info "This script will help identify why Shift+Enter isn't working system-wide"
echo ""

# 1. Check if this is a keyboard hardware/firmware issue
print_header "1. Keyboard Hardware Check"

echo ""
print_info "Physical keyboard detection:"
ioreg -n AppleHIDKeyboard -r | grep -A5 "Product" | head -20
echo ""

KEYBOARD_COUNTRY=$(ioreg -n AppleHIDKeyboard -r | grep "CountryCode" | awk '{print $NF}' | head -1)
if [ -n "$KEYBOARD_COUNTRY" ]; then
    print_success "Keyboard country code: $KEYBOARD_COUNTRY"
else
    print_warning "Could not detect keyboard country code"
fi

# Check if MNK88 is connected
if ioreg -n AppleHIDKeyboard -r | grep -q "19280"; then
    print_success "MNK88 keyboard detected (Vendor ID: 19280)"
    print_info "Checking if Karabiner remapping might affect Shift+Enter..."
else
    print_info "Using built-in or other keyboard"
fi

# 2. Check macOS Text Input System
print_header "2. macOS Text Input System"

echo ""
print_info "Input Source configuration:"
defaults read com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null | grep -B2 -A2 "KeyboardLayout Name"
echo ""

# Check for input methods that might interfere
INPUT_METHOD=$(defaults read com.apple.HIToolbox AppleCurrentKeyboardLayoutInputSourceID 2>/dev/null || echo "not set")
print_info "Current input method: $INPUT_METHOD"

# 3. Check for system-wide keyboard shortcuts that might conflict
print_header "3. System Keyboard Shortcuts"

echo ""
print_info "Checking for shortcuts involving Enter/Return..."

# Check symbolic hotkeys (system shortcuts)
if defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys &>/dev/null; then
    print_success "Symbolic hotkeys configured"
    
    # Look for any shortcuts using Return/Enter with Shift
    HOTKEYS=$(defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys 2>/dev/null)
    if echo "$HOTKEYS" | grep -q "NSCarriageReturnCharacter"; then
        print_warning "Found system shortcuts involving Return key"
        echo "$HOTKEYS" | grep -A5 "NSCarriageReturnCharacter" | head -20
    else
        print_success "No system shortcuts using Return key"
    fi
else
    print_info "No symbolic hotkeys configured"
fi

# Check app-specific keyboard shortcuts
echo ""
print_info "Checking app-specific keyboard shortcuts..."
if defaults read -g NSUserKeyEquivalents &>/dev/null; then
    USER_SHORTCUTS=$(defaults read -g NSUserKeyEquivalents 2>/dev/null)
    if [ -n "$USER_SHORTCUTS" ] && [ "$USER_SHORTCUTS" != "{}" ]; then
        print_warning "Found custom keyboard shortcuts:"
        echo "$USER_SHORTCUTS"
    else
        print_success "No custom app keyboard shortcuts"
    fi
else
    print_success "No custom app keyboard shortcuts"
fi

# 4. Check Accessibility Permissions
print_header "4. Accessibility & Security"

echo ""
print_info "Checking accessibility permissions for key apps..."

# Check if Karabiner has accessibility access
if [ -d "/Applications/Karabiner-Elements.app" ]; then
    KARABINER_BUNDLE="org.pqrs.Karabiner-Elements"
    print_info "Karabiner Elements is installed"
    
    # Check if it's in accessibility database
    if sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db "SELECT client FROM access WHERE service='kTCCServiceAccessibility' AND client LIKE '%Karabiner%';" 2>/dev/null | grep -q "Karabiner"; then
        print_success "Karabiner has accessibility access"
    else
        print_warning "Karabiner accessibility status unclear"
    fi
else
    print_info "Karabiner Elements not installed"
fi

# 5. Test if Shift+Enter is being remapped somewhere
print_header "5. Key Remapping Detection"

echo ""
print_info "Checking for key remapping tools..."

# Check Karabiner config
if [ -f "$HOME/.config/karabiner/karabiner.json" ]; then
    print_success "Karabiner config found"
    
    # Check for any rules involving shift and enter/return
    if grep -q "shift.*return\|return.*shift" "$HOME/.config/karabiner/karabiner.json"; then
        print_warning "Found Karabiner rules involving Shift+Return:"
        grep -B3 -A3 "shift.*return\|return.*shift" "$HOME/.config/karabiner/karabiner.json" | head -20
    else
        print_success "No Karabiner rules affecting Shift+Return"
    fi
    
    # Check if any complex modifications are active
    RULES_COUNT=$(grep -c '"rules"' "$HOME/.config/karabiner/karabiner.json" || echo "0")
    print_info "Karabiner has $RULES_COUNT rule sections"
else
    print_info "No Karabiner configuration"
fi

# Check for other keyboard remapping tools
echo ""
print_info "Checking for other keyboard tools..."
for app in "BetterTouchTool" "Keyboard Maestro" "Alfred" "Hammerspoon"; do
    if [ -d "/Applications/$app.app" ]; then
        print_warning "$app is installed (might have keyboard shortcuts)"
    fi
done

# 6. British Keyboard Layout Check
print_header "6. Keyboard Layout Analysis"

echo ""
print_info "You're using British keyboard layout"
print_info "British keyboards have different key positions for some keys"
echo ""

# British layout specific check
print_info "British keyboard differences from US:"
echo "  • @ and \" are swapped"
echo "  • # is Shift+3 (not Shift+£)"
echo "  • Return/Enter key is usually same"
echo ""

print_warning "IMPORTANT: On UK keyboards, check if:"
echo "  1. Your Shift key is functioning properly"
echo "  2. Your Enter/Return key is the correct one (not numeric keypad Enter)"
echo "  3. Both left and right Shift keys behave the same"
echo ""

# 7. Interactive Test
print_header "7. Manual Testing Instructions"

echo ""
echo "Let's test Shift+Enter in different contexts:"
echo ""

echo "TEST A: Test in TextEdit (native macOS app)"
echo "  1. Open TextEdit (Cmd+Space, type 'TextEdit')"
echo "  2. Create a new document (Cmd+N)"
echo "  3. Type: 'Line 1'"
echo "  4. Press Shift+Enter"
echo "  5. Type: 'Line 2'"
echo ""
echo "  Expected: You should see two lines"
echo "  Result: [TEST THIS FIRST]"
echo ""

echo "TEST B: Test in Notes (native macOS app)"
echo "  1. Open Notes"
echo "  2. Create a new note"
echo "  3. Type some text"
echo "  4. Press Shift+Enter"
echo ""
echo "  Expected: New line inserted"
echo "  Result: [TEST THIS]"
echo ""

echo "TEST C: Test in Safari/Chrome (web app)"
echo "  1. Open claude.ai in a web browser"
echo "  2. In the message box, type text"
echo "  3. Press Shift+Enter"
echo ""
echo "  Expected: New line inserted (message NOT sent)"
echo "  Result: [TEST THIS]"
echo ""

echo "TEST D: Test different Shift keys"
echo "  Try BOTH the left and right Shift keys"
echo "  Some keyboards have issues with one but not the other"
echo ""

# 8. Diagnostic recommendations
print_header "8. Diagnosis & Solutions"

echo ""
echo "Based on the checks above, follow this decision tree:"
echo ""

echo "IF Shift+Enter works in TextEdit/Notes:"
print_info "  → The issue is app-specific configuration"
print_info "  → Solution: Configure individual apps (Cursor, Claude, etc.)"
echo ""

echo "IF Shift+Enter does NOT work in TextEdit/Notes:"
print_error "  → This is a system-level macOS keyboard issue"
echo ""
echo "  Possible causes:"
echo "  1. Keyboard hardware issue (especially if wireless)"
echo "  2. macOS keyboard settings misconfigured"
echo "  3. Karabiner or other tool blocking the key"
echo "  4. Accessibility permissions issue"
echo "  5. Input method intercepting the keystroke"
echo ""
echo "  Solutions to try IN ORDER:"
echo ""
echo "  SOLUTION 1: Test with a different keyboard"
print_info "    → Plug in a different keyboard (or use built-in MacBook keyboard)"
print_info "    → This rules out hardware issues"
echo ""
echo "  SOLUTION 2: Disable Karabiner completely"
print_info "    → Run: osascript -e 'quit app \"Karabiner-Elements\"'"
print_info "    → Test Shift+Enter again"
print_info "    → If it works, Karabiner is the culprit"
echo ""
echo "  SOLUTION 3: Reset keyboard settings"
print_info "    → System Settings > Keyboard > Keyboard Shortcuts"
print_info "    → Click 'Restore Defaults' at the bottom"
print_info "    → Restart Mac"
echo ""
echo "  SOLUTION 4: Check for Shift key stuck/held"
print_info "    → Sometimes Shift can be 'virtually stuck'"
print_info "    → Press both Shift keys several times"
print_info "    → Try Caps Lock on/off"
echo ""
echo "  SOLUTION 5: Create new user account (test)"
print_info "    → System Settings > Users & Groups > Add Account"
print_info "    → Log in to new account"
print_info "    → Test Shift+Enter there"
print_info "    → If it works, your main account has corrupted settings"
echo ""
echo "  SOLUTION 6: Check keyboard firmware (MNK88)"
print_info "    → Your MNK88 keyboard might have custom firmware"
print_info "    → Check if it's remapping Shift+Enter at hardware level"
print_info "    → Try using VIA/VIAL to check keymap"
echo ""

# 9. Quick fix suggestions
print_header "9. Immediate Workarounds"

echo ""
echo "While diagnosing, use these alternative keybindings:"
echo ""
print_success "Alternative 1: Option+Enter (⌥+↩)"
print_info "  → Try this in Claude, Cursor, terminal"
print_info "  → Less commonly remapped than Shift+Enter"
echo ""
print_success "Alternative 2: Ctrl+Enter (⌃+↩)"
print_info "  → Common in some apps"
echo ""
print_success "Alternative 3: Cmd+Return (⌘+↩)"
print_info "  → Used in some messaging apps"
echo ""

# 10. Create a test application
print_header "10. Automated Key Detection Test"

echo ""
print_info "Creating a simple test..."
cat > /tmp/test-shift-enter.sh << 'TESTEOF'
#!/usr/bin/env bash
echo "Press any key combination (Press Ctrl+C to exit):"
echo "Try: Shift+Enter, Option+Enter, Ctrl+Enter, etc."
echo ""

while true; do
    # Read single character with timeout
    if IFS= read -rsn1 -t 0.1 char; then
        # Get the ASCII/hex value
        if [ -n "$char" ]; then
            printf "Key pressed: "
            printf "%s" "$char" | od -An -tx1
            printf " (char: %s)\n" "$char"
        fi
    fi
done
TESTEOF

chmod +x /tmp/test-shift-enter.sh

print_success "Created key test script at: /tmp/test-shift-enter.sh"
print_info "Run it in terminal: /tmp/test-shift-enter.sh"
print_info "Then press Shift+Enter to see what code is generated"
echo ""

print_header "Summary"

echo ""
print_info "Next steps:"
echo "  1. Test Shift+Enter in TextEdit (TEST A above)"
echo "  2. If it doesn't work there → Hardware/System issue"
echo "  3. If it DOES work there → App configuration issue"
echo "  4. Report back which test results you got"
echo ""

print_warning "Most likely causes based on your symptoms:"
echo "  1. Karabiner intercepting the keystroke (most common)"
echo "  2. MNK88 keyboard firmware remapping Shift+Enter"
echo "  3. macOS input method conflict"
echo ""

print_info "For detailed app-specific config, see: docs/NEWLINE_KEYBINDINGS.md"
echo ""
