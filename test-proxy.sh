#!/usr/bin/env bash
# Test script for VPN proxies
set -euo pipefail

echo "=== Testing VPN Proxies ==="
echo ""

echo "1. Checking services..."
systemctl is-active --quiet privoxy-qbvpn.service && echo "✓ Privoxy HTTP proxy is running" || echo "✗ Privoxy HTTP proxy is NOT running"
systemctl is-active --quiet dante-qbvpn.service && echo "✓ Dante SOCKS5 proxy is running" || echo "✗ Dante SOCKS5 proxy is NOT running"
systemctl is-active --quiet qbittorrent-netns.service && echo "✓ Network namespace is active" || echo "✗ Network namespace is NOT active"
echo ""

echo "2. Checking network namespace..."
if ip netns list | grep -q "^qbittorrent\b"; then
  echo "✓ Network namespace 'qbittorrent' exists"
else
  echo "✗ Network namespace 'qbittorrent' does NOT exist"
fi
echo ""

echo "3. Checking if proxies are listening in namespace..."
if sudo ip netns exec qbittorrent ss -tlnp 2>/dev/null | grep -q ":1080"; then
  echo "✓ SOCKS5 proxy is listening on port 1080"
else
  echo "✗ SOCKS5 proxy is NOT listening on port 1080"
fi

if sudo ip netns exec qbittorrent ss -tlnp 2>/dev/null | grep -q ":8118"; then
  echo "✓ HTTP proxy is listening on port 8118"
else
  echo "✗ HTTP proxy is NOT listening on port 8118"
fi
echo ""

echo "4. Checking firewall rules..."
if sudo iptables -t nat -L -n 2>/dev/null | grep -q "1080.*10.200.0.1"; then
  echo "✓ SOCKS5 port forwarding rules exist"
else
  echo "✗ SOCKS5 port forwarding rules NOT found"
fi

if sudo iptables -t nat -L -n 2>/dev/null | grep -q "8118.*10.200.0.1"; then
  echo "✓ HTTP port forwarding rules exist"
else
  echo "✗ HTTP port forwarding rules NOT found"
fi
echo ""

echo "5. Testing proxy connectivity..."
echo "Testing SOCKS5 proxy (may take a few seconds)..."
if timeout 5 curl -s --proxy socks5://127.0.0.1:1080 http://ifconfig.me 2>&1 | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$"; then
  VPN_IP=$(timeout 5 curl -s --proxy socks5://127.0.0.1:1080 http://ifconfig.me 2>&1)
  echo "✓ SOCKS5 proxy is working! Your VPN IP: $VPN_IP"
else
  echo "✗ SOCKS5 proxy test failed (connection timeout or error)"
fi

echo "Testing HTTP proxy (may take a few seconds)..."
if timeout 5 curl -s --proxy http://127.0.0.1:8118 http://ifconfig.me 2>&1 | grep -qE "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$"; then
  VPN_IP=$(timeout 5 curl -s --proxy http://127.0.0.1:8118 http://ifconfig.me 2>&1)
  echo "✓ HTTP proxy is working! Your VPN IP: $VPN_IP"
else
  echo "✗ HTTP proxy test failed (connection timeout or error)"
fi
echo ""

echo "6. Checking Prowlarr service..."
if systemctl is-active --quiet prowlarr.service; then
  echo "✓ Prowlarr is running"
  echo "  Environment variables:"
  systemctl show prowlarr.service --property=Environment --no-pager | grep -i proxy || echo "  (No proxy environment variables set)"
else
  echo "✗ Prowlarr is NOT running"
fi
echo ""

echo "=== Test Complete ==="
echo ""
echo "If proxies are not working:"
echo "1. Make sure you've rebuilt your NixOS configuration"
echo "2. Restart services: sudo systemctl restart dante-qbvpn.service privoxy-qbvpn.service"
echo "3. Check logs: sudo journalctl -u dante-qbvpn.service -u privoxy-qbvpn.service -n 50"
