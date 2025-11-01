#!/usr/bin/env bash
# Helper script to check WireGuard status in qBittorrent namespace
# Run as root: sudo bash check-wg-status.sh

set -euo pipefail

NAMESPACE="qbt"
IFACE="qbt0"

echo "=== Finding WireGuard Tools ==="

# Try to find wg command
WG_PATH=$(find /nix/store -name "wg" -type f 2>/dev/null | grep wireguard | head -1)

if [ -z "$WG_PATH" ]; then
    echo "Error: Could not find wg command in /nix/store"
    echo ""
    echo "Trying alternative method..."
    # Try the path from the qbt-up script
    WG_PATH="/nix/store/30ymxnyg9zhvyr86rwa5h8s4phi6kxyv-wireguard-tools-1.0.20250521/bin/wg"
    if [ ! -f "$WG_PATH" ]; then
        echo "Error: WireGuard tools not found at expected path"
        echo ""
        echo "Manual search:"
        find /nix/store -name "wg" -type f 2>/dev/null | head -5
        exit 1
    fi
fi

echo "Found WireGuard tools at: $WG_PATH"
echo ""

# Check if namespace exists
if ! ip netns list | grep -q "^${NAMESPACE}"; then
    echo "Error: Namespace '${NAMESPACE}' does not exist"
    exit 1
fi

# Check if interface exists
if ! ip netns exec "${NAMESPACE}" ip link show "${IFACE}" >/dev/null 2>&1; then
    echo "Error: Interface '${IFACE}' does not exist in namespace"
    exit 1
fi

echo "=== WireGuard Status ==="
echo ""
ip netns exec "${NAMESPACE}" "$WG_PATH" show "${IFACE}"
echo ""

echo "=== Interface Status ==="
ip netns exec "${NAMESPACE}" ip link show "${IFACE}"
echo ""

echo "=== Routing Table ==="
ip netns exec "${NAMESPACE}" ip route show
echo ""

echo "=== IP Addresses ==="
ip netns exec "${NAMESPACE}" ip addr show "${IFACE}"
echo ""

echo "=== Testing Connectivity ==="
echo "Testing VPN DNS (10.2.0.1)..."
if ip netns exec "${NAMESPACE}" ping -c 2 -W 2 10.2.0.1 >/dev/null 2>&1; then
    echo "✓ Can reach VPN DNS"
else
    echo "✗ Cannot reach VPN DNS"
fi

echo "Testing external IP (8.8.8.8)..."
if ip netns exec "${NAMESPACE}" ping -c 2 -W 2 8.8.8.8 >/dev/null 2>&1; then
    echo "✓ Can reach external IP"
else
    echo "✗ Cannot reach external IP"
fi

echo ""
echo "=== Summary ==="
echo "To check WireGuard handshake, look for 'latest handshake' in the output above."
echo "If no handshake is shown, WireGuard is not connected."
