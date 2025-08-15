#!/usr/bin/env bash

echo "=== CURSOR VERSION COMPARISON ==="
echo ""

# Current cursor info
CURRENT_CURSOR=$(which cursor)
NEW_CURSOR="/nix/store/hah9f69vhd8kg4c5y4zcikxm4pxpimz2-cursor-1.4.5/bin/cursor"

echo "📍 CURRENT CURSOR:"
echo "   Path: $CURRENT_CURSOR"
echo "   Type: $(file "$CURRENT_CURSOR" 2>/dev/null || echo "Binary executable")"
echo ""

echo "📍 NEW CURSOR:"
echo "   Path: $NEW_CURSOR"
echo "   Type: $(file "$NEW_CURSOR" 2>/dev/null || echo "Shell script wrapper")"
echo ""

echo "=== WRAPPER CONTENT COMPARISON ==="
echo ""

echo "🔍 CURRENT CURSOR CONTENT (first 200 chars):"
if [[ -f "$CURRENT_CURSOR" ]]; then
    if file "$CURRENT_CURSOR" | grep -q "text"; then
        head -10 "$CURRENT_CURSOR"
    else
        echo "   [Binary file - no wrapper script]"
        strings "$CURRENT_CURSOR" | head -5 | sed 's/^/   /'
    fi
else
    echo "   [Not found]"
fi

echo ""
echo "🔍 NEW CURSOR WRAPPER CONTENT:"
echo "   $(cat "$NEW_CURSOR")"
echo ""

echo "=== ENVIRONMENT VARIABLE TEST ==="
echo ""

echo "🧪 TESTING CURRENT CURSOR ENVIRONMENT:"
if [[ -x "$CURRENT_CURSOR" ]]; then
    # Launch current cursor in background and check its environment
    "$CURRENT_CURSOR" --version &
    CURRENT_PID=$!
    sleep 2
    if kill -0 $CURRENT_PID 2>/dev/null; then
        echo "   Current cursor environment variables:"
        cat /proc/$CURRENT_PID/environ | tr '\0' '\n' | grep -E "(OZONE|WAYLAND|GTK|ELECTRON)" | sed 's/^/   /' || echo "   [No Wayland-specific env vars found]"
        kill $CURRENT_PID 2>/dev/null
    else
        echo "   [Could not check environment - process exited quickly]"
    fi
else
    echo "   [Current cursor not executable]"
fi

echo ""
echo "🧪 TESTING NEW CURSOR ENVIRONMENT:"
echo "   New cursor will have these environment variables:"
grep "export" "$NEW_CURSOR" | sed 's/^/   /'

echo ""
echo "=== COMMAND LINE ARGUMENTS COMPARISON ==="
echo ""

echo "🚀 CURRENT CURSOR LAUNCH COMMAND:"
if [[ -x "$CURRENT_CURSOR" ]]; then
    echo "   Direct binary execution (no wrapper flags)"
else
    echo "   [Not available]"
fi

echo ""
echo "🚀 NEW CURSOR LAUNCH COMMAND:"
echo "   Wrapper adds: --ozone-platform-hint=auto"
echo "   Plus environment variables: NIXOS_OZONE_WL=1, ELECTRON_OZONE_PLATFORM_HINT=auto, GTK_USE_PORTAL=1"

echo ""
echo "=== WAYLAND OPTIMIZATION SUMMARY ==="
echo ""
echo "❌ CURRENT VERSION:"
echo "   - Raw AppImage binary"
echo "   - No Wayland optimizations"
echo "   - Runs in X11 compatibility mode on Wayland"
echo "   - No environment variable setup"
echo ""
echo "✅ NEW VERSION:"
echo "   - Properly wrapped with makeWrapper"
echo "   - Wayland-native mode enabled (NIXOS_OZONE_WL=1)"
echo "   - Auto-detection of best platform (ELECTRON_OZONE_PLATFORM_HINT=auto)"
echo "   - Portal integration for better desktop integration (GTK_USE_PORTAL=1)"
echo "   - Ozone platform hints for optimal rendering"
echo ""
echo "🎯 EXPECTED BENEFITS:"
echo "   - Better performance on Wayland compositors"
echo "   - Native Wayland features (proper scaling, clipboard, etc.)"
echo "   - Improved file dialog integration via portals"
echo "   - More responsive UI rendering"
echo ""



