#!/usr/bin/env bash

echo "🎯 CURSOR VERSIONS - EXACT DIFFERENCES"
echo "======================================"
echo

CURRENT="/nix/store/ir3ylbkr1qcnc66c0lbha1k5qw49h944-cursor-1.4.5-extracted/usr/bin/cursor"
NEW="/nix/store/hah9f69vhd8kg4c5y4zcikxm4pxpimz2-cursor-1.4.5/bin/cursor"

echo "📋 WHAT YOU CURRENTLY HAVE:"
echo "  Path: $CURRENT"
echo "  Type: Raw Electron/AppImage binary"
echo "  Wayland: Uses X11 compatibility layer (XWayland)"
echo

echo "📋 WHAT THE FIX PROVIDES:"
echo "  Path: $NEW"
echo "  Type: Bash wrapper script"
echo "  Wayland: Native Wayland support"
echo

echo "🔬 TECHNICAL DIFFERENCES:"
echo

echo "Current cursor command line:"
echo "  $CURRENT [your-arguments]"
echo

echo "New cursor command line:"
echo "  NIXOS_OZONE_WL=1 \\"
echo "  ELECTRON_OZONE_PLATFORM_HINT=auto \\"
echo "  GTK_USE_PORTAL=1 \\"
echo "  $CURRENT --ozone-platform-hint=auto [your-arguments]"
echo

echo "🎨 VISUAL/PERFORMANCE DIFFERENCES YOU MIGHT NOTICE:"
echo

echo "❌ Current (X11 mode on Wayland):"
echo "  • Might have scaling/blur issues"
echo "  • Less smooth scrolling/animations"
echo "  • File dialogs use GTK fallbacks"
echo "  • Higher CPU usage for graphics"
echo "  • May have input lag"
echo

echo "✅ New (Native Wayland):"
echo "  • Crisp rendering at any scale"
echo "  • Smooth 60fps animations"
echo "  • Native portal file dialogs"
echo "  • Lower CPU/GPU usage"
echo "  • Better touch/gesture support"
echo

echo "🧪 QUICK TEST - Launch both and compare:"
echo

echo "Test current version:"
echo "  $CURRENT &"
echo

echo "Test new version:"
echo "  $NEW &"
echo

echo "Then compare side-by-side for:"
echo "• Scaling sharpness (if you have >100% scale)"
echo "• File dialog appearance (File > Open)"
echo "• General UI smoothness"
echo "• CPU usage in htop"



