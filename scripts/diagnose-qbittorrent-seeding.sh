#!/usr/bin/env bash
# Comprehensive qBittorrent seeding diagnostic script
# Identifies why seeding might not be working

set -euo pipefail

NAMESPACE="qbittor"
WEBUI_IP="192.168.15.1"
WEBUI_PORT=8080
WEBUI_URL="http://${WEBUI_IP}:${WEBUI_PORT}"
TORRENT_PORT=6881
VPN_INTERFACE="qbittor0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

pass() { echo -e "${GREEN}?${NC} $1"; }
fail() { echo -e "${RED}?${NC} $1"; }
warn() { echo -e "${YELLOW}?${NC} $1"; }
info() { echo -e "${BLUE}?${NC} $1"; }

section() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

# Check if running as root for some operations
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

section "1. Service & VPN Namespace Status"

if systemctl is-active --quiet qbittorrent; then
    pass "qBittorrent service is running"
else
    fail "qBittorrent service is NOT running"
    echo "  Run: sudo systemctl status qbittorrent"
    exit 1
fi

if $SUDO ip netns list | grep -q "$NAMESPACE"; then
    pass "VPN namespace '$NAMESPACE' exists"
else
    fail "VPN namespace '$NAMESPACE' NOT found"
    exit 1
fi

VPN_IP=$($SUDO ip netns exec "$NAMESPACE" ip addr show "$VPN_INTERFACE" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 || echo "")
if [ -n "$VPN_IP" ]; then
    pass "VPN interface '$VPN_INTERFACE' is up (IP: $VPN_IP)"
else
    fail "VPN interface '$VPN_INTERFACE' NOT found or not configured"
    exit 1
fi

