#!/usr/bin/env bash
# Test if IPv6 is working in WireGuard VPN namespace
# This helps decide whether to keep ::/0 in AllowedIPs

set -euo pipefail

echo "=== WireGuard IPv6 Connectivity Test ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

NAMESPACE="qbittor"
INTERFACE="qbittor0"
IPV6_WORKS=false

# 1. Check if namespace exists
echo "1. Checking VPN namespace..."
if ! ip netns list | grep -q "^$NAMESPACE"; then
    echo -e "   ${RED}?${NC} Namespace '$NAMESPACE' not found"
    echo -e "   ${YELLOW}Note:${NC} VPN may not be enabled. Start qBittorrent VPN first."
    exit 1
fi
echo -e "   ${GREEN}?${NC} Namespace exists"

# 2. Check if interface exists
echo ""
echo "2. Checking WireGuard interface..."
if ! ip netns exec "$NAMESPACE" ip link show "$INTERFACE" >/dev/null 2>&1; then
    echo -e "   ${RED}?${NC} Interface '$INTERFACE' not found in namespace"
    exit 1
fi
echo -e "   ${GREEN}?${NC} Interface exists"

# 3. Check for IPv6 addresses
echo ""
echo "3. Checking for IPv6 addresses on interface..."
IPv6_ADDRS=$(ip netns exec "$NAMESPACE" ip -6 addr show "$INTERFACE" 2>/dev/null | grep "inet6" | wc -l || echo "0")

if [ "$IPv6_ADDRS" -eq 0 ]; then
    echo -e "   ${RED}?${NC} No IPv6 addresses found"
    echo -e "   ${BLUE}Info:${NC} This means IPv6 is not configured on the VPN interface"
else
    echo -e "   ${GREEN}?${NC} Found $IPv6_ADDRS IPv6 address(es):"
    ip netns exec "$NAMESPACE" ip -6 addr show "$INTERFACE" 2>/dev/null | grep "inet6" | sed 's/^/      /' || true
fi

# 4. Check IPv6 routes
echo ""
echo "4. Checking IPv6 routes..."
IPv6_ROUTES=$(ip netns exec "$NAMESPACE" ip -6 route show 2>/dev/null | wc -l || echo "0")

if [ "$IPv6_ROUTES" -eq 0 ]; then
    echo -e "   ${RED}?${NC} No IPv6 routes found"
else
    echo -e "   ${GREEN}?${NC} Found $IPv6_ROUTES IPv6 route(s):"
    ip netns exec "$NAMESPACE" ip -6 route show 2>/dev/null | head -5 | sed 's/^/      /' || true
    if [ "$IPv6_ROUTES" -gt 5 ]; then
        echo "      ... (showing first 5)"
    fi
fi

# 5. Test IPv6 connectivity
echo ""
echo "5. Testing IPv6 connectivity..."

# Test with Google DNS IPv6 (use ping -6 instead of ping6 on modern systems)
if ip netns exec "$NAMESPACE" ping -6 -c 2 -W 3 2001:4860:4860::8888 >/dev/null 2>&1; then
    echo -e "   ${GREEN}?${NC} IPv6 connectivity works (tested with Google DNS)"
    IPV6_WORKS=true
else
    echo -e "   ${RED}?${NC} IPv6 connectivity test failed"
    echo -e "   ${BLUE}Info:${NC} Cannot reach IPv6 addresses through VPN"
fi

# Test with Cloudflare DNS IPv6 as backup
if [ "$IPV6_WORKS" = false ]; then
    if ip netns exec "$NAMESPACE" ping -6 -c 2 -W 3 2606:4700:4700::1111 >/dev/null 2>&1; then
        echo -e "   ${GREEN}?${NC} IPv6 connectivity works (tested with Cloudflare DNS)"
        IPV6_WORKS=true
    fi
fi

# 6. Check WireGuard peer status
echo ""
echo "6. Checking WireGuard connection status..."
WG_STATUS=$(ip netns exec "$NAMESPACE" wg show "$INTERFACE" 2>/dev/null || echo "")
if echo "$WG_STATUS" | grep -q "latest handshake"; then
    echo -e "   ${GREEN}?${NC} WireGuard is connected"
    echo "$WG_STATUS" | grep "latest handshake" | sed 's/^/      /' || true
else
    echo -e "   ${YELLOW}?${NC} Could not determine WireGuard status"
fi

# 7. Check if IPv6 is in AllowedIPs
echo ""
echo "7. Checking current WireGuard configuration..."
if echo "$WG_STATUS" | grep -q "allowed ips.*::/0"; then
    echo -e "   ${BLUE}?${NC} IPv6 (::/0) is currently in AllowedIPs"
else
    echo -e "   ${BLUE}?${NC} IPv6 (::/0) is NOT in AllowedIPs"
fi

# Summary and Recommendation
echo ""
echo "=== Summary and Recommendation ==="
echo ""

if [ "$IPV6_WORKS" = true ]; then
    echo -e "${GREEN}? IPv6 IS WORKING${NC}"
    echo ""
    echo "Recommendation: ${GREEN}KEEP ::/0 in AllowedIPs${NC}"
    echo ""
    echo "Reasons:"
    echo "  ? IPv6 connectivity is functional"
    echo "  ? More peer connections possible (peers with IPv6)"
    echo "  ? Better connectivity in some cases"
    echo "  ? Future-proofing"
    echo ""
    echo "Use this config:"
    echo "  AllowedIPs = 0.0.0.0/0, ::/0"
    exit 0
else
    echo -e "${RED}? IPv6 IS NOT WORKING${NC}"
    echo ""
    echo "Recommendation: ${YELLOW}REMOVE ::/0 from AllowedIPs${NC}"
    echo ""
    echo "Reasons:"
    echo "  ? IPv6 is not available through this VPN server"
    echo "  ? Keeping ::/0 adds overhead without benefit"
    echo "  ? Faster connection establishment without IPv6"
    echo "  ? Cleaner configuration"
    echo ""
    echo "Use this config:"
    echo "  AllowedIPs = 0.0.0.0/0"
    echo ""
    echo -e "${BLUE}Note:${NC} Most torrent traffic is IPv4 anyway, so removing ::/0"
    echo "       won't significantly impact peer connectivity."
    exit 1
fi
