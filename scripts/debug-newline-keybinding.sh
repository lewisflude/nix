#!/usr/bin/env bash
# Debug script for Shift+Enter newline keybinding issues
# This script helps diagnose why Shift+Enter doesn't insert newlines on macOS/NixOS

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
    print_info "Detected: macOS"
else
    OS="linux"
    print_info "Detected: Linux"
fi

# 1. Check Ghostty configuration
print_header "1. Ghostty Configuration"

if command -v ghostty &>/dev/null; then
    print_success "Ghostty is installed"
    ghostty --version
    
    # Check Ghostty config file
    if [ "$OS" = "macos" ]; then
        GHOSTTY_CONFIG="$HOME/.config/ghostty/config"
    else
        GHOSTTY_CONFIG="$HOME/.config/ghostty/config"
    fi
    
    if [ -f "$GHOSTTY_CONFIG" ]; then
        print_success "Ghostty config found at: $GHOSTTY_CONFIG"
        
        if grep -q "keybind.*shift.*enter" "$GHOSTTY_CONFIG"; then
            print_success "Shift+Enter keybinding found in config:"
            grep "keybind.*shift.*enter" "$GHOSTTY_CONFIG" | sed 's/^/  /'
        else
            print_warning "No Shift+Enter keybinding found in Ghostty config"
            print_info "Expected: keybind = shift+enter=text:\n"
        fi
    else
        print_warning "Ghostty config not found at: $GHOSTTY_CONFIG"
    fi
else
    print_error "Ghostty is not installed or not in PATH"
fi

# 2. Check terminal shell configuration
print_header "2. Shell Configuration (ZSH)"

if [ -f "$HOME/.zshrc" ]; then
    print_success "~/.zshrc found"
    
    if grep -q "ghostty-insert-newline\|ghostty_insert_newline" "$HOME/.zshrc"; then
        print_success "Ghostty multiline support found in .zshrc:"
        grep -A2 "ghostty.*newline" "$HOME/.zshrc" | sed 's/^/  /'
    else
        print_warning "No Ghostty newline support found in .zshrc"
    fi
else
    print_warning "~/.zshrc not found"
fi

# 3. macOS-specific checks
if [ "$OS" = "macos" ]; then
    print_header "3. macOS Keyboard Settings"
    
    # Check Karabiner Elements
    if [ -f "$HOME/.config/karabiner/karabiner.json" ]; then
        print_success "Karabiner Elements configuration found"
        
        # Check if there are any rules that might interfere with Shift+Enter
        if grep -q "shift.*enter\|return_or_enter" "$HOME/.config/karabiner/karabiner.json"; then
            print_warning "Found rules involving Enter/Return in Karabiner config:"
            grep -B2 -A2 "return_or_enter" "$HOME/.config/karabiner/karabiner.json" | head -20 | sed 's/^/  /'
            print_info "Karabiner might be intercepting Shift+Enter"
        else
            print_success "No Shift+Enter rules found in Karabiner"
        fi
    else
        print_info "Karabiner Elements not configured"
    fi
    
    # Check if Karabiner is running
    if pgrep -q karabiner; then
        print_warning "Karabiner Elements is currently running"
        print_info "Try temporarily disabling it to test if it's causing issues"
    else
        print_info "Karabiner Elements is not running"
    fi
    
    # Check system keyboard settings
    print_info "Checking macOS keyboard settings..."
    
    # Key repeat settings
    KEY_REPEAT=$(defaults read -g KeyRepeat 2>/dev/null || echo "not set")
    INITIAL_KEY_REPEAT=$(defaults read -g InitialKeyRepeat 2>/dev/null || echo "not set")
    print_info "Key Repeat: $KEY_REPEAT (lower = faster)"
    print_info "Initial Key Repeat: $INITIAL_KEY_REPEAT (lower = faster)"
    
    # Press and hold
    PRESS_HOLD=$(defaults read -g ApplePressAndHoldEnabled 2>/dev/null || echo "not set")
    if [ "$PRESS_HOLD" = "0" ]; then
        print_success "Press and hold is disabled (good for key repeat)"
    else
        print_info "Press and hold is enabled or not set"
    fi
fi

# 4. Application-specific checks
print_header "4. Application Configurations"

# Check Cursor settings
CURSOR_SETTINGS="$HOME/Library/Application Support/Cursor/User/settings.json"
if [ "$OS" = "linux" ]; then
    CURSOR_SETTINGS="$HOME/.config/Cursor/User/settings.json"
fi

if [ -f "$CURSOR_SETTINGS" ]; then
    print_success "Cursor settings found"
    
    if grep -q "acceptSuggestionOnEnter" "$CURSOR_SETTINGS"; then
        ENTER_BEHAVIOR=$(grep "acceptSuggestionOnEnter" "$CURSOR_SETTINGS" | sed 's/^/  /')
        echo "$ENTER_BEHAVIOR"
        print_info "This setting affects Enter behavior in Cursor"
    fi
    
    # Check for custom keybindings
    CURSOR_KEYBINDINGS="$HOME/Library/Application Support/Cursor/User/keybindings.json"
    if [ "$OS" = "linux" ]; then
        CURSOR_KEYBINDINGS="$HOME/.config/Cursor/User/keybindings.json"
    fi
    
    if [ -f "$CURSOR_KEYBINDINGS" ]; then
        if grep -q "shift.*enter" "$CURSOR_KEYBINDINGS"; then
            print_warning "Found Shift+Enter keybindings in Cursor:"
            grep -B2 -A2 "shift.*enter" "$CURSOR_KEYBINDINGS" | sed 's/^/  /'
        fi
    fi
