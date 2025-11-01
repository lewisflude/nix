#!/usr/bin/env bash
# Test torrent/network connectivity for qBittorrent VPN setup
# Specifically tests connectivity to torrent.blmt.io tracker

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check() {
    if "$@"; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1"
        return 1
    fi
}

info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

TRACKER_URL="https://torrent.blmt.io"
NAMESPACE="qbt"

echo -e "${BLUE}=== qBittorrent Torrent Connectivity Test ===${NC}\n"
echo "Testing connectivity to: ${TRACKER_URL}"
echo ""

# Test 1: Check namespace exists
echo "1. Checking VPN namespace..."
if ip netns list | grep -q "^${NAMESPACE}"; then
    check true "VPN namespace '${NAMESPACE}' exists"
else
    error "VPN namespace '${NAMESPACE}' not found"
    echo "   Available namespaces:"
    ip netns list | sed 's/^/   /'
    exit 1
fi

# Test 2: Check qBittorrent service
echo ""
echo "2. Checking qBittorrent service..."
if systemctl is-active --quiet qbittorrent.service; then
    check true "qBittorrent service is running"
else
    error "qBittorrent service is not running"
    info "Start with: systemctl start qbittorrent.service"
fi

# Test 3: Check VPN namespace service
echo ""
echo "3. Checking VPN namespace service..."
if systemctl is-active --quiet qbt.service; then
    check true "VPN namespace service is active"
else
    error "VPN namespace service is not active"
fi

# Test 4: Check WireGuard interface in namespace
echo ""
echo "4. Checking WireGuard interface..."
# VPN-Confinement uses interface name based on namespace (qbt -> qbt0)
IFACE_NAME="qbt0"
if ip netns exec "${NAMESPACE}" ip link show "${IFACE_NAME}" 2>/dev/null | grep -q "${IFACE_NAME}"; then
    check true "WireGuard interface ${IFACE_NAME} exists"
    if ip netns exec "${NAMESPACE}" ip link show "${IFACE_NAME}" | grep -q "state UP"; then
        check true "WireGuard interface is UP"
        echo "   IP addresses:"
        ip netns exec "${NAMESPACE}" ip addr show "${IFACE_NAME}" | grep -E "inet|inet6" | sed 's/^/   /' || echo "   No IP addresses assigned"
        echo "   WireGuard status:"
        ip netns exec "${NAMESPACE}" wg show "${IFACE_NAME}" 2>/dev/null | sed 's/^/   /' || echo "   Could not get WireGuard status"
    else
        info "WireGuard interface exists but is DOWN"
        echo "   Checking interface details:"
        ip netns exec "${NAMESPACE}" ip link show "${IFACE_NAME}" | sed 's/^/   /'
    fi
else
    error "WireGuard interface ${IFACE_NAME} not found in namespace"
    echo "   Available interfaces in namespace:"
    ip netns exec "${NAMESPACE}" ip link show | sed 's/^/   /' || echo "   Could not list interfaces"
fi

# Test 5: Check DNS resolution in namespace
echo ""
echo "5. Testing DNS resolution in namespace..."
if ip netns exec "${NAMESPACE}" getent hosts torrent.blmt.io 2>/dev/null | grep -q "torrent.blmt.io"; then
    check true "DNS resolution works for torrent.blmt.io"
    echo "   Resolved IPs:"
    ip netns exec "${NAMESPACE}" getent hosts torrent.blmt.io | sed 's/^/   /'
else
    error "DNS resolution failed for torrent.blmt.io"
fi

# Test 6: Check basic internet connectivity from namespace
echo ""
echo "6. Testing basic internet connectivity from namespace..."
if ip netns exec "${NAMESPACE}" ping -c 2 -W 2 8.8.8.8 2>&1 | grep -q "0% packet loss"; then
    check true "Can reach external IP (8.8.8.8)"
else
    error "Cannot reach external IP (8.8.8.8)"
    info "This may indicate VPN connection issues"
fi

# Test 7: Test HTTP connectivity to tracker from namespace
echo ""
echo "7. Testing HTTP connectivity to tracker from namespace..."
info "Note: Requires root privileges to test from namespace"
echo "   Run manually: sudo ip netns exec ${NAMESPACE} curl -v ${TRACKER_URL}"

# Test 8: Test HTTPS connectivity to tracker from namespace
echo ""
echo "8. Testing HTTPS connectivity to tracker from namespace..."
info "Note: Requires root privileges to test from namespace"
echo "   Run manually: sudo ip netns exec ${NAMESPACE} curl -v ${TRACKER_URL}"

# Test 9: Check WebUI accessibility
echo ""
echo "9. Testing qBittorrent WebUI accessibility..."
if curl -s --connect-timeout 2 --max-time 5 "http://localhost:8080" > /dev/null 2>&1; then
    check true "WebUI is accessible on localhost:8080"
else
    error "WebUI is not accessible on localhost:8080"
fi

# Test 10: Check VPN IP (verify we're using VPN)
echo ""
echo "10. Checking VPN IP address..."
info "Note: Requires root privileges to test from namespace"
echo "   Run manually: sudo ip netns exec ${NAMESPACE} curl https://api.ipify.org"
echo "   Expected: Should show VPN IP (ProtonVPN), not your ISP IP"

# Test 11: Check torrent port listening
echo ""
echo "11. Checking torrent port (6881)..."
if ss -tuln | grep -q ":6881"; then
    check true "Port 6881 is listening"
    ss -tuln | grep ":6881" | sed 's/^/   /'
else
    info "Port 6881 not listening (may be normal if no active torrents)"
fi

# Summary
echo ""
echo -e "${BLUE}=== Test Summary ===${NC}"
echo ""
echo "If all connectivity tests passed, qBittorrent should be able to reach:"
echo "  - ${TRACKER_URL}"
echo ""
echo "To verify torrent functionality:"
echo "  1. Access WebUI: http://localhost:8080"
echo "  2. Add a test torrent"
echo "  3. Check that it connects to trackers"
echo ""
echo "For detailed VPN testing, run:"
echo "  ./scripts/test-qbt-vpn.sh"
echo ""
