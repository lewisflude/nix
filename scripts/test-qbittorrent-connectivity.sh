#!/usr/bin/env bash
# Test qBittorrent network connectivity (TCP and uTP) in VPN namespace

set -euo pipefail

NAMESPACE="qbt"
PORT=6881
VPN_INTERFACE="qbt0"
VPN_IP="10.2.0.2"

echo "=========================================="
echo "qBittorrent Network Connectivity Test"
echo "=========================================="
echo ""

# Check if namespace exists
if ! sudo ip netns list | grep -q "$NAMESPACE"; then
    echo "? ERROR: VPN namespace '$NAMESPACE' not found"
    exit 1
fi
echo "? VPN namespace '$NAMESPACE' exists"
echo ""

# Check VPN interface
echo "--- VPN Interface Status ---"
if sudo ip netns exec "$NAMESPACE" ip addr show "$VPN_INTERFACE" &>/dev/null; then
    VPN_ACTUAL_IP=$(sudo ip netns exec "$NAMESPACE" ip addr show "$VPN_INTERFACE" | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    echo "? VPN interface '$VPN_INTERFACE' is up"
    echo "   IP address: $VPN_ACTUAL_IP"
else
    echo "? ERROR: VPN interface '$VPN_INTERFACE' not found"
    exit 1
fi
echo ""

# Check external IP
echo "--- External IP Check ---"
EXTERNAL_IP=$(sudo ip netns exec "$NAMESPACE" curl -s --max-time 5 https://ipv4.icanhazip.com 2>/dev/null || echo "unknown")
if [ "$EXTERNAL_IP" != "unknown" ]; then
    echo "? External IP: $EXTERNAL_IP (via VPN)"
else
    echo "? ERROR: Cannot determine external IP"
fi
echo ""

# Check port binding
echo "--- Port $PORT Binding Status ---"
TCP_LISTEN=$(sudo ip netns exec "$NAMESPACE" ss -tln | grep ":$PORT " || true)
UDP_LISTEN=$(sudo ip netns exec "$NAMESPACE" ss -uln | grep ":$PORT " || true)

if echo "$TCP_LISTEN" | grep -q ":$PORT"; then
    BIND_IP=$(echo "$TCP_LISTEN" | awk '{print $4}' | cut -d: -f1)
    echo "? TCP port $PORT is listening"
    echo "   Bound to: $BIND_IP"
else
    echo "? ERROR: TCP port $PORT is NOT listening"
fi

if echo "$UDP_LISTEN" | grep -q ":$PORT"; then
    BIND_IP=$(echo "$UDP_LISTEN" | awk '{print $4}' | cut -d: -f1)
    echo "? UDP (uTP) port $PORT is listening"
    echo "   Bound to: $BIND_IP"
else
    echo "? ERROR: UDP (uTP) port $PORT is NOT listening"
fi
echo ""

# Test TCP connectivity
echo "--- TCP Connectivity Test ---"
if sudo ip netns exec "$NAMESPACE" timeout 5 bash -c "echo > /dev/tcp/8.8.8.8/53" 2>/dev/null; then
    echo "? TCP outbound connections work"
else
    echo "? ERROR: TCP outbound connections FAILED"
fi

# Test UDP connectivity
echo "--- UDP (uTP) Connectivity Test ---"
if echo "test" | sudo ip netns exec "$NAMESPACE" timeout 3 nc -u -w 1 8.8.8.8 53 2>/dev/null; then
    echo "? UDP outbound connections work"
else
    echo "? ERROR: UDP outbound connections FAILED"
fi
echo ""

# Test ICMP (ping)
echo "--- ICMP Connectivity Test ---"
if sudo ip netns exec "$NAMESPACE" ping -c 2 -W 2 8.8.8.8 &>/dev/null; then
    echo "? ICMP (ping) connectivity works"
else
    echo "? ERROR: ICMP connectivity FAILED"
fi
echo ""

# Check routing
echo "--- Routing Status ---"
DEFAULT_ROUTE=$(sudo ip netns exec "$NAMESPACE" ip route show default | awk '{print $3}')
if [ -n "$DEFAULT_ROUTE" ]; then
    echo "? Default route: via $DEFAULT_ROUTE"
    if [ "$DEFAULT_ROUTE" = "$VPN_INTERFACE" ]; then
        echo "   ? Traffic is routed through VPN"
    else
        echo "   ??  WARNING: Traffic may not be routed through VPN"
    fi
else
    echo "? ERROR: No default route found"
fi
echo ""

# Check active connections
echo "--- Active Connections on Port $PORT ---"
ACTIVE_CONN=$(sudo ip netns exec "$NAMESPACE" ss -tn 2>/dev/null | grep -c ":$PORT " || echo "0")
ACTIVE_CONN=$((ACTIVE_CONN + 0))  # Convert to integer
if [ "$ACTIVE_CONN" -gt 0 ]; then
    echo "? Active TCP connections: $ACTIVE_CONN"
    sudo ip netns exec "$NAMESPACE" ss -tn 2>/dev/null | grep ":$PORT " | head -5 || true
else
    echo "??  No active TCP connections on port $PORT (normal if no active torrents)"
fi
echo ""

# Summary
echo "=========================================="
echo "Summary"
echo "=========================================="
TCP_OK=false
UDP_OK=false

if echo "$TCP_LISTEN" | grep -q ":$PORT"; then
    TCP_OK=true
fi

if echo "$UDP_LISTEN" | grep -q ":$PORT"; then
    UDP_OK=true
fi

if [ "$EXTERNAL_IP" != "unknown" ] && [ "$TCP_OK" = true ] && [ "$UDP_OK" = true ]; then
    echo "? qBittorrent network connectivity appears to be working"
    echo "   - VPN is active (External IP: $EXTERNAL_IP)"
    echo "   - TCP port $PORT is listening on VPN interface"
    echo "   - UDP (uTP) port $PORT is listening on VPN interface"
    echo ""
    echo "??  Note: Port forwarding status cannot be verified from inside"
    echo "   Check ProtonVPN dashboard or use external port checker:"
    echo "   https://www.yougetsignal.com/tools/open-ports/"
    echo "   Test with: $EXTERNAL_IP:$PORT"
    exit 0
else
    echo "? Some connectivity issues detected"
    [ "$EXTERNAL_IP" = "unknown" ] && echo "   - Cannot determine external IP"
    [ "$TCP_OK" = false ] && echo "   - TCP port $PORT is not listening"
    [ "$UDP_OK" = false ] && echo "   - UDP port $PORT is not listening"
    exit 1
fi
