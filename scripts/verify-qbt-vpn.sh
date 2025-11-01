#!/usr/bin/env bash
# Verify qBittorrent VPN setup and connectivity

set -u

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="qbittorrent"
WG_INTERFACE="wg-qbtvpn"
VETH_HOST="qbt-host"
VETH_NS="qbt-veth"
QBITTORRENT_PORT=6881
WEBUI_PORT=8080

echo -e "${BLUE}=== qBittorrent VPN Verification ===${NC}\n"

# Check 1: Namespace exists
echo -e "${BLUE}[1] Checking network namespace...${NC}"
if ip netns list | grep -q "^${NAMESPACE}$"; then
    echo -e "${GREEN}✓${NC} Namespace '${NAMESPACE}' exists"
else
    echo -e "${RED}✗${NC} Namespace '${NAMESPACE}' does not exist"
    exit 1
fi

# Check 2: WireGuard interface in namespace
echo -e "\n${BLUE}[2] Checking WireGuard interface in namespace...${NC}"
if ip netns exec "${NAMESPACE}" ip link show "${WG_INTERFACE}" &>/dev/null; then
    echo -e "${GREEN}✓${NC} WireGuard interface '${WG_INTERFACE}' exists"
    ip netns exec "${NAMESPACE}" ip addr show "${WG_INTERFACE}"
else
    echo -e "${RED}✗${NC} WireGuard interface '${WG_INTERFACE}' not found"
fi

# Check 3: veth pair interfaces
echo -e "\n${BLUE}[3] Checking veth pair...${NC}"
if ip link show "${VETH_HOST}" &>/dev/null; then
    echo -e "${GREEN}✓${NC} Host veth interface '${VETH_HOST}' exists"
    ip addr show "${VETH_HOST}"
else
    echo -e "${RED}✗${NC} Host veth interface '${VETH_HOST}' not found"
fi

if ip netns exec "${NAMESPACE}" ip link show "${VETH_NS}" &>/dev/null; then
    echo -e "${GREEN}✓${NC} Namespace veth interface '${VETH_NS}' exists"
    ip netns exec "${NAMESPACE}" ip addr show "${VETH_NS}"
else
    echo -e "${RED}✗${NC} Namespace veth interface '${VETH_NS}' not found"
fi

# Check 4: DNS in namespace
echo -e "\n${BLUE}[4] Checking DNS in namespace...${NC}"
if [ -f "/run/netns/${NAMESPACE}/etc/resolv.conf" ]; then
    echo -e "${GREEN}✓${NC} resolv.conf exists in namespace:"
    cat "/run/netns/${NAMESPACE}/etc/resolv.conf" | sed 's/^/    /'
else
    echo -e "${RED}✗${NC} resolv.conf not found in namespace"
fi

# Check 5: IP routing in namespace
echo -e "\n${BLUE}[5] Checking IP routing in namespace...${NC}"
echo "Default route:"
ip netns exec "${NAMESPACE}" ip route show default 2>/dev/null || echo -e "${RED}✗${NC} No default route"
echo "Full routing table:"
ip netns exec "${NAMESPACE}" ip route show | sed 's/^/    /'

# Check 6: qBittorrent service status
echo -e "\n${BLUE}[6] Checking qBittorrent service...${NC}"
if systemctl is-active --quiet qbittorrent; then
    echo -e "${GREEN}✓${NC} qBittorrent service is running"
    systemctl status qbittorrent | grep -E "Active:|Loaded:" | sed 's/^/    /'
else
    echo -e "${RED}✗${NC} qBittorrent service is not running"
fi

# Check 7: Port connectivity
echo -e "\n${BLUE}[7] Checking port connectivity...${NC}"

# Check WebUI port on host
if nc -z 127.0.0.1 "${WEBUI_PORT}" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} WebUI port ${WEBUI_PORT} is accessible on host"
else
    echo -e "${RED}✗${NC} WebUI port ${WEBUI_PORT} is not accessible on host"
fi

