#!/usr/bin/env bash
# Comprehensive connectivity test from VPN namespace
# Run as root: sudo bash test-vpn-connectivity.sh

set -euo pipefail

NAMESPACE="qbt"
IFACE="qbt0"
WG_PATH="/nix/store/30ymxnyg9zhvyr86rwa5h8s4phi6kxyv-wireguard-tools-1.0.20250521/bin/wg"

echo "=== VPN Connectivity Test ==="
echo ""

# 1. Check WireGuard status
echo "1. WireGuard Status:"
ip netns exec "$NAMESPACE" "$WG_PATH" show "$IFACE" | grep -E "(handshake|transfer)" || true
echo ""

# 2. Check routing
echo "2. Routing Table:"
ip netns exec "$NAMESPACE" ip route show
echo ""

# 3. Check DNS
echo "3. DNS Configuration:"
ip netns exec "$NAMESPACE" cat /etc/resolv.conf 2>/dev/null || echo "  Using systemd-resolved"
echo ""

# 4. Test DNS resolution
echo "4. DNS Resolution Test:"
if ip netns exec "$NAMESPACE" getent hosts torrent.blmt.io >/dev/null 2>&1; then
    echo "  ✓ DNS resolution works"
    ip netns exec "$NAMESPACE" getent hosts torrent.blmt.io | head -1
else
    echo "  ✗ DNS resolution failed"
fi
echo ""

# 5. Test VPN DNS
echo "5. Testing VPN DNS (10.2.0.1):"
if ip netns exec "$NAMESPACE" ping -c 2 -W 2 10.2.0.1 >/dev/null 2>&1; then
    echo "  ✓ Can reach VPN DNS"
else
    echo "  ✗ Cannot reach VPN DNS"
fi
echo ""

# 6. Test external connectivity
echo "6. Testing External Connectivity:"
if ip netns exec "$NAMESPACE" ping -c 2 -W 2 8.8.8.8 >/dev/null 2>&1; then
    echo "  ✓ Can reach external IP (8.8.8.8)"
else
    echo "  ✗ Cannot reach external IP"
fi
echo ""

# 7. Test HTTP (non-TLS)
echo "7. Testing HTTP (non-TLS) Connectivity:"
if ip netns exec "$NAMESPACE" curl -s --max-time 5 http://example.com >/dev/null 2>&1; then
    echo "  ✓ HTTP connectivity works"
else
    echo "  ✗ HTTP connectivity failed"
    echo "  Attempting verbose test..."
    ip netns exec "$NAMESPACE" curl -v --max-time 5 http://example.com 2>&1 | tail -10
fi
echo ""

# 8. Check iptables OUTPUT rules
echo "8. iptables OUTPUT Rules:"
ip netns exec "$NAMESPACE" iptables -L OUTPUT -n -v | head -20
echo ""

# 9. Check OUTPUT policy
echo "9. iptables OUTPUT Policy:"
ip netns exec "$NAMESPACE" iptables -S OUTPUT | head -5
echo ""

# 10. Test HTTPS connectivity
echo "10. Testing HTTPS Connectivity to torrent.blmt.io:"
echo "  Attempting connection..."
ip netns exec "$NAMESPACE" curl -v --max-time 10 https://torrent.blmt.io 2>&1 | head -30
echo ""

# 11. Check VPN IP
echo "11. Checking VPN IP Address:"
VPN_IP=$(ip netns exec "$NAMESPACE" curl -s --max-time 5 https://api.ipify.org 2>&1)
if [ -n "$VPN_IP" ] && [[ "$VPN_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "  VPN IP: $VPN_IP"
    HOST_IP=$(curl -s --max-time 5 https://api.ipify.org 2>&1)
    if [ "$VPN_IP" != "$HOST_IP" ]; then
        echo "  ✓ VPN IP differs from host IP (VPN working)"
        echo "  Host IP: $HOST_IP"
    else
        echo "  ⚠ VPN IP matches host IP (unexpected)"
    fi
else
    echo "  ✗ Could not determine VPN IP"
    echo "  Error: $VPN_IP"
fi
echo ""

echo "=== Test Complete ==="
