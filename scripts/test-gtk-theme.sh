#!/usr/bin/env bash
#
# Test GTK Theme Installation
# Tests that the Signal theme is properly compiled and installed

set -e

echo "=== GTK Theme Test ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Check GTK configuration
echo "Test 1: Checking GTK configuration..."
if grep -q "gtk-theme-name=Signal" ~/.config/gtk-3.0/settings.ini 2>/dev/null; then
    echo -e "${GREEN}✓${NC} GTK 3 configured to use Signal theme"
else
    echo -e "${RED}✗${NC} GTK 3 NOT configured for Signal theme"
    exit 1
fi

if grep -q "gtk-theme-name=Signal" ~/.config/gtk-4.0/settings.ini 2>/dev/null; then
    echo -e "${GREEN}✓${NC} GTK 4 configured to use Signal theme"
else
    echo -e "${RED}✗${NC} GTK 4 NOT configured for Signal theme"
    exit 1
fi

echo ""

# Test 2: Check if theme package is in Nix store
echo "Test 2: Checking Nix store for theme..."
THEME_PATH=$(nix path-info ~/.nix-profile | xargs nix-store -qR | grep signal-theme | head -1)
if [ -n "$THEME_PATH" ]; then
    echo -e "${GREEN}✓${NC} Signal theme found in Nix store: $THEME_PATH"
else
    echo -e "${YELLOW}⚠${NC} Signal theme not found in current profile"
    echo "Searching all of Nix store..."
    THEME_PATH=$(find /nix/store -maxdepth 1 -name "*signal-theme*" -type d 2>/dev/null | sort | tail -1)
    if [ -n "$THEME_PATH" ]; then
        echo -e "${GREEN}✓${NC} Found theme in: $THEME_PATH"
    else
        echo -e "${RED}✗${NC} Theme not found anywhere in Nix store"
        exit 1
    fi
fi

echo ""

# Test 3: Check theme files exist
echo "Test 3: Checking theme files..."
if [ -f "$THEME_PATH/share/themes/Signal/gtk-3.0/gtk.css" ]; then
    echo -e "${GREEN}✓${NC} GTK 3 CSS file exists"
    LINES=$(wc -l < "$THEME_PATH/share/themes/Signal/gtk-3.0/gtk.css")
    echo "  → $LINES lines"
else
    echo -e "${RED}✗${NC} GTK 3 CSS file missing"
    exit 1
fi

if [ -f "$THEME_PATH/share/themes/Signal/gtk-4.0/gtk.css" ]; then
    echo -e "${GREEN}✓${NC} GTK 4 CSS file exists"
    LINES=$(wc -l < "$THEME_PATH/share/themes/Signal/gtk-4.0/gtk.css")
    echo "  → $LINES lines"
else
    echo -e "${RED}✗${NC} GTK 4 CSS file missing"
    exit 1
fi

if [ -f "$THEME_PATH/share/themes/Signal/index.theme" ]; then
    echo -e "${GREEN}✓${NC} index.theme file exists"
else
    echo -e "${RED}✗${NC} index.theme file missing"
    exit 1
fi

echo ""

# Test 4: Verify SCSS compilation
echo "Test 4: Verifying SCSS was compiled correctly..."
if grep -q "@define-color theme_bg_color #" "$THEME_PATH/share/themes/Signal/gtk-3.0/gtk.css"; then
    echo -e "${GREEN}✓${NC} SCSS variables were interpolated to hex colors"
else
    echo -e "${RED}✗${NC} SCSS interpolation failed - variables not converted"
    exit 1
fi

# Check for color values from our palette
if grep -q "#1e1f26" "$THEME_PATH/share/themes/Signal/gtk-3.0/gtk.css"; then
    echo -e "${GREEN}✓${NC} Signal color palette detected (surface-base: #1e1f26)"
else
    echo -e "${YELLOW}⚠${NC} Signal colors may not be applied correctly"
fi

echo ""

# Test 5: Check custom CSS overrides
echo "Test 5: Checking CSS overrides..."
if [ -f ~/.config/gtk-3.0/gtk.css ]; then
    echo -e "${GREEN}✓${NC} GTK 3 CSS overrides exist"
    echo "  → $(wc -l < ~/.config/gtk-3.0/gtk.css) lines"
else
    echo -e "${YELLOW}⚠${NC} No GTK 3 CSS overrides"
fi

if [ -f ~/.config/gtk-4.0/gtk.css ]; then
    echo -e "${GREEN}✓${NC} GTK 4 CSS overrides exist"
    echo "  → $(wc -l < ~/.config/gtk-4.0/gtk.css) lines"
else
    echo -e "${YELLOW}⚠${NC} No GTK 4 CSS overrides"
fi

echo ""

# Test 6: Sample of compiled CSS
echo "Test 6: Sample of compiled CSS:"
echo "─────────────────────────────────"
head -50 "$THEME_PATH/share/themes/Signal/gtk-3.0/gtk.css" | grep -E "@define-color|/\*" | head -15
echo "─────────────────────────────────"

echo ""

echo -e "${GREEN}All tests passed!${NC}"
echo ""
echo "To visually test the theme, run:"
echo "  thunar &"
echo ""
echo "Theme location: $THEME_PATH/share/themes/Signal/"
