#!/usr/bin/env bash
# Quick diagnostic script for qBittorrent VPN connectivity issues
# Run as root: sudo bash check-qbt-vpn.sh

set -euo pipefail

NAMESPACE="qbt"
IFACE="qbt0"

echo "=== qBittorrent VPN Diagnostic ==="
echo ""

# 1. Check routing
echo "1. Routing table:"
ip netns exec "${NAMESPACE}" ip route show
echo ""

# 2. Check iptables OUTPUT rules
echo "2. iptables OUTPUT rules:"
ip netns exec "${NAMESPACE}" iptables -L OUTPUT -n -v
echo ""

# 3. Check iptables OUTPUT policy
echo "3. iptables OUTPUT policy:"
ip netns exec "${NAMESPACE}" iptables -L OUTPUT -n | head -5
echo ""

# 4. Check if WireGuard is working (try to ping VPN DNS)
echo "4. Testing VPN DNS connectivity:"
if ip netns exec "${NAMESPACE}" ping -c 2 -W 2 10.2.0.1 2>&1; then
    echo "✓ Can reach VPN DNS (10.2.0.1)"
else
    echo "✗ Cannot reach VPN DNS"
fi
echo ""

# 5. Check if we can reach external IPs
echo "5. Testing external connectivity:"
if ip netns exec "${NAMESPACE}" ping -c 2 -W 2 8.8.8.8 2>&1; then
    echo "✓ Can reach external IP (8.8.8.8)"
else
    echo "✗ Cannot reach external IP"
fi
echo ""

# 6. Check WireGuard interface status
echo "6. WireGuard interface status:"
ip netns exec "${NAMESPACE}" ip -s link show "${IFACE}" | head -10
echo ""

# 7. Try to get WireGuard status (if available)
echo "7. WireGuard status (if wg command available):"
if command -v wg >/dev/null 2>&1; then
    ip netns exec "${NAMESPACE}" wg show "${IFACE}" 2>&1 || echo "Could not get WireGuard status"
else
    echo "wg command not available in PATH"
    echo "Try: /nix/store/*/wireguard-tools-*/bin/wg show ${IFACE}"
fi
echo ""

# 8. Check WireGuard config file
echo "8. WireGuard config file (first 20 lines):"
head -20 /run/qbittorrent-wg.conf 2>&1 || echo "Config file not found"
echo ""

# 9. Test HTTP (non-TLS) connectivity
echo "9. Testing HTTP (non-TLS) connectivity:"
if ip netns exec "${NAMESPACE}" curl -s --max-time 5 http://example.com > /dev/null 2>&1; then
    echo "✓ HTTP connectivity works"
else
    echo "✗ HTTP connectivity failed"
    ip netns exec "${NAMESPACE}" curl -v --max-time 5 http://example.com 2>&1 | tail -10
fi
echo ""

echo "=== Diagnostic Complete ==="
echo ""
echo "If WireGuard is not working, check:"
echo "  1. WireGuard config file: /run/qbittorrent-wg.conf"
echo "  2. Restart services: sudo systemctl restart qbt.service"
echo "  3. Check logs: sudo journalctl -u qbt.service -n 50"
