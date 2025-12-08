#!/usr/bin/env bash
#
# Debug GTK Rendering Issues
# Helps identify CSS conflicts causing rendering artifacts like backgrounds spilling beyond borders
#

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== GTK Rendering Debug Tool ===${NC}"
echo ""

# Step 1: Check current GTK CSS files
echo -e "${YELLOW}Step 1: Checking active CSS files...${NC}"
echo ""

if [ -f ~/.config/gtk-3.0/gtk.css ]; then
    echo -e "${GREEN}✓${NC} Found GTK 3 CSS overrides:"
    echo "  Path: ~/.config/gtk-3.0/gtk.css"
    echo "  Lines: $(wc -l < ~/.config/gtk-3.0/gtk.css)"

    # Check for common rendering issues
    echo ""
    echo "Checking for potential issues:"

    if grep -q "box-shadow" ~/.config/gtk-3.0/gtk.css; then
        echo -e "${YELLOW}⚠${NC} Found box-shadow (can cause background overflow)"
        grep -n "box-shadow" ~/.config/gtk-3.0/gtk.css | head -5
    fi

    if grep -q "border-radius" ~/.config/gtk-3.0/gtk.css; then
        echo -e "${YELLOW}⚠${NC} Found border-radius (check padding/border interaction)"
        grep -n "border-radius" ~/.config/gtk-3.0/gtk.css | head -5
    fi

    # Check popover/menu styling
    echo ""
    echo "Context menu/popover styling:"
    grep -A 10 "popover\|menu\|\.context-menu" ~/.config/gtk-3.0/gtk.css | head -20
fi

echo ""
echo -e "${YELLOW}Step 2: Inspecting compiled theme CSS...${NC}"
echo ""

# Find theme in Nix store
THEME_PATH=$(nix path-info ~/.nix-profile 2>/dev/null | xargs nix-store -qR 2>/dev/null | grep signal-theme | head -1)
if [ -z "$THEME_PATH" ]; then
    THEME_PATH=$(find /nix/store -maxdepth 1 -name "*signal-theme*" -type d 2>/dev/null | sort | tail -1)
fi

if [ -n "$THEME_PATH" ] && [ -f "$THEME_PATH/share/themes/Signal/gtk-3.0/gtk.css" ]; then
    echo -e "${GREEN}✓${NC} Found compiled theme: $THEME_PATH"
    echo ""

    # Check for CSS that might conflict
    echo "Checking compiled theme for rendering issues:"

    if grep -q "box-shadow" "$THEME_PATH/share/themes/Signal/gtk-3.0/gtk.css"; then
        echo -e "${YELLOW}⚠${NC} Base theme uses box-shadow:"
        grep -n "box-shadow" "$THEME_PATH/share/themes/Signal/gtk-3.0/gtk.css" | grep -E "popover|menu|context" | head -5
    fi

    if grep -q "outline" "$THEME_PATH/share/themes/Signal/gtk-3.0/gtk.css"; then
        echo -e "${YELLOW}⚠${NC} Base theme uses outline:"
        grep -n "outline" "$THEME_PATH/share/themes/Signal/gtk-3.0/gtk.css" | grep -E "popover|menu|context" | head -5
    fi
fi

echo ""
echo -e "${YELLOW}Step 3: Live GTK Inspector${NC}"
echo ""
echo "To inspect rendering in real-time:"
echo -e "${GREEN}1.${NC} Enable GTK Inspector:"
echo "   GTK_DEBUG=interactive <application>"
echo ""
echo -e "${GREEN}2.${NC} Examples:"
echo "   GTK_DEBUG=interactive thunar"
echo "   GTK_DEBUG=interactive nautilus"
echo "   GTK_DEBUG=interactive gedit"
echo ""
echo -e "${GREEN}3.${NC} In the Inspector:"
echo "   - Right-click any element with the picker"
echo "   - Check the 'CSS Nodes' tab"
echo "   - Look for conflicting rules"
echo "   - Check computed 'box-shadow', 'border', 'padding' values"
echo ""

echo -e "${YELLOW}Step 4: Test specific elements${NC}"
echo ""
echo "Create a test CSS file to isolate the issue:"
echo ""
cat << 'EOF'
# Test file: ~/.config/gtk-3.0/test.css
# Add this to your gtk.css temporarily to debug

/* Disable all box-shadows on popovers/menus */
popover,
.popover,
menu,
.menu {
    box-shadow: none !important;
}

/* Add visible debug border */
popover,
.popover,
menu,
.menu {
    border: 2px solid red !important;
    background-clip: padding-box !important;
}

/* Ensure background doesn't extend beyond border */
popover.background,
menu.background {
    background-clip: border-box !important;
}
EOF

echo ""
echo -e "${YELLOW}Step 5: Common fixes${NC}"
echo ""
echo "Common CSS properties that fix background overflow:"
echo ""
echo "1. Remove or reduce box-shadow:"
echo "   box-shadow: none; /* or make it smaller */"
echo ""
echo "2. Use background-clip:"
echo "   background-clip: padding-box; /* or border-box */"
echo ""
echo "3. Ensure proper border radius on all layers:"
echo "   border-radius: 8px;"
echo "   overflow: hidden; /* clips content to border */"
echo ""
echo "4. Check padding vs border interaction:"
echo "   padding: 4px;"
echo "   border: 1px solid ...;"
echo "   /* Make sure they're consistent */"
echo ""

echo -e "${YELLOW}Step 6: Screenshot comparison${NC}"
echo ""
echo "To document the issue:"
echo "1. Take a screenshot showing the problem"
echo "2. Use 'scrot' or 'flameshot' to capture"
echo "3. Compare before/after CSS changes"
echo ""

echo -e "${GREEN}Debug session complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Run GTK_DEBUG=interactive on an app"
echo "2. Right-click the problematic element"
echo "3. Check CSS in the Inspector"
echo "4. Try the test CSS fixes above"
echo ""
