#!/usr/bin/env bash
# Verification script for Ironbar notification badge CSS selectors
# This script helps identify the actual DOM structure of the notification widget

set -euo pipefail

echo "=== Ironbar Notification Widget CSS Selector Verification ==="
echo ""
echo "This script will help verify the CSS selectors used for notification badges."
echo ""

# Check if ironbar is running
if ! pgrep -x ironbar >/dev/null; then
    echo "⚠️  Ironbar is not currently running."
    echo "Please start ironbar first, then run this script again."
    exit 1
fi

echo "✓ Ironbar is running"
echo ""
echo "To inspect the notification widget DOM structure:"
echo ""
echo "1. Run this command in a terminal:"
echo "   GTK_DEBUG=interactive ironbar"
echo ""
echo "2. In the GTK Inspector window that appears:"
echo "   - Click the 'Object' tab at the top"
echo "   - Use the 'Pick an object' tool (crosshair icon)"
echo "   - Click on the notification icon in your ironbar"
echo ""
echo "3. Look for the CSS node structure in the left panel"
echo "   - Find the .notifications class"
echo "   - Look for child elements that contain the count/badge"
echo "   - Note the class names used (e.g., .count, .badge, .label, etc.)"
echo ""
echo "4. Current CSS assumes these selectors:"
echo "   - .notifications (parent container)"
echo "   - .notifications .count (badge element)"
echo ""
echo "If the actual selectors differ, update:"
echo "   /home/lewis/Code/signal-nix/modules/ironbar/style.css"
echo ""
echo "Common alternatives to check:"
echo "   - .notifications label"
echo "   - .notifications .badge"
echo "   - .notifications .notification-count"
echo "   - .notifications box > label"
echo ""
