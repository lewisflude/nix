#!/usr/bin/env bash
# Test script to check what colors GTK4 is actually using

echo "=== GTK4 Color Test ==="
echo ""
echo "This script checks if GTK4 applications are loading Signal colors."
echo ""

# Check if we can read the CSS file
if [[ -f ~/.config/gtk-4.0/gtk.css ]]; then
    echo "✓ CSS file exists"
    
    # Extract some key colors
    BLUE_3=$(grep -- "--blue-3:" ~/.config/gtk-4.0/gtk.css | head -1 | sed 's/.*#\([0-9a-fA-F]\{6\}\).*/\1/')
    GREEN_3=$(grep -- "--green-3:" ~/.config/gtk-4.0/gtk.css | head -1 | sed 's/.*#\([0-9a-fA-F]\{6\}\).*/\1/')
    ACCENT_BG=$(grep -- "--accent-bg-color:" ~/.config/gtk-4.0/gtk.css | head -1 | sed 's/.*#\([0-9a-fA-F]\{6\}\).*/\1/')
    
    echo "  Signal colors defined in CSS:"
    echo "    --blue-3: #${BLUE_3}"
    echo "    --green-3: #${GREEN_3}"
    echo "    --accent-bg-color: #${ACCENT_BG}"
    echo ""
    echo "If GTK Inspector shows different colors, it's likely showing"
    echo "the base Adwaita theme colors, not the CSS overrides."
    echo ""
    echo "To verify theming is working:"
    echo "  1. Visually check ironbar - does it show Signal colors?"
    echo "  2. Open Nautilus - does it show Signal colors?"
    echo "  3. If yes, theming is working - Inspector is just misleading"
else
    echo "✗ CSS file missing!"
fi
