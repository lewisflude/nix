#!/usr/bin/env bash
# Check Janitorr status and configuration

set -euo pipefail

echo "=== Janitorr Status Check ==="
echo ""

# Check if container is running
echo "Container Status:"
if podman ps --format "{{.Names}}" | grep -q "^janitorr$"; then
    echo "✓ Janitorr container is running"
    podman ps --filter "name=janitorr" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo "✗ Janitorr container is NOT running"
    echo ""
    echo "Checking if container exists:"
    if podman ps -a --format "{{.Names}}" | grep -q "^janitorr$"; then
        echo "  Container exists but is stopped"
        podman ps -a --filter "name=janitorr" --format "table {{.Names}}\t{{.Status}}"
    else
        echo "  Container does not exist"
    fi
fi

echo ""
echo "=== Configuration Check ==="
CONFIG_FILE="/var/lib/containers/containers-supplemental/janitorr/config/application.yml"
if [ -f "$CONFIG_FILE" ]; then
    echo "✓ Config file exists: $CONFIG_FILE"
    echo ""
    echo "Key Settings:"

    # Check dry-run mode
    if grep -q "dry-run: true" "$CONFIG_FILE"; then
        echo "⚠️  DRY-RUN MODE ENABLED - Janitorr will NOT delete anything!"
        echo "   It will only simulate deletions. Disable dry-run to actually clean up."
    elif grep -q "dry-run: false" "$CONFIG_FILE"; then
        echo "✓ Dry-run mode DISABLED - Janitorr will actually delete files"
    else
        echo "? Could not determine dry-run status"
    fi

    echo ""
    echo "Media Deletion Settings:"
    grep -A 10 "media-deletion:" "$CONFIG_FILE" | head -15 || echo "  Not found"

    echo ""
    echo "Free Space Check Directory:"
    grep "free-space-check-dir:" "$CONFIG_FILE" || echo "  Not found"

    echo ""
    echo "Minimum Free Disk Percent (tag-based deletion):"
    grep "minimum-free-disk-percent:" "$CONFIG_FILE" || echo "  Not found"
else
    echo "✗ Config file not found: $CONFIG_FILE"
fi

echo ""
echo "=== Recent Logs (last 50 lines) ==="
LOG_FILE="/var/lib/containers/containers-supplemental/janitorr/logs/janitorr.log"
if [ -f "$LOG_FILE" ]; then
    echo "Log file: $LOG_FILE"
    tail -50 "$LOG_FILE" 2>/dev/null || echo "  Could not read log file"
else
    echo "Log file not found: $LOG_FILE"
    echo ""
    echo "Checking container logs:"
    podman logs janitorr --tail 50 2>/dev/null || echo "  Could not retrieve container logs"
fi

echo ""
echo "=== Recommendations ==="
if podman ps --format "{{.Names}}" | grep -q "^janitorr$"; then
    if grep -q "dry-run: true" "$CONFIG_FILE" 2>/dev/null; then
        echo "⚠️  Janitorr is running but in DRY-RUN mode"
        echo "   To enable actual cleanup, edit the config and set dry-run: false"
        echo "   Config location: $CONFIG_FILE"
        echo "   Or update hosts/jupiter/default.nix and rebuild"
    else
        echo "✓ Janitorr appears to be configured correctly"
        echo "   Check logs above to see what actions it's taking"
    fi
else
    echo "✗ Janitorr container is not running"
    echo "   Start it with: sudo systemctl start podman-janitorr"
    echo "   Check status: sudo systemctl status podman-janitorr"
fi
