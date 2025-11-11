#!/usr/bin/env bash
# Helper script to detect ProtonVPN forwarded port
# Works with WireGuard connections using NAT-PMP

set -euo pipefail

NAMESPACE="${1:-qbittor}"
VPN_GATEWAY="${2:-10.2.0.1}"  # Default ProtonVPN gateway

echo "Attempting to detect ProtonVPN forwarded port..."
echo "Namespace: $NAMESPACE"
echo "VPN Gateway: $VPN_GATEWAY"
echo ""

# Method 1: Try NAT-PMP if available
if command -v natpmpc >/dev/null 2>&1; then
    echo "Trying NAT-PMP detection..."
    RESULT=$(sudo ip netns exec "$NAMESPACE" natpmpc -g "$VPN_GATEWAY" -a 0 0 0 2>&1 || echo "")

    if echo "$RESULT" | grep -q "external port"; then
        PORT=$(echo "$RESULT" | grep -oP 'external port \K[0-9]+' || echo "")
        if [ -n "$PORT" ] && [ "$PORT" != "0" ]; then
            echo "? Detected forwarded port via NAT-PMP: $PORT"
            echo "$PORT"
            exit 0
        fi
    fi
    echo "NAT-PMP did not return a valid port"
else
    echo "natpmpc not found. Install it with: nix-shell -p natpmpc"
fi

echo ""
echo "Could not automatically detect port."
echo ""
echo "Manual detection options:"
echo ""
echo "1. Check external port accessibility:"
EXTERNAL_IP=$(sudo ip netns exec "$NAMESPACE" curl -s --max-time 5 https://ipv4.icanhazip.com 2>/dev/null || echo "unknown")
if [ "$EXTERNAL_IP" != "unknown" ]; then
    echo "   External IP: $EXTERNAL_IP"
    echo "   Test ports: https://www.yougetsignal.com/tools/open-ports/"
    echo "   Try common ports: 6881, 6882, 6883, etc."
else
    echo "   Could not determine external IP"
fi

echo ""
echo "2. Check ProtonVPN account:"
echo "   https://account.protonvpn.com ? Downloads ? WireGuard"
echo "   (Port may be shown if port forwarding is active)"

echo ""
echo "3. Check qBittorrent current port:"
echo "   Visit WebUI and check: Connection ? Port used for incoming connections"

exit 1
