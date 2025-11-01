#!/usr/bin/env bash
# Quick WireGuard status check for qBittorrent VPN namespace
# Run as root: sudo bash check-wg.sh

NAMESPACE="qbt"
IFACE="qbt0"

# WireGuard tools path (from qbt-up script)
WG_PATH="/nix/store/30ymxnyg9zhvyr86rwa5h8s4phi6kxyv-wireguard-tools-1.0.20250521/bin/wg"

echo "=== WireGuard Status ==="
echo ""

# Check if wg command exists
if [ ! -f "$WG_PATH" ]; then
    echo "Error: WireGuard tools not found at: $WG_PATH"
    echo ""
    echo "Trying to find alternative path..."
    WG_PATH=$(find /nix/store -name "wg" -type f 2>/dev/null | grep wireguard | head -1)
    if [ -z "$WG_PATH" ]; then
        echo "Error: Could not find wg command"
        exit 1
    fi
    echo "Found at: $WG_PATH"
fi

# Check WireGuard status
echo "Running: ip netns exec $NAMESPACE $WG_PATH show $IFACE"
echo ""
ip netns exec "$NAMESPACE" "$WG_PATH" show "$IFACE"
echo ""

echo "=== What to Look For ==="
echo "✓ 'latest handshake: X seconds ago' = WireGuard is connected"
echo "✗ No handshake shown = WireGuard is NOT connected"
echo ""
echo "If no handshake, try:"
echo "  sudo systemctl restart generate-qbt-wg-config.service"
echo "  sudo systemctl restart qbt.service"
