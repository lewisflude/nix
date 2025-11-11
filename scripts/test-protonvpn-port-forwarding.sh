#!/usr/bin/env bash
# Test if ProtonVPN port forwarding is working and find the forwarded port

set -euo pipefail

NAMESPACE="${1:-qbittor}"
TEST_PORT="${2:-6881}"

echo "Testing ProtonVPN Port Forwarding"
echo "=================================="
echo "Namespace: $NAMESPACE"
echo "Testing port: $TEST_PORT"
echo ""

# Get external IP
echo "1. Getting external IP via VPN..."
EXTERNAL_IP=$(sudo ip netns exec "$NAMESPACE" curl -s --max-time 10 https://ipv4.icanhazip.com 2>/dev/null || echo "")

if [ -z "$EXTERNAL_IP" ]; then
    echo "   ? Could not determine external IP (VPN may not be connected)"
    exit 1
fi

echo "   ? External IP: $EXTERNAL_IP"
echo ""

# Test if port is open using external service
echo "2. Testing if port $TEST_PORT is accessible from internet..."
echo "   (This may take a few seconds...)"

# Try multiple port check services
PORT_OPEN=false

# Method 1: Try yougetsignal API
RESULT=$(curl -s --max-time 10 "https://www.yougetsignal.com/tools/port-scanner/port-scanner.php" \
    -d "remoteAddress=$EXTERNAL_IP&portNumber=$TEST_PORT" 2>/dev/null || echo "")

if echo "$RESULT" | grep -qi "open\|success"; then
    PORT_OPEN=true
    echo "   ? Port $TEST_PORT appears to be OPEN"
elif echo "$RESULT" | grep -qi "closed\|fail"; then
    echo "   ? Port $TEST_PORT appears to be CLOSED"
else
    echo "   ? Could not determine port status automatically"
    echo ""
    echo "   Please test manually:"
    echo "   Visit: https://www.yougetsignal.com/tools/open-ports/"
    echo "   Enter IP: $EXTERNAL_IP"
    echo "   Enter Port: $TEST_PORT"
fi

echo ""
echo "3. Recommendations:"
echo ""

if [ "$PORT_OPEN" = true ]; then
    echo "   ? Port $TEST_PORT is open!"
    echo "   ? If qBittorrent is still not seeding, check:"
    echo "     1. qBittorrent is listening on port $TEST_PORT"
    echo "     2. Firewall rules in VPN namespace allow port $TEST_PORT"
    echo "     3. qBittorrent settings (max uploads, upload limits, etc.)"
else
    echo "   ? Port $TEST_PORT is not open"
    echo ""
    echo "   This means ProtonVPN is likely forwarding a DIFFERENT port."
    echo ""
    echo "   Next steps:"
    echo "   1. Try to find the forwarded port:"
    echo "      ./scripts/get-protonvpn-forwarded-port.sh"
    echo ""
    echo "   2. Or test other common ports:"
    for port in 6882 6883 6884 6885 49152 49153 49154; do
        echo "      ./scripts/test-protonvpn-port-forwarding.sh $NAMESPACE $port"
    done
    echo ""
    echo "   3. Once you find the correct port, update qBittorrent:"
    echo "      ./scripts/update-qbittorrent-protonvpn-port.sh <FOUND_PORT>"
fi

echo ""
echo "4. Current qBittorrent torrenting port check:"
# Check specifically for torrenting ports on VPN interface (not WebUI port 8080)
QB_TORRENT_PORT=$(sudo ip netns exec "$NAMESPACE" ss -tuln 2>/dev/null | grep qbittor0 | grep -E ":(6881|6882|6883|6884|6885|49152|49153|49154|49155|49156|49157|49158|49159|49160)" | grep -v ":8080" | grep -oP ':\K\d+' | head -1 || echo "unknown")

if [ "$QB_TORRENT_PORT" = "$TEST_PORT" ]; then
    echo "   ? qBittorrent is listening on port $TEST_PORT (torrenting on VPN interface)"
elif [ "$QB_TORRENT_PORT" != "unknown" ] && [ -n "$QB_TORRENT_PORT" ]; then
    echo "   ? qBittorrent is listening on port: $QB_TORRENT_PORT (torrenting)"
    echo "   ? Testing port: $TEST_PORT"
    if [ "$QB_TORRENT_PORT" != "$TEST_PORT" ]; then
        echo "   ? Port mismatch: qBittorrent uses $QB_TORRENT_PORT, but testing $TEST_PORT"
        echo "   ? If $TEST_PORT is open, update qBittorrent: ./scripts/update-qbittorrent-protonvpn-port.sh $TEST_PORT"
    fi
else
    echo "   ? Could not determine qBittorrent torrenting port"
    echo "   ? qBittorrent may not be running or not listening on common ports"
fi
