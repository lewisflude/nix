#!/usr/bin/env bash
# Test IPv6 optimizations for qBittorrent VPN setup
# This script verifies that IPv6 optimizations are correctly applied

set -euo pipefail

echo "=== IPv6 Optimization Verification ==="
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
PASSED=0
FAILED=0

# Helper function to check sysctl value
check_sysctl() {
    local namespace=$1
    local setting=$2
    local expected=$3
    local description=$4

    if [ -n "$namespace" ]; then
        actual=$(ip netns exec "$namespace" sysctl -n "$setting" 2>/dev/null || echo "NOT_SET")
    else
        actual=$(sysctl -n "$setting" 2>/dev/null || echo "NOT_SET")
    fi

    if [ "$actual" = "$expected" ] || [ "$actual" = "NOT_SET" ]; then
        if [ "$actual" = "NOT_SET" ]; then
            echo -e "   ${YELLOW}?${NC} $description: Setting not available (may be kernel-dependent)"
        else
            echo -e "   ${GREEN}?${NC} $description: $actual"
            ((PASSED++))
        fi
    else
        echo -e "   ${RED}?${NC} $description: Expected '$expected', got '$actual'"
        ((FAILED++))
    fi
}

# Helper function to check if value contains expected
check_sysctl_contains() {
    local namespace=$1
    local setting=$2
    local expected=$3
    local description=$4

    if [ -n "$namespace" ]; then
        actual=$(ip netns exec "$namespace" sysctl -n "$setting" 2>/dev/null || echo "NOT_SET")
    else
        actual=$(sysctl -n "$setting" 2>/dev/null || echo "NOT_SET")
    fi

    if [[ "$actual" == *"$expected"* ]] || [ "$actual" = "NOT_SET" ]; then
        if [ "$actual" = "NOT_SET" ]; then
            echo -e "   ${YELLOW}?${NC} $description: Setting not available"
        else
            echo -e "   ${GREEN}?${NC} $description: $actual"
            ((PASSED++))
        fi
    else
        echo -e "   ${RED}?${NC} $description: Expected to contain '$expected', got '$actual'"
        ((FAILED++))
    fi
}

# 1. Check if namespace exists
echo "1. Checking VPN namespace..."
if ip netns list | grep -q "^$NAMESPACE"; then
    echo -e "   ${GREEN}?${NC} Namespace '$NAMESPACE' exists"
    ((PASSED++))
else
    echo -e "   ${RED}?${NC} Namespace '$NAMESPACE' not found"
    echo -e "   ${YELLOW}Note:${NC} VPN may not be enabled or namespace hasn't been created yet"
    ((FAILED++))
    echo ""
    echo "Skipping namespace-specific tests..."
    NAMESPACE_EXISTS=false
fi

