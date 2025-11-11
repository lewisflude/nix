#!/usr/bin/env bash
# Update qBittorrent port based on ProtonVPN forwarded port
# Based on: https://github.com/Maroka-chan/VPN-Confinement/issues/10
#
# For ProtonVPN WireGuard, port forwarding uses NAT-PMP and assigns a random port.
# This script can:
# 1. Try to detect the forwarded port automatically (if natpmpc is available)
# 2. Accept a port as argument
# 3. Provide instructions for manual port discovery

set -euo pipefail

NAMESPACE="qbittor"
VPN_INTERFACE="qbittor0"
VPN_GATEWAY="10.2.0.1"  # ProtonVPN DNS/gateway IP from WireGuard config
WEBUI_IP="192.168.15.1"
WEBUI_PORT=8080
WEBUI_URL="http://${WEBUI_IP}:${WEBUI_PORT}"

# Get credentials from environment or SOPS
QB_USERNAME="${QB_USERNAME:-lewis}"
QB_PASSWORD="${QB_PASSWORD:-}"

if [ -z "$QB_PASSWORD" ]; then
    # Try to get from SOPS if available
    if command -v sops >/dev/null 2>&1; then
        QB_PASSWORD=$(sops -d secrets/secrets.yaml 2>/dev/null | grep -A 5 'qbittorrent:' | grep 'password:' | awk '{print $2}' | tr -d '"' || echo "")
    fi
fi

if [ -z "$QB_PASSWORD" ]; then
    echo "Error: QB_PASSWORD not set and cannot retrieve from SOPS"
    echo "Usage: QB_USERNAME=lewis QB_PASSWORD=yourpassword $0 [PORT]"
    exit 1
fi

# Function to try detecting port via NAT-PMP
detect_port_via_natpmp() {
    if command -v natpmpc >/dev/null 2>&1; then
        echo "Attempting to detect forwarded port via NAT-PMP..." >&2
        # Query NAT-PMP for external port mapping
        # NAT-PMP uses UDP port 5351
        PORT=$(sudo ip netns exec "$NAMESPACE" natpmpc -g "$VPN_GATEWAY" -a 0 0 0 2>/dev/null | grep -oP 'external port \K[0-9]+' || echo "")
        if [ -n "$PORT" ] && [ "$PORT" != "0" ]; then
            echo "$PORT"
            return 0
        fi
    fi
    return 1
}

# Function to get port from ProtonVPN API (requires VPN connection)
detect_port_via_api() {
    # ProtonVPN doesn't provide a public API for this, but we can try checking
    # if there's a way to query it. For now, return empty.
    return 1
}

