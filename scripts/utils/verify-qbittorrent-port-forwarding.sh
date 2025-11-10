#!/usr/bin/env bash
# Verify qBittorrent VPN port forwarding status
# This script checks if port forwarding is working correctly

set -euo pipefail

echo "=== qBittorrent VPN Port Forwarding Verification ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# 1. Check port forwarding service status
echo "1. Checking port forwarding service status..."
if systemctl is-active --quiet protonvpn-port-forwarding.service; then
    echo -e "   ${GREEN}?${NC} Service is running"
else
    echo -e "   ${RED}?${NC} Service is not running"
    exit 1
fi

# 2. Get public IP and port from logs
echo ""
echo "2. Checking forwarded port from service logs..."
PUBLIC_IP=$(journalctl -u protonvpn-port-forwarding.service -n 50 --no-pager | grep "Public IP address" | tail -1 | awk '{print $NF}')
PUBLIC_PORT_TCP=$(journalctl -u protonvpn-port-forwarding.service -n 50 --no-pager | grep "Mapped public port.*TCP" | tail -1 | sed -n 's/.*Mapped public port \([0-9]*\) protocol TCP.*/\1/p')
PUBLIC_PORT_UDP=$(journalctl -u protonvpn-port-forwarding.service -n 50 --no-pager | grep "Mapped public port.*UDP" | tail -1 | sed -n 's/.*Mapped public port \([0-9]*\) protocol UDP.*/\1/p')

if [ -n "$PUBLIC_IP" ] && [ -n "$PUBLIC_PORT_TCP" ]; then
    echo -e "   ${GREEN}?${NC} Public IP: $PUBLIC_IP"
    echo -e "   ${GREEN}?${NC} Public TCP Port: $PUBLIC_PORT_TCP"
    if [ -n "$PUBLIC_PORT_UDP" ]; then
        echo -e "   ${GREEN}?${NC} Public UDP Port: $PUBLIC_PORT_UDP"
    fi
else
    echo -e "   ${RED}?${NC} Could not determine public IP/port from logs"
    exit 1
fi

# 3. Check VPN namespace
echo ""
echo "3. Checking VPN namespace..."
if ip netns list | grep -q "^qbittor "; then
    echo -e "   ${GREEN}?${NC} VPN namespace 'qbittor' exists"
else
    echo -e "   ${RED}?${NC} VPN namespace 'qbittor' not found"
    exit 1
fi

# 4. Check VPN interface
echo ""
echo "4. Checking VPN interface..."
VPN_IP=$(ip netns exec qbittor ip addr show qbittor0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1)
if [ -n "$VPN_IP" ]; then
    echo -e "   ${GREEN}?${NC} VPN interface IP: $VPN_IP"
else
    echo -e "   ${RED}?${NC} VPN interface not found or has no IP"
    exit 1
fi

# 5. Check qBittorrent is listening
echo ""
echo "5. Checking if qBittorrent is listening on port 6881..."
if ip netns exec qbittor ss -tunlp 2>/dev/null | grep -q ":6881"; then
    echo -e "   ${GREEN}?${NC} qBittorrent is listening on port 6881"
    echo "   Listening sockets:"
    ip netns exec qbittor ss -tunlp 2>/dev/null | grep ":6881" | sed 's/^/      /'
else
    echo -e "   ${RED}?${NC} qBittorrent is not listening on port 6881"
    exit 1
fi

# 6. Test connectivity from namespace to gateway
echo ""
echo "6. Testing connectivity to ProtonVPN gateway..."
if ip netns exec qbittor ping -c 1 -W 2 10.2.0.1 >/dev/null 2>&1; then
    echo -e "   ${GREEN}?${NC} Can reach ProtonVPN gateway (10.2.0.1)"
else
    echo -e "   ${YELLOW}?${NC} Cannot ping gateway (may be normal if ICMP is blocked)"
fi

# 7. Summary
echo ""
echo "=== Summary ==="
echo "Port forwarding is configured as follows:"
echo ""
echo "  Local (inside VPN namespace):"
echo "    - qBittorrent listens on: $VPN_IP:6881 (TCP & UDP)"
echo ""
echo "  Public (ProtonVPN gateway):"
echo "    - Public IP: $PUBLIC_IP"
echo "    - Public TCP Port: $PUBLIC_PORT_TCP"
if [ -n "$PUBLIC_PORT_UDP" ]; then
    echo "    - Public UDP Port: $PUBLIC_PORT_UDP"
fi
echo ""
echo "  Forwarding:"
echo "    - $PUBLIC_IP:$PUBLIC_PORT_TCP ? $VPN_IP:6881 (TCP)"
if [ -n "$PUBLIC_PORT_UDP" ]; then
    echo "    - $PUBLIC_IP:$PUBLIC_PORT_UDP ? $VPN_IP:6881 (UDP)"
fi
echo ""
echo -e "${GREEN}? Port forwarding appears to be working!${NC}"
echo ""
echo "To verify externally:"
echo "  1. Check qBittorrent WebUI: Options ? Connection ? Port forwarding status"
echo "  2. Use online port checker: https://www.yougetsignal.com/tools/open-ports/"
echo "     Check port $PUBLIC_PORT_TCP on IP $PUBLIC_IP"
echo "  3. Check active peer connections in qBittorrent (should show incoming connections)"
echo ""