EXTERNAL_IP=$($SUDO ip netns exec "$NAMESPACE" curl -s --max-time 5 https://ipv4.icanhazip.com 2>/dev/null || echo "unknown")
if [ "$EXTERNAL_IP" != "unknown" ]; then
    pass "External IP via VPN: $EXTERNAL_IP"
else
    fail "Cannot determine external IP (VPN may not be working)"
fi

section "2. Port Binding & Listening Status"

TCP_LISTEN=$($SUDO ip netns exec "$NAMESPACE" ss -tln 2>/dev/null | grep ":$TORRENT_PORT " || true)
UDP_LISTEN=$($SUDO ip netns exec "$NAMESPACE" ss -uln 2>/dev/null | grep ":$TORRENT_PORT " || true)

if echo "$TCP_LISTEN" | grep -q ":$TORRENT_PORT"; then
    BIND_IP=$(echo "$TCP_LISTEN" | awk '{print $4}' | cut -d: -f1)
    pass "TCP port $TORRENT_PORT is listening (bound to: $BIND_IP)"

    # Check if bound to correct interface
    if [ "$BIND_IP" = "0.0.0.0" ] || [ "$BIND_IP" = "::" ]; then
        warn "Port is bound to all interfaces (should be bound to VPN interface)"
    elif [ "$BIND_IP" = "$VPN_IP" ]; then
        pass "Port is correctly bound to VPN interface IP"
    else
        warn "Port is bound to $BIND_IP (expected VPN IP: $VPN_IP)"
    fi
else
    fail "TCP port $TORRENT_PORT is NOT listening"
    info "qBittorrent may not be configured to listen on this port"
fi

if echo "$UDP_LISTEN" | grep -q ":$TORRENT_PORT"; then
    BIND_IP=$(echo "$UDP_LISTEN" | awk '{print $4}' | cut -d: -f1)
    pass "UDP (uTP) port $TORRENT_PORT is listening (bound to: $BIND_IP)"
else
    fail "UDP (uTP) port $TORRENT_PORT is NOT listening"
    info "uTP is important for BitTorrent connections"
fi

section "3. VPN Namespace Firewall Rules"

# Check iptables rules in VPN namespace
info "Checking firewall rules in VPN namespace..."
TCP_RULES=$($SUDO ip netns exec "$NAMESPACE" iptables -L INPUT -n -v 2>/dev/null | grep -i "$TORRENT_PORT" || true)
UDP_RULES=$($SUDO ip netns exec "$NAMESPACE" iptables -L INPUT -n -v 2>/dev/null | grep -i "$TORRENT_PORT" || true)

if [ -n "$TCP_RULES" ] || [ -n "$UDP_RULES" ]; then
    info "Found firewall rules for port $TORRENT_PORT:"
    [ -n "$TCP_RULES" ] && echo "  TCP: $TCP_RULES"
    [ -n "$UDP_RULES" ] && echo "  UDP: $UDP_RULES"
else
    warn "No explicit firewall rules found for port $TORRENT_PORT"
    info "Checking default policy..."

    DEFAULT_POLICY=$($SUDO ip netns exec "$NAMESPACE" iptables -L INPUT -n 2>/dev/null | grep "Chain INPUT" | awk '{print $4}' || echo "unknown")
    if [ "$DEFAULT_POLICY" = "ACCEPT" ]; then
        pass "Default INPUT policy is ACCEPT (should allow incoming connections)"
    elif [ "$DEFAULT_POLICY" = "DROP" ] || [ "$DEFAULT_POLICY" = "REJECT" ]; then
        fail "Default INPUT policy is $DEFAULT_POLICY (will block incoming connections!)"
        info "This is likely preventing seeding - need to add firewall rules"
    else
        warn "Could not determine default firewall policy"
    fi
fi

section "4. qBittorrent Configuration (via API)"

# Try to get credentials from environment or prompt
if [ -z "${QB_USERNAME:-}" ] || [ -z "${QB_PASSWORD:-}" ]; then
    warn "WebUI credentials not set (QB_USERNAME, QB_PASSWORD)"
    warn "Skipping API-based configuration checks"
    info "Set credentials to check qBittorrent settings:"
    info "  export QB_USERNAME='lewis'"
    info "  export QB_PASSWORD='your-password'"
else
    # Authenticate
    AUTH_RESPONSE=$(curl -s -c /tmp/qb_cookies.txt -b /tmp/qb_cookies.txt \
        "${WEBUI_URL}/api/v2/auth/login?username=${QB_USERNAME}&password=${QB_PASSWORD}" 2>/dev/null || echo "failed")

    if [ "$AUTH_RESPONSE" = "Ok." ]; then
        pass "WebUI API authentication successful"

        # Get preferences
        PREFS=$(curl -s -b /tmp/qb_cookies.txt "${WEBUI_URL}/api/v2/app/preferences" 2>/dev/null || echo "")

        if [ -n "$PREFS" ]; then
            # Check upload settings
            UPLOAD_LIMIT=$(echo "$PREFS" | grep -o '"up_limit":\([0-9]*\)' | grep -o '[0-9]*' || echo "0")
            if [ "$UPLOAD_LIMIT" = "0" ]; then
                pass "Upload rate limit: Unlimited"
            else
                KB_LIMIT=$(($UPLOAD_LIMIT / 1024))
                warn "Upload rate limit: ${KB_LIMIT} KB/s (may limit seeding)"
            fi

            # Check max uploads
            MAX_UPLOADS=$(echo "$PREFS" | grep -o '"max_uploads":\([0-9]*\)' | grep -o '[0-9]*' || echo "unknown")
            if [ "$MAX_UPLOADS" != "unknown" ]; then
                if [ "$MAX_UPLOADS" -eq 0 ]; then
                    fail "Max uploads: 0 (seeding is DISABLED!)"
                else
                    info "Max uploads: $MAX_UPLOADS"
                fi
            fi

            # Check max connections
            MAX_CONN=$(echo "$PREFS" | grep -o '"max_connec":\([0-9]*\)' | grep -o '[0-9]*' || echo "unknown")
            if [ "$MAX_CONN" != "unknown" ]; then
                info "Max connections: $MAX_CONN"
            fi

            # Check listen port
            LISTEN_PORT=$(echo "$PREFS" | grep -o '"listen_port":\([0-9]*\)' | grep -o '[0-9]*' || echo "unknown")
            if [ "$LISTEN_PORT" != "unknown" ]; then
                if [ "$LISTEN_PORT" = "$TORRENT_PORT" ]; then
                    pass "qBittorrent listen port: $LISTEN_PORT (matches configuration)"
                else
                    fail "qBittorrent listen port: $LISTEN_PORT (expected: $TORRENT_PORT)"
                fi
            fi

            # Check if random port is enabled
            RANDOM_PORT=$(echo "$PREFS" | grep -o '"use_upnp":\(true\|false\)' | grep -o 'true\|false' || echo "unknown")
            if [ "$RANDOM_PORT" = "true" ]; then
                warn "UPnP is enabled (may conflict with VPN port forwarding)"
            fi

            # Check interface binding
            INTERFACE=$(echo "$PREFS" | grep -o '"interface":\"[^\"]*\"' | cut -d'"' -f4 || echo "unknown")
            if [ "$INTERFACE" != "unknown" ]; then
                if [ "$INTERFACE" = "$VPN_INTERFACE" ] || [ "$INTERFACE" = "any" ] || [ "$INTERFACE" = "" ]; then
                    info "Interface binding: $INTERFACE"
                else
                    warn "Interface binding: $INTERFACE (expected: $VPN_INTERFACE or any)"
                fi
            fi

            # Check DHT, PeX, LSD
            DHT=$(echo "$PREFS" | grep -o '"dht":\(true\|false\)' | grep -o 'true\|false' || echo "unknown")
            PEX=$(echo "$PREFS" | grep -o '"pex":\(true\|false\)' | grep -o 'true\|false' || echo "unknown")
            LSD=$(echo "$PREFS" | grep -o '"lsd":\(true\|false\)' | grep -o 'true\|false' || echo "unknown")

            [ "$DHT" = "true" ] && pass "DHT enabled" || warn "DHT disabled"
            [ "$PEX" = "true" ] && pass "PeX enabled" || warn "PeX disabled"
            [ "$LSD" = "true" ] && pass "LSD enabled" || warn "LSD disabled"

            # Get torrent stats
            TORRENTS=$(curl -s -b /tmp/qb_cookies.txt "${WEBUI_URL}/api/v2/torrents/info" 2>/dev/null || echo "[]")
            if [ "$TORRENTS" != "[]" ] && [ -n "$TORRENTS" ]; then
                SEEDING=$(echo "$TORRENTS" | grep -o '"state":"seeding"' | wc -l || echo "0")
                COMPLETED=$(echo "$TORRENTS" | grep -o '"state":"uploading\|seeding\|stalledUP"' | wc -l || echo "0")
                info "Torrents: $SEEDING seeding, $COMPLETED completed"

                if [ "$SEEDING" -eq 0 ] && [ "$COMPLETED" -gt 0 ]; then
                    warn "You have completed torrents but none are seeding"
                    info "Check if torrents are paused or have upload limits"
                fi
            fi

            # Get global stats
            SYNC=$(curl -s -b /tmp/qb_cookies.txt "${WEBUI_URL}/api/v2/sync/maindata?rid=0" 2>/dev/null || echo "")
            if [ -n "$SYNC" ]; then
                PEERS=$(echo "$SYNC" | grep -o '"nb_connections":\([0-9]*\)' | grep -o '[0-9]*' || echo "0")
                if [ "$PEERS" -gt 0 ]; then
                    pass "Connected peers: $PEERS"
                else
                    warn "No peers connected (this is the seeding problem!)"
                fi
            fi
        fi

        rm -f /tmp/qb_cookies.txt
    else
        fail "WebUI API authentication failed"
    fi
fi

section "5. Port Forwarding Status"

if [ "$EXTERNAL_IP" != "unknown" ]; then
    info "External IP: $EXTERNAL_IP"
    info "Port: $TORRENT_PORT"
    echo ""
    warn "Port forwarding cannot be automatically verified"
    info "To check if port forwarding is working:"
    echo "  1. Visit: https://www.yougetsignal.com/tools/open-ports/"
    echo "  2. Enter IP: $EXTERNAL_IP"
    echo "  3. Enter Port: $TORRENT_PORT"
    echo "  4. Click 'Check'"
    echo ""
    info "If the port is closed, you need to:"
    echo "  - Enable port forwarding in ProtonVPN dashboard"
    echo "  - Ensure the forwarded port matches: $TORRENT_PORT"
    echo "  - Restart qBittorrent after enabling port forwarding"
else
    fail "Cannot check port forwarding (no external IP)"
fi

section "6. Network Connectivity Tests"

# Test outbound connectivity
if $SUDO ip netns exec "$NAMESPACE" timeout 3 bash -c "echo > /dev/tcp/8.8.8.8/53" 2>/dev/null; then
    pass "Outbound TCP connectivity works"
else
    fail "Outbound TCP connectivity FAILED"
fi

if echo "test" | $SUDO ip netns exec "$NAMESPACE" timeout 3 nc -u -w 1 8.8.8.8 53 2>/dev/null; then
    pass "Outbound UDP connectivity works"
else
    fail "Outbound UDP connectivity FAILED"
fi

# Check routing
DEFAULT_ROUTE=$($SUDO ip netns exec "$NAMESPACE" ip route show default 2>/dev/null | awk '{print $3}' || echo "")
if [ "$DEFAULT_ROUTE" = "$VPN_INTERFACE" ]; then
    pass "Traffic is routed through VPN interface"
else
    warn "Default route via $DEFAULT_ROUTE (expected: $VPN_INTERFACE)"
fi

section "7. Summary & Recommendations"

echo ""
info "Common issues preventing seeding:"
echo "  1. Port forwarding not enabled in VPN provider (ProtonVPN)"
echo "  2. VPN namespace firewall blocking incoming connections"
echo "  3. qBittorrent max uploads set to 0"
echo "  4. Upload rate limit too low"
echo "  5. Port not properly forwarded through VPN"
echo ""
info "Next steps:"
echo "  1. Verify port forwarding in ProtonVPN dashboard"
echo "  2. Check VPN namespace firewall rules (see section 3)"
echo "  3. Review qBittorrent settings (see section 4)"
echo "  4. Test external port accessibility"
echo ""
