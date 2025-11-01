#!/usr/bin/env bash
# Test script for qBittorrent VPN configuration
set -euo pipefail

echo "=== Testing qBittorrent VPN Configuration ==="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Test 1: Check if WireGuard config generation service exists
echo "1. Checking WireGuard config generation service..."
if systemctl list-unit-files | grep -q "generate-qbt-wg-config.service"; then
    check true "generate-qbt-wg-config.service exists"
else
    error "generate-qbt-wg-config.service not found"
    exit 1
fi

# Test 2: Start config generation service
echo ""
echo "2. Starting WireGuard config generation..."
if systemctl start generate-qbt-wg-config.service; then
    sleep 1
    if systemctl is-active --quiet generate-qbt-wg-config.service; then
        check true "Config generation service started"
    else
        error "Config generation service failed"
        systemctl status generate-qbt-wg-config.service --no-pager -l
        exit 1
    fi
else
    error "Failed to start config generation service"
    exit 1
fi

# Test 3: Check if WireGuard config file was created
echo ""
echo "3. Checking WireGuard config file..."
if [ -f /run/qbittorrent-wg.conf ]; then
    check true "WireGuard config file exists"
    echo "   Location: /run/qbittorrent-wg.conf"
    echo "   File size: $(stat -c%s /run/qbittorrent-wg.conf) bytes"
    echo ""
    echo "   Config preview:"
    head -10 /run/qbittorrent-wg.conf | sed 's/^/   /'
    echo "   ..."
else
    error "WireGuard config file not found at /run/qbittorrent-wg.conf"
    exit 1
fi

# Test 4: Validate WireGuard config syntax
echo ""
echo "4. Validating WireGuard config..."
if wg-quick check /run/qbittorrent-wg.conf 2>&1 | grep -q "Configuration OK"; then
    check true "WireGuard config syntax is valid"
elif wg-quick check /run/qbittorrent-wg.conf 2>&1 | head -5; then
    # Some versions don't output "Configuration OK", just check for errors
    if ! wg-quick check /run/qbittorrent-wg.conf 2>&1 | grep -qi "error"; then
        check true "WireGuard config appears valid"
    else
        error "WireGuard config has errors"
        wg-quick check /run/qbittorrent-wg.conf 2>&1 | head -10
    fi
else
    info "wg-quick check not available, skipping syntax validation"
fi

# Test 5: Start VPN namespace service
echo ""
echo "5. Starting VPN namespace service (qbt.service)..."
if systemctl start qbt.service; then
    sleep 2
    if systemctl is-active --quiet qbt.service; then
        check true "VPN namespace service started"
    else
        error "VPN namespace service failed to start"
        echo ""
        systemctl status qbt.service --no-pager -l | head -30
        exit 1
    fi
else
    error "Failed to start VPN namespace service"
    systemctl status qbt.service --no-pager -l | head -20
    exit 1
fi

# Test 6: Check if VPN namespace exists
echo ""
echo "6. Checking VPN namespace..."
if ip netns list | grep -q "qbt"; then
    check true "VPN namespace 'qbt' exists"
    echo "   Namespaces:"
    ip netns list | grep "qbt" | sed 's/^/   /'
else
    error "VPN namespace 'qbt' not found"
    echo "   Available namespaces:"
    ip netns list | sed 's/^/   /'
fi

# Test 7: Check WireGuard interface in namespace
echo ""
echo "7. Checking WireGuard interface..."
if ip netns exec qbt ip link show wg0 2>/dev/null | grep -q "wg0"; then
    check true "WireGuard interface wg0 exists in namespace"
    if ip netns exec qbt ip link show wg0 | grep -q "state UP"; then
        check true "WireGuard interface is UP"
        echo "   Interface details:"
        ip netns exec qbt ip addr show wg0 | grep -E "inet|inet6" | sed 's/^/   /' || echo "   No IP addresses assigned yet"
    else
        info "WireGuard interface exists but is DOWN"
    fi
else
    error "WireGuard interface wg0 not found in namespace"
fi

# Test 8: Check DNS in namespace
echo ""
echo "8. Checking DNS configuration..."
if [ -f /run/netns/qbt/etc/resolv.conf ]; then
    check true "DNS resolv.conf exists in namespace"
    echo "   DNS servers:"
    cat /run/netns/qbt/etc/resolv.conf | grep -v "^#" | sed 's/^/   /'
else
    info "DNS resolv.conf not found (may be set via systemd-resolved)"
fi

# Test 9: Check qBittorrent service
echo ""
echo "9. Checking qBittorrent service..."
if systemctl is-enabled --quiet qbittorrent.service; then
    check true "qBittorrent service is enabled"
    if systemctl is-active --quiet qbittorrent.service; then
        check true "qBittorrent service is running"
    else
        info "qBittorrent service is not running (start it with: systemctl start qbittorrent.service)"
    fi
else
    info "qBittorrent service is not enabled"
fi

# Test 10: Check 3proxy service (if enabled)
echo ""
echo "10. Checking 3proxy service..."
if systemctl list-unit-files | grep -q "3proxy-qbvpn.service"; then
    if systemctl is-enabled --quiet 3proxy-qbvpn.service; then
        check true "3proxy service is enabled"
        if systemctl is-active --quiet 3proxy-qbvpn.service; then
            check true "3proxy service is running"
            echo "   Testing proxy connectivity..."
            if ip netns exec qbt curl -s --max-time 2 --proxy http://127.0.0.1:8118 https://api.ipify.org > /dev/null 2>&1; then
                check true "HTTP proxy (8118) is responding"
            else
                info "HTTP proxy may not be fully initialized yet"
            fi
        else
            info "3proxy service is not running"
        fi
    else
        info "3proxy service is not enabled"
    fi
else
    info "3proxy service not found (proxy may not be enabled)"
fi

# Test 11: Check port mappings
echo ""
echo "11. Checking port mappings..."
echo "   WebUI (8080):"
if ss -tlnp | grep -q ":8080"; then
    check true "Port 8080 is listening"
    ss -tlnp | grep ":8080" | sed 's/^/   /'
else
    info "Port 8080 not listening yet"
fi

echo ""
echo "=== Test Summary ==="
echo "If all checks passed, your VPN configuration is working!"
echo ""
echo "Next steps:"
echo "  1. Start qBittorrent: systemctl start qbittorrent.service"
echo "  2. Access WebUI: http://localhost:8080"
echo "  3. Check VPN connection: ip netns exec qbt curl https://api.ipify.org"
echo ""