else
    print_info "Cursor settings not found"
fi

# 5. Testing section
print_header "5. Interactive Tests"

echo ""
echo "Please perform the following manual tests:"
echo ""
echo "TEST 1: Terminal (Ghostty)"
echo "  1. Open Ghostty terminal"
echo "  2. Type some text"
echo "  3. Press Shift+Enter"
echo "  4. Does it insert a newline? (it should)"
echo ""
echo "TEST 2: Claude Desktop App"
echo "  1. Open Claude desktop app"
echo "  2. In the message input area, type some text"
echo "  3. Press Shift+Enter"
echo "  4. Does it insert a newline? (it should)"
echo ""
echo "TEST 3: Cursor Editor"
echo "  1. Open Cursor"
echo "  2. Open any file or create a new one"
echo "  3. Press Shift+Enter"
echo "  4. Does it insert a newline? (it should)"
echo ""
echo "TEST 4: Web Browser (Claude/Gemini web)"
echo "  1. Open Claude or Gemini in a web browser"
echo "  2. In the message input, type some text"
echo "  3. Press Shift+Enter"
echo "  4. Does it insert a newline? (it should)"
echo ""

# 6. Debugging recommendations
print_header "6. Debugging Recommendations"

echo ""
echo "If Shift+Enter is NOT working, try these steps in order:"
echo ""
echo "STEP 1: Test in safe applications"
print_info "  Open TextEdit or Notes and test Shift+Enter there"
print_info "  If it works there, the issue is app-specific"
echo ""

echo "STEP 2: Check for conflicting keybindings"
if [ "$OS" = "macos" ]; then
    print_info "  System Settings > Keyboard > Keyboard Shortcuts"
    print_info "  Search for 'Enter' or 'Return' shortcuts"
    print_info "  Temporarily disable Karabiner Elements:"
    echo "    osascript -e 'quit app \"Karabiner-Elements\"'"
fi
echo ""

echo "STEP 3: Application-specific fixes"
echo ""
echo "  For Cursor/VSCode:"
print_info "    Add to keybindings.json:"
echo '    {'
echo '      "key": "shift+enter",'
echo '      "command": "editor.action.insertLineAfter",'
echo '      "when": "editorTextFocus && !editorReadonly"'
echo '    }'
echo ""

echo "  For Claude Desktop:"
print_info "    This is controlled by the app itself"
print_info "    Try Cmd+Enter or Option+Enter as alternatives"
echo ""

echo "  For web browsers:"
print_info "    Check browser extensions that might interfere"
print_info "    Try in incognito/private mode to rule out extensions"
echo ""

echo "STEP 4: Rebuild Home Manager configuration"
if [ "$OS" = "macos" ]; then
    print_info "  darwin-rebuild switch"
else
    print_info "  home-manager switch"
fi
print_info "  This ensures Ghostty config is properly deployed"
echo ""

echo "STEP 5: Check alternative keybindings"
echo "  Try these alternatives if Shift+Enter doesn't work:"
print_info "    • Option+Enter (⌥+Enter on Mac)"
print_info "    • Cmd+Enter (⌘+Enter on Mac)"
print_info "    • Ctrl+Enter (^+Enter on Mac)"
echo ""

# 7. Generate test file
print_header "7. Keybinding Test File"

TEST_FILE="/tmp/keybinding-test.txt"
cat > "$TEST_FILE" << 'EOF'
Keybinding Test File
====================

Instructions:
1. Open this file in different applications (Cursor, TextEdit, etc.)
2. Place cursor after each line below
3. Press Shift+Enter
4. Check if a new line is inserted

Test lines (press Shift+Enter after each):
Line 1 here→
Line 2 here→
Line 3 here→

Expected result:
Each line should have a blank line after it when you press Shift+Enter

Alternative keybindings to test:
- Shift+Enter (⇧+↩)
- Option+Enter (⌥+↩)
- Cmd+Enter (⌘+↩)
- Ctrl+Enter (^+↩)
EOF

print_success "Created test file at: $TEST_FILE"
print_info "Open this file in different apps to test keybindings"

# 8. Summary
print_header "8. Summary & Next Steps"

echo ""
echo "Quick troubleshooting checklist:"
echo ""
echo "[ ] Test Shift+Enter in TextEdit/Notes (macOS) or gedit (Linux)"
echo "[ ] Check Karabiner Elements configuration (macOS)"
echo "[ ] Temporarily disable Karabiner Elements (macOS)"
echo "[ ] Test in Ghostty terminal"
echo "[ ] Test in web browser (incognito mode)"
echo "[ ] Check Cursor keybindings.json"
echo "[ ] Try alternative keybindings (Option+Enter, Cmd+Enter)"
echo "[ ] Rebuild home-manager configuration"
echo ""

print_info "For more help, see:"
print_info "  • Ghostty docs: https://ghostty.org/docs"
print_info "  • Karabiner docs: https://karabiner-elements.pqrs.org/docs/"
print_info "  • VSCode keybindings: https://code.visualstudio.com/docs/getstarted/keybindings"
echo ""