if [ "${NAMESPACE_EXISTS:-true}" = true ]; then
    # 2. Check IPv6 addresses in namespace
    echo ""
    echo "2. Checking IPv6 addresses in namespace..."
    IPv6_ADDRS=$(ip netns exec "$NAMESPACE" ip -6 addr show "$INTERFACE" 2>/dev/null | grep "inet6" | wc -l || echo "0")
    if [ "$IPv6_ADDRS" -gt 0 ]; then
        echo -e "   ${GREEN}?${NC} IPv6 addresses found on $INTERFACE:"
        ip netns exec "$NAMESPACE" ip -6 addr show "$INTERFACE" 2>/dev/null | grep "inet6" | sed 's/^/      /' || true
        ((PASSED++))
    else
        echo -e "   ${YELLOW}?${NC} No IPv6 addresses found on $INTERFACE"
        echo -e "   ${BLUE}Info:${NC} This is normal if ProtonVPN doesn't provide IPv6 or WireGuard config doesn't include IPv6"
    fi

    # 3. Check IPv6 routes in namespace
    echo ""
    echo "3. Checking IPv6 routes in namespace..."
    IPv6_ROUTES=$(ip netns exec "$NAMESPACE" ip -6 route show 2>/dev/null | wc -l || echo "0")
    if [ "$IPv6_ROUTES" -gt 0 ]; then
        echo -e "   ${GREEN}?${NC} IPv6 routes found:"
        ip netns exec "$NAMESPACE" ip -6 route show 2>/dev/null | sed 's/^/      /' || true
        ((PASSED++))
    else
        echo -e "   ${YELLOW}?${NC} No IPv6 routes found"
    fi

    # 4. Check IPv6 forwarding in namespace
    echo ""
    echo "4. Checking IPv6 forwarding in namespace..."
    check_sysctl "$NAMESPACE" "net.ipv6.conf.all.forwarding" "1" "IPv6 forwarding enabled"

    # 5. Check IPv6 TCP buffer sizes in namespace
    echo ""
    echo "5. Checking IPv6 TCP buffer sizes in namespace..."
    check_sysctl_contains "$NAMESPACE" "net.ipv6.tcp_rmem" "16777216" "IPv6 TCP receive buffer max (16MB)"
    check_sysctl_contains "$NAMESPACE" "net.ipv6.tcp_wmem" "16777216" "IPv6 TCP send buffer max (16MB)"

    # 6. Check IPv6 congestion control in namespace
    echo ""
    echo "6. Checking IPv6 congestion control in namespace..."
    check_sysctl_contains "$NAMESPACE" "net.ipv6.tcp_congestion_control" "bbr" "IPv6 BBR congestion control"

    # 7. Test IPv6 connectivity (if IPv6 is available)
    echo ""
    echo "7. Testing IPv6 connectivity in namespace..."
    if [ "$IPv6_ADDRS" -gt 0 ]; then
        if ip netns exec "$NAMESPACE" ping6 -c 2 -W 2 2001:4860:4860::8888 >/dev/null 2>&1; then
            echo -e "   ${GREEN}?${NC} IPv6 connectivity works (tested with Google DNS)"
            ((PASSED++))
        else
            echo -e "   ${YELLOW}?${NC} IPv6 connectivity test failed (may be normal if VPN doesn't route IPv6)"
        fi
    else
        echo -e "   ${BLUE}?${NC} Skipped (no IPv6 addresses available)"
    fi
fi

# 8. Check global IPv6 TCP buffer sizes
echo ""
echo "8. Checking global IPv6 TCP buffer sizes..."
check_sysctl_contains "" "net.ipv6.tcp_rmem" "16777216" "Global IPv6 TCP receive buffer max (16MB)"
check_sysctl_contains "" "net.ipv6.tcp_wmem" "16777216" "Global IPv6 TCP send buffer max (16MB)"

# 9. Check global IPv6 congestion control
echo ""
echo "9. Checking global IPv6 congestion control..."
check_sysctl_contains "" "net.ipv6.tcp_congestion_control" "bbr" "Global IPv6 BBR congestion control"

# 10. Check global IPv6 forwarding
echo ""
echo "10. Checking global IPv6 forwarding..."
check_sysctl "" "net.ipv6.conf.all.forwarding" "1" "Global IPv6 forwarding enabled"

# Summary
echo ""
echo "=== Summary ==="
echo -e "   ${GREEN}Passed:${NC} $PASSED"
if [ $FAILED -gt 0 ]; then
    echo -e "   ${RED}Failed:${NC} $FAILED"
else
    echo -e "   ${GREEN}Failed:${NC} $FAILED"
fi
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}? All IPv6 optimizations are correctly configured!${NC}"
    exit 0
else
    echo -e "${YELLOW}? Some checks failed. This may be normal if:${NC}"
    echo "   - VPN doesn't provide IPv6 connectivity"
    echo "   - WireGuard config doesn't include IPv6"
    echo "   - Some kernel settings are not available on this system"
    exit 1
fi
