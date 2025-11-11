#!/usr/bin/env bash
# Scan common ports to find which one ProtonVPN is forwarding
# This helps when automatic detection doesn't work

set -euo pipefail

NAMESPACE="${1:-qbittor}"

echo "Finding ProtonVPN Forwarded Port"
echo "================================="
echo "Namespace: $NAMESPACE"
echo ""

# Get external IP
EXTERNAL_IP=$(sudo ip netns exec "$NAMESPACE" curl -s --max-time 10 https://ipv4.icanhazip.com 2>/dev/null || echo "")

if [ -z "$EXTERNAL_IP" ]; then
    echo "? Could not determine external IP (VPN may not be connected)"
    exit 1
fi

echo "External IP: $EXTERNAL_IP"
echo ""
echo "Testing common ProtonVPN forwarded ports..."
echo "(This will take a while - ProtonVPN often uses ports 49152-65535)"
echo ""

# Common ports ProtonVPN uses
PORTS_TO_TEST=(
    6881 6882 6883 6884 6885 6886 6887 6888 6889 6890
    49152 49153 49154 49155 49156 49157 49158 49159 49160
    50000 50001 50002 50003 50004
)

FOUND_PORT=""

for port in "${PORTS_TO_TEST[@]}"; do
    echo -n "Testing port $port... "

    # Use a simple TCP connection test
    # Note: This is a basic test - external port checkers are more reliable
    RESULT=$(timeout 3 bash -c "echo > /dev/tcp/$EXTERNAL_IP/$port" 2>&1 || echo "closed")

    if [ "$RESULT" = "" ]; then
        echo "? OPEN!"
        FOUND_PORT="$port"
        break
    else
        echo "closed"
    fi
done

echo ""
if [ -n "$FOUND_PORT" ]; then
    echo "? Found open port: $FOUND_PORT"
    echo ""
    echo "Next step: Update qBittorrent to use this port:"
    echo "  ./scripts/update-qbittorrent-protonvpn-port.sh $FOUND_PORT"
else
    echo "? Could not find open port in common range"
    echo ""
    echo "ProtonVPN may be forwarding a port outside the tested range."
    echo ""
    echo "Options:"
    echo "1. Test manually: https://www.yougetsignal.com/tools/open-ports/"
    echo "   Enter IP: $EXTERNAL_IP"
    echo "   Try ports: 49152-65535 (common ProtonVPN range)"
    echo ""
    echo "2. Check ProtonVPN account:"
    echo "   https://account.protonvpn.com ? Downloads ? WireGuard"
    echo ""
    echo "3. Use ProtonVPN app temporarily to see the forwarded port"
    echo ""
    echo "4. Install natpmpc and try automatic detection:"
    echo "   nix-shell -p natpmpc"
    echo "   ./scripts/get-protonvpn-forwarded-port.sh"
fi
