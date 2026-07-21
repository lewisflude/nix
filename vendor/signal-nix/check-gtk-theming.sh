#!/usr/bin/env bash
# Diagnostic script to check GTK theming status

set -euo pipefail

echo "=== GTK Theming Diagnostic ==="
echo ""

# 1. Check CSS files exist and have Signal colors
echo "1. Checking CSS files..."
if [[ -f ~/.config/gtk-4.0/gtk.css ]]; then
    echo "   ✓ GTK4 CSS exists"
    if grep -q "blue_3\|green_3" ~/.config/gtk-4.0/gtk.css 2>/dev/null; then
        echo "   ✓ Contains Signal color definitions"
        BLUE_3=$(grep "blue_3" ~/.config/gtk-4.0/gtk.css | head -1 | grep -oP '#[0-9a-fA-F]{6}')
        echo "   → blue_3 = $BLUE_3"
    else
        echo "   ✗ Missing Signal color definitions"
    fi
else
    echo "   ✗ GTK4 CSS file missing"
fi

if [[ -f ~/.config/gtk-3.0/gtk.css ]]; then
    echo "   ✓ GTK3 CSS exists"
else
    echo "   ✗ GTK3 CSS file missing"
fi

echo ""

# 2. Check settings.ini files
echo "2. Checking GTK settings..."
if [[ -f ~/.config/gtk-4.0/settings.ini ]]; then
    echo "   GTK4 settings.ini:"
    cat ~/.config/gtk-4.0/settings.ini | grep -E "gtk-theme-name|gtk-application-prefer-dark-theme" || echo "   (no theme settings found)"
else
    echo "   ✗ GTK4 settings.ini missing"
fi

if [[ -f ~/.config/gtk-3.0/settings.ini ]]; then
    echo "   GTK3 settings.ini:"
    cat ~/.config/gtk-3.0/settings.ini | grep -E "gtk-theme-name|gtk-application-prefer-dark-theme" || echo "   (no theme settings found)"
else
    echo "   ✗ GTK3 settings.ini missing"
fi

echo ""

# 3. Check if gsettings is available (optional)
echo "3. Checking gsettings (optional)..."
if command -v gsettings &>/dev/null; then
    echo "   ✓ gsettings available"
    GTK_THEME=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "not set")
    COLOR_SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "not set")
    echo "   → gtk-theme: $GTK_THEME"
    echo "   → color-scheme: $COLOR_SCHEME"
else
    echo "   (gsettings not available - this is OK if not using GNOME)"
fi

echo ""

# 4. Check CSS file content structure
echo "4. Checking CSS structure..."
if [[ -f ~/.config/gtk-4.0/gtk.css ]]; then
    if grep -q ":root" ~/.config/gtk-4.0/gtk.css; then
        echo "   ✓ Contains :root block (GTK4 CSS custom properties)"
    else
        echo "   ✗ Missing :root block"
    fi
    
    if grep -q "@define-color" ~/.config/gtk-4.0/gtk.css; then
        echo "   ✓ Contains @define-color directives"
        DEFINE_COUNT=$(grep -c "@define-color" ~/.config/gtk-4.0/gtk.css || echo "0")
        echo "   → Found $DEFINE_COUNT @define-color statements"
    else
        echo "   ✗ Missing @define-color directives"
    fi
fi

echo ""
echo "=== Summary ==="
echo ""
echo "If CSS files exist and contain Signal colors, but GTK Inspector shows"
echo "default colors, this is likely an Inspector issue, not a theming issue."
echo ""
echo "To verify:"
echo "  1. Does ironbar itself visually show Signal colors correctly?"
echo "  2. Do other GTK4 apps (like Nautilus) show Signal colors?"
echo "  3. If yes to both, GTK Inspector is just showing wrong info."
echo ""
echo "If ironbar itself shows wrong colors, try:"
echo "  - Restart ironbar: systemctl --user restart ironbar"
echo "  - Reload ironbar: ironbar reload"
echo "  - Check ironbar logs: journalctl --user -u ironbar -f"