# Check torrent port in namespace
if ip netns exec "${NAMESPACE}" nc -z 127.0.0.1 "${QBITTORRENT_PORT}" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Torrent port ${QBITTORRENT_PORT} is accessible in namespace"
else
    echo -e "${YELLOW}⚠${NC} Torrent port ${QBITTORRENT_PORT} may not be listening (normal if qBittorrent just started)"
fi

# Check 8: iptables rules
echo -e "\n${BLUE}[8] Checking iptables rules for port forwarding...${NC}"
if iptables -t nat -L PREROUTING -n | grep -q "${WEBUI_PORT}"; then
    echo -e "${GREEN}✓${NC} WebUI port forwarding rules exist"
else
    echo -e "${RED}✗${NC} WebUI port forwarding rules not found"
fi

if iptables -t nat -L PREROUTING -n | grep -q "${QBITTORRENT_PORT}"; then
    echo -e "${GREEN}✓${NC} Torrent port forwarding rules exist"
else
    echo -e "${RED}✗${NC} Torrent port forwarding rules not found"
fi

# Check 9: Test VPN connectivity from namespace
echo -e "\n${BLUE}[9] Testing VPN connectivity...${NC}"
if ip netns exec "${NAMESPACE}" ping -c 1 8.8.8.8 &>/dev/null; then
    echo -e "${GREEN}✓${NC} Can reach external IP (8.8.8.8) from namespace"
else
    echo -e "${YELLOW}⚠${NC} Cannot reach external IP (8.8.8.8) - check VPN peer configuration"
fi

# Check 10: DNS leak test
echo -e "\n${BLUE}[10] Testing DNS from namespace...${NC}"
if ip netns exec "${NAMESPACE}" nslookup example.com &>/dev/null; then
    echo -e "${GREEN}✓${NC} DNS resolution works in namespace"
    echo "    Resolved example.com:"
    ip netns exec "${NAMESPACE}" nslookup example.com 2>/dev/null | grep -E "^Address:" | sed 's/^/    /'
else
    echo -e "${RED}✗${NC} DNS resolution failed - check DNS configuration"
fi

# Check 11: IPv6 leak test (important for privacy)
echo -e "\n${BLUE}[11] Checking IPv6 configuration...${NC}"
if ip netns exec "${NAMESPACE}" ip -6 route show | grep -q "^default"; then
    echo -e "${YELLOW}⚠${NC} IPv6 default route exists - possible IPv6 leak"
    ip netns exec "${NAMESPACE}" ip -6 route show default | sed 's/^/    /'
else
    echo -e "${GREEN}✓${NC} No IPv6 default route (good for privacy)"
fi

# Check 12: Privoxy/Dante proxies
echo -e "\n${BLUE}[12] Checking proxy services...${NC}"
if systemctl is-active --quiet privoxy-qbvpn; then
    echo -e "${GREEN}✓${NC} Privoxy proxy is running"
else
    echo -e "${YELLOW}⚠${NC} Privoxy proxy is not running"
fi

if systemctl is-active --quiet dante-qbvpn; then
    echo -e "${GREEN}✓${NC} Dante SOCKS proxy is running"
else
    echo -e "${YELLOW}⚠${NC} Dante SOCKS proxy is not running"
fi

# Check 13: Prowlarr proxy configuration (if enabled)
echo -e "\n${BLUE}[13] Checking Prowlarr proxy setup...${NC}"
if systemctl is-active --quiet prowlarr; then
    echo -e "${GREEN}✓${NC} Prowlarr service is running"
    echo "    Check Prowlarr UI for proxy settings at http://127.0.0.1:9696/settings/indexers"
else
    echo -e "${YELLOW}⚠${NC} Prowlarr service is not running"
fi

echo -e "\n${BLUE}=== Verification Complete ===${NC}"
echo -e "${YELLOW}Note: Review the qBittorrent settings at http://127.0.0.1:8080${NC}"
echo -e "${YELLOW}Ensure: Connection.ListenInterfaceValue = 0.0.0.0${NC}"
echo -e "${YELLOW}Ensure: Connection.InterfaceAddress = 0.0.0.0${NC}"
