#!/usr/bin/env bash

echo "=== ProtonVPN Speed Test ==="
echo ""

# Check we're on VLAN 2
echo "Current IP address:"
ip -4 addr show vlan2 | grep inet
echo ""

# Check public IP
echo "Public IP (should be ProtonVPN):"
curl -s ifconfig.me
echo ""
echo ""

# Speed test using speedtest-cli
echo "Running speed test..."
nix-shell -p speedtest-cli --run "speedtest-cli --simple"
echo ""

# Alternative: Fast.com test (Netflix's speed test)
echo "Alternative test (fast.com):"
nix-shell -p fast-cli --run "fast --upload"
echo ""

# Check port connectivity
echo "Checking port forwarding..."
echo "Port 45564 should be forwarded to your qBittorrent on 62000"
nix-shell -p curl --run "curl -s --max-time 5 http://138.199.7.134:45564 && echo 'Port is reachable!' || echo 'Port test failed (this is ok if qBittorrent is running)'"
echo ""

echo "=== Test Complete ==="