# Determine which port to use
if [ $# -ge 1 ]; then
    NEW_PORT="$1"
    echo "Using provided port: $NEW_PORT"
elif DETECTED_PORT=$(detect_port_via_natpmp); then
    NEW_PORT="$DETECTED_PORT"
    echo "Detected forwarded port via NAT-PMP: $NEW_PORT"
else
    echo "Error: Could not automatically detect forwarded port"
    echo ""
    echo "Usage: $0 <PORT>"
    echo ""
    echo "To find your ProtonVPN forwarded port:"
    echo ""
    echo "Option 1: Check ProtonVPN dashboard"
    echo "  1. Log into https://account.protonvpn.com"
    echo "  2. Go to Downloads ? WireGuard configuration"
    echo "  3. If port forwarding is active, the port may be shown there"
    echo ""
    echo "Option 2: Test common ports"
    echo "  Your current port (6881) might be correct. Test it:"
    echo "  EXTERNAL_IP=\$(sudo ip netns exec $NAMESPACE curl -s https://ipv4.icanhazip.com)"
    echo "  Visit: https://www.yougetsignal.com/tools/open-ports/"
    echo "  Enter IP: \$EXTERNAL_IP"
    echo "  Enter Port: 6881 (or try other ports)"
    echo ""
    echo "Option 3: Install natpmpc and try automatic detection"
    echo "  nix-shell -p natpmpc"
    echo "  Then run this script again without arguments"
    echo ""
    echo "Option 4: Use ProtonVPN app temporarily"
    echo "  Connect using ProtonVPN app, note the forwarded port,"
    echo "  then update qBittorrent: $0 <PORT>"
    exit 1
fi

# Authenticate with qBittorrent API
COOKIE_FILE="/tmp/qb_cookies_$$"
trap "rm -f $COOKIE_FILE" EXIT

AUTH_RESPONSE=$(curl -s -c "$COOKIE_FILE" -b "$COOKIE_FILE" \
    "${WEBUI_URL}/api/v2/auth/login" \
    -d "username=${QB_USERNAME}&password=${QB_PASSWORD}" || echo "")

if [ "$AUTH_RESPONSE" != "Ok." ]; then
    echo "Error: Failed to authenticate with qBittorrent WebUI"
    exit 1
fi

# Get current port
CURRENT_PORT=$(curl -s -b "$COOKIE_FILE" \
    "${WEBUI_URL}/api/v2/app/preferences" | jq -r '.listen_port' || echo "")

if [ -z "$CURRENT_PORT" ]; then
    echo "Error: Failed to get current port from qBittorrent"
    exit 1
fi

echo "Current qBittorrent port: $CURRENT_PORT"
echo "New port: $NEW_PORT"

if [ "$CURRENT_PORT" = "$NEW_PORT" ]; then
    echo "Port already set to $NEW_PORT, no update needed"
    exit 0
fi

# Update port in qBittorrent
PREFS=$(curl -s -b "$COOKIE_FILE" "${WEBUI_URL}/api/v2/app/preferences")
UPDATED_PREFS=$(echo "$PREFS" | jq ".listen_port = $NEW_PORT")

UPDATE_RESPONSE=$(curl -s -b "$COOKIE_FILE" -X POST \
    "${WEBUI_URL}/api/v2/app/setPreferences" \
    -H "Content-Type: application/json" \
    -d "$UPDATED_PREFS" || echo "")

if [ "$UPDATE_RESPONSE" != "Ok." ]; then
    echo "Error: Failed to update qBittorrent port"
    exit 1
fi

echo "? Updated qBittorrent port to $NEW_PORT"

# Update firewall rules in VPN namespace
# Remove old rules for current port (if different)
if [ "$CURRENT_PORT" != "$NEW_PORT" ]; then
    sudo ip netns exec "$NAMESPACE" iptables -D INPUT -p tcp --dport "$CURRENT_PORT" -j ACCEPT 2>/dev/null || true
    sudo ip netns exec "$NAMESPACE" iptables -D INPUT -p udp --dport "$CURRENT_PORT" -j ACCEPT 2>/dev/null || true
fi

# Add new rules for the new port
# Check if rules already exist
if ! sudo ip netns exec "$NAMESPACE" iptables -C INPUT -p tcp --dport "$NEW_PORT" -j ACCEPT 2>/dev/null; then
    sudo ip netns exec "$NAMESPACE" iptables -I INPUT -p tcp --dport "$NEW_PORT" -j ACCEPT
    echo "? Added TCP firewall rule for port $NEW_PORT"
fi

if ! sudo ip netns exec "$NAMESPACE" iptables -C INPUT -p udp --dport "$NEW_PORT" -j ACCEPT 2>/dev/null; then
    sudo ip netns exec "$NAMESPACE" iptables -I INPUT -p udp --dport "$NEW_PORT" -j ACCEPT
    echo "? Added UDP firewall rule for port $NEW_PORT"
fi

# Also ensure rules exist for the VPN interface specifically
if ! sudo ip netns exec "$NAMESPACE" iptables -C INPUT -p tcp -i "$VPN_INTERFACE" --dport "$NEW_PORT" -j ACCEPT 2>/dev/null; then
    sudo ip netns exec "$NAMESPACE" iptables -I INPUT -p tcp -i "$VPN_INTERFACE" --dport "$NEW_PORT" -j ACCEPT
fi

if ! sudo ip netns exec "$NAMESPACE" iptables -C INPUT -p udp -i "$VPN_INTERFACE" --dport "$NEW_PORT" -j ACCEPT 2>/dev/null; then
    sudo ip netns exec "$NAMESPACE" iptables -I INPUT -p udp -i "$VPN_INTERFACE" --dport "$NEW_PORT" -j ACCEPT
fi

echo ""
echo "? Successfully updated qBittorrent to use port $NEW_PORT"
echo "? Firewall rules updated in VPN namespace"
echo ""
echo "Note: These firewall rules are temporary and will be lost on reboot."
echo "You may need to update your configuration or create a systemd service"
echo "that runs this script when the VPN namespace starts."
