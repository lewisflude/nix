#!/usr/bin/env bash
# Diagnose routing issue in VPN namespace
# Run as root: sudo bash diagnose-routing.sh

NAMESPACE="qbt"
IFACE="qbt0"

echo "=== Routing Diagnosis ==="
echo ""

# 1. Check WireGuard interface status
echo "1. WireGuard Interface Status:"
ip netns exec "$NAMESPACE" ip link show "$IFACE"
echo ""

# 2. Check IP addresses
echo "2. IP Addresses on qbt0:"
ip netns exec "$NAMESPACE" ip addr show "$IFACE"
echo ""

# 3. Check routing table
echo "3. Routing Table:"
ip netns exec "$NAMESPACE" ip route show
echo ""

# 4. Test if we can reach the VPN gateway
echo "4. Testing VPN Gateway Reachability:"
echo "  Attempting to ping VPN DNS (10.2.0.1)..."
if ip netns exec "$NAMESPACE" ping -c 2 -W 2 10.2.0.1 2>&1; then
    echo "  ✓ Can reach VPN DNS"
else
    echo "  ✗ Cannot reach VPN DNS"
fi
echo ""

# 5. Check WireGuard peer status
echo "5. WireGuard Peer Status:"
WG_PATH="/nix/store/30ymxnyg9zhvyr86rwa5h8s4phi6kxyv-wireguard-tools-1.0.20250521/bin/wg"
ip netns exec "$NAMESPACE" "$WG_PATH" show "$IFACE" | grep -A 10 "peer:"
echo ""

# 6. Test routing to external IP
echo "6. Testing Routing to External IP:"
echo "  Checking route to 8.8.8.8..."
ip netns exec "$NAMESPACE" ip route get 8.8.8.8
echo ""

# 7. Test routing to VPN DNS
echo "7. Testing Route to VPN DNS:"
ip netns exec "$NAMESPACE" ip route get 10.2.0.1
echo ""

# 8. Check iptables FORWARD rules (might block traffic)
echo "8. iptables FORWARD Rules:"
ip netns exec "$NAMESPACE" iptables -L FORWARD -n -v
echo ""

# 9. Check iptables INPUT rules
echo "9. iptables INPUT Rules:"
ip netns exec "$NAMESPACE" iptables -L INPUT -n -v | head -20
echo ""

# 10. Test ARP (if applicable)
echo "10. Checking ARP Table:"
ip netns exec "$NAMESPACE" ip neigh show
echo ""

# 11. Check if packets are being sent
echo "11. Testing Packet Transmission:"
echo "  Sending ping to VPN DNS with tcpdump..."
timeout 3 ip netns exec "$NAMESPACE" ping -c 1 10.2.0.1 2>&1 &
sleep 1
ip netns exec "$NAMESPACE" ip -s link show "$IFACE" | grep -E "RX|TX" | head -4
echo ""

echo "=== Diagnosis Complete ==="
echo ""
echo "Key Checks:"
echo "  - Default route should be via qbt0"
echo "  - WireGuard should show handshake"
echo "  - Packets should be transmitted (TX counter increases)"
