#!/usr/bin/env bash
# Comprehensive qBittorrent seeding health check
# Tests service status, WebUI access, API connectivity, and seeding metrics

set -euo pipefail

NAMESPACE="qbittor"
WEBUI_IP="192.168.15.1"
WEBUI_PORT=8080
WEBUI_URL="http://${WEBUI_IP}:${WEBUI_PORT}"
TORRENT_PORT=6881
VPN_INTERFACE="qbittor0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Helper functions
pass() {
    echo -e "${GREEN}?${NC} $1"
    ((PASSED++)) || true
}

fail() {
    echo -e "${RED}?${NC} $1"
    ((FAILED++)) || true
}

warn() {
    echo -e "${YELLOW}?${NC} $1"
    ((WARNINGS++)) || true
}

info() {
    echo -e "${BLUE}?${NC} $1"
}

section() {
    echo ""
    echo "=========================================="
    echo "$1"
    echo "=========================================="
}

# Check if qBittorrent WebUI credentials are available
check_credentials() {
    # Try to get credentials from systemd service environment or config
    # For now, we'll prompt or use environment variables
    if [ -z "${QB_USERNAME:-}" ] || [ -z "${QB_PASSWORD:-}" ]; then
        warn "WebUI credentials not set in environment (QB_USERNAME, QB_PASSWORD)"
        warn "Some checks will be skipped. Set credentials to enable full API checks."
        return 1
    fi
    return 0
}

# Authenticate with qBittorrent WebUI API
authenticate() {
    local username="${QB_USERNAME:-}"
    local password="${QB_PASSWORD:-}"

    if [ -z "$username" ] || [ -z "$password" ]; then
        return 1
    fi

    # Get CSRF token and authenticate
    local response=$(curl -s -c /tmp/qb_cookies.txt -b /tmp/qb_cookies.txt \
        "${WEBUI_URL}/api/v2/auth/login?username=${username}&password=${password}" 2>/dev/null || echo "failed")

    if [ "$response" = "Ok." ]; then
        return 0
    else
        return 1
    fi
}

# Make authenticated API call
api_call() {
    local endpoint="$1"
    curl -s -b /tmp/qb_cookies.txt "${WEBUI_URL}/api/v2/${endpoint}" 2>/dev/null || echo ""
}

echo "=========================================="
echo "qBittorrent Seeding Health Check"
echo "=========================================="
echo ""

# 1. Service Status Check
section "Service Status"

if systemctl is-active --quiet qbittorrent; then
    pass "qBittorrent service is running"
    info "Service status: $(systemctl is-active qbittorrent)"
else
    fail "qBittorrent service is not running"
    info "Run: sudo systemctl status qbittorrent"
fi

# 2. VPN Namespace Check
section "VPN Namespace"

if sudo ip netns list | grep -q "$NAMESPACE"; then
    pass "VPN namespace '$NAMESPACE' exists"
else
    fail "VPN namespace '$NAMESPACE' not found"
fi

# 3. VPN Interface Check
if sudo ip netns exec "$NAMESPACE" ip addr show "$VPN_INTERFACE" &>/dev/null; then
    VPN_IP=$(sudo ip netns exec "$NAMESPACE" ip addr show "$VPN_INTERFACE" | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    pass "VPN interface '$VPN_INTERFACE' is up (IP: $VPN_IP)"
else
    fail "VPN interface '$VPN_INTERFACE' not found"
fi

# 4. External IP Check
EXTERNAL_IP=$(sudo ip netns exec "$NAMESPACE" curl -s --max-time 5 https://ipv4.icanhazip.com 2>/dev/null || echo "unknown")
if [ "$EXTERNAL_IP" != "unknown" ]; then
    pass "External IP: $EXTERNAL_IP (via VPN)"
else
    fail "Cannot determine external IP"
fi

# 5. Port Binding Check
section "Port Binding"

TCP_LISTEN=$(sudo ip netns exec "$NAMESPACE" ss -tln | grep ":$TORRENT_PORT " || true)
UDP_LISTEN=$(sudo ip netns exec "$NAMESPACE" ss -uln | grep ":$TORRENT_PORT " || true)

if echo "$TCP_LISTEN" | grep -q ":$TORRENT_PORT"; then
    BIND_IP=$(echo "$TCP_LISTEN" | awk '{print $4}' | cut -d: -f1)
    pass "TCP port $TORRENT_PORT is listening (bound to: $BIND_IP)"
else
    fail "TCP port $TORRENT_PORT is NOT listening"
fi

if echo "$UDP_LISTEN" | grep -q ":$TORRENT_PORT"; then
    BIND_IP=$(echo "$UDP_LISTEN" | awk '{print $4}' | cut -d: -f1)
    pass "UDP (uTP) port $TORRENT_PORT is listening (bound to: $BIND_IP)"
else
    fail "UDP (uTP) port $TORRENT_PORT is NOT listening"
fi

# 6. WebUI Accessibility
section "WebUI Accessibility"

if curl -s --max-time 3 "${WEBUI_URL}" > /dev/null 2>&1; then
    pass "WebUI is accessible at ${WEBUI_URL}"
else
    fail "WebUI is not accessible at ${WEBUI_URL}"
    info "Check if WebUI is bound to the correct IP and port"
fi

# 7. API Authentication & Configuration
section "qBittorrent API & Configuration"

if check_credentials; then
    if authenticate; then
        pass "WebUI API authentication successful"

        # Get application version
        VERSION=$(api_call "app/version")
        if [ -n "$VERSION" ]; then
            info "qBittorrent version: $VERSION"
        fi

        # Get preferences
        PREFS=$(api_call "app/preferences")

        # Check DHT status
        if echo "$PREFS" | grep -q '"dht":true'; then
            pass "DHT (Distributed Hash Table) is enabled"
        else
            warn "DHT is disabled (may reduce peer discovery)"
        fi

        # Check PeX status
        if echo "$PREFS" | grep -q '"pex":true'; then
            pass "PeX (Peer Exchange) is enabled"
        else
            warn "PeX is disabled (may reduce peer discovery)"
        fi

        # Check LSD status
        if echo "$PREFS" | grep -q '"lsd":true'; then
            pass "LSD (Local Service Discovery) is enabled"
        else
            warn "LSD is disabled (may reduce local peer discovery)"
        fi

        # Check upload rate limit
        UPLOAD_LIMIT=$(echo "$PREFS" | grep -o '"up_limit":\([0-9]*\)' | grep -o '[0-9]*' || echo "0")
        if [ "$UPLOAD_LIMIT" = "0" ]; then
            pass "Upload rate limit: Unlimited"
        else
            info "Upload rate limit: $UPLOAD_LIMIT bytes/s ($(($UPLOAD_LIMIT / 1024)) KB/s)"
        fi

        # Check port forwarding status
        PORT_FORWARDING=$(echo "$PREFS" | grep -o '"upnp":\(true\|false\)' | grep -o 'true\|false' || echo "unknown")
        if [ "$PORT_FORWARDING" = "true" ]; then
            info "UPnP/NAT-PMP port forwarding: Enabled"
        else
            info "UPnP/NAT-PMP port forwarding: Disabled (using VPN port forwarding)"
        fi

        # Get transfer info
        TRANSFER_INFO=$(api_call "transfer/info")
        if [ -n "$TRANSFER_INFO" ]; then
            DL_SPEED=$(echo "$TRANSFER_INFO" | grep -o '"dl_info_speed":\([0-9]*\)' | grep -o '[0-9]*' || echo "0")
            UL_SPEED=$(echo "$TRANSFER_INFO" | grep -o '"up_info_speed":\([0-9]*\)' | grep -o '[0-9]*' || echo "0")

            if [ "$UL_SPEED" -gt 0 ]; then
                pass "Current upload speed: $(($UL_SPEED / 1024)) KB/s"
            else
                warn "No current upload activity"
            fi

            if [ "$DL_SPEED" -gt 0 ]; then
                info "Current download speed: $(($DL_SPEED / 1024)) KB/s"
            fi
        fi

        # Get torrent list
        TORRENTS=$(api_call "torrents/info")
        if [ -n "$TORRENTS" ] && [ "$TORRENTS" != "[]" ]; then
            TOTAL_TORRENTS=$(echo "$TORRENTS" | grep -o '"hash"' | wc -l || echo "0")
            info "Total torrents: $TOTAL_TORRENTS"

            # Count seeding torrents
            SEEDING_COUNT=$(echo "$TORRENTS" | grep -o '"state":"seeding"' | wc -l || echo "0")
            if [ "$SEEDING_COUNT" -gt 0 ]; then
                pass "Active seeding torrents: $SEEDING_COUNT"
            else
                warn "No torrents currently seeding"
            fi

            # Count completed torrents
            COMPLETED_COUNT=$(echo "$TORRENTS" | grep -o '"state":"uploading\|seeding\|stalledUP"' | wc -l || echo "0")
            info "Completed/uploading torrents: $COMPLETED_COUNT"

            # Get detailed seeding stats
            if [ "$SEEDING_COUNT" -gt 0 ]; then
                echo ""
                info "Seeding Statistics:"

                # Calculate total upload
                TOTAL_UPLOADED=0
                TOTAL_SIZE=0
                while IFS= read -r torrent; do
                    if echo "$torrent" | grep -q '"state":"seeding"'; then
                        UPLOADED=$(echo "$torrent" | grep -o '"uploaded":\([0-9]*\)' | grep -o '[0-9]*' || echo "0")
                        SIZE=$(echo "$torrent" | grep -o '"size":\([0-9]*\)' | grep -o '[0-9]*' || echo "0")
                        TOTAL_UPLOADED=$((TOTAL_UPLOADED + UPLOADED))
                        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
                    fi
                done <<< "$(echo "$TORRENTS" | sed 's/},{/}\n{/g')"

                if [ "$TOTAL_SIZE" -gt 0 ]; then
                    # Calculate ratio using awk
                    RATIO=$(awk "BEGIN {printf \"%.2f\", $TOTAL_UPLOADED / $TOTAL_SIZE}")
                    info "  Total uploaded: $(($TOTAL_UPLOADED / 1024 / 1024 / 1024)) GB"
                    info "  Total size: $(($TOTAL_SIZE / 1024 / 1024 / 1024)) GB"
                    info "  Upload ratio: ${RATIO}x"
                fi
            fi

            # Check for tracker errors
            TRACKER_ERRORS=0
            while IFS= read -r torrent; do
                HASH=$(echo "$torrent" | grep -o '"hash":"[^"]*"' | cut -d'"' -f4)
                if [ -n "$HASH" ]; then
                    TRACKERS=$(api_call "torrents/trackers?hash=${HASH}")
                    if echo "$TRACKERS" | grep -q '"status":4'; then
                        ((TRACKER_ERRORS++)) || true
                    fi
                fi
            done <<< "$(echo "$TORRENTS" | sed 's/},{/}\n{/g' | head -10)"

            if [ "$TRACKER_ERRORS" -gt 0 ]; then
                warn "Some trackers have errors ($TRACKER_ERRORS torrents affected)"
            else
                pass "No tracker errors detected"
            fi
        else
            warn "No torrents found in qBittorrent"
        fi

        # Get global peer stats
        GLOBAL_STATS=$(api_call "sync/maindata?rid=0")
        if [ -n "$GLOBAL_STATS" ]; then
            PEERS_CONNECTED=$(echo "$GLOBAL_STATS" | grep -o '"nb_connections":\([0-9]*\)' | grep -o '[0-9]*' || echo "0")
            if [ "$PEERS_CONNECTED" -gt 0 ]; then
                pass "Connected peers: $PEERS_CONNECTED"
            else
                warn "No peers currently connected"
            fi
        fi

    else
        fail "WebUI API authentication failed"
        info "Check QB_USERNAME and QB_PASSWORD environment variables"
    fi
else
    warn "Skipping API checks (credentials not available)"
    info "Set QB_USERNAME and QB_PASSWORD environment variables for full checks"
fi

# 8. Port Forwarding Test (External)
section "Port Forwarding Test"

if [ "$EXTERNAL_IP" != "unknown" ]; then
    info "Testing external port accessibility..."
    info "External IP: $EXTERNAL_IP"
    info "Port: $TORRENT_PORT"
    info ""
    info "To test port forwarding externally, use one of these services:"
    info "  - https://www.yougetsignal.com/tools/open-ports/"
    info "  - https://canyouseeme.org/"
    info "  - https://www.portchecker.co/"
    info ""
    info "Or from another machine:"
    info "  telnet $EXTERNAL_IP $TORRENT_PORT"
    info "  nc -zv $EXTERNAL_IP $TORRENT_PORT"
    warn "External port forwarding cannot be automatically verified"
    warn "Check ProtonVPN dashboard for port forwarding status"
else
    warn "Cannot test external port forwarding (no external IP)"
fi

# 9. Network Connectivity
section "Network Connectivity"

if sudo ip netns exec "$NAMESPACE" timeout 3 bash -c "echo > /dev/tcp/8.8.8.8/53" 2>/dev/null; then
    pass "TCP outbound connectivity works"
else
    fail "TCP outbound connectivity FAILED"
fi

if echo "test" | sudo ip netns exec "$NAMESPACE" timeout 3 nc -u -w 1 8.8.8.8 53 2>/dev/null; then
    pass "UDP outbound connectivity works"
else
    fail "UDP outbound connectivity FAILED"
fi

if sudo ip netns exec "$NAMESPACE" ping -c 2 -W 2 8.8.8.8 &>/dev/null; then
    pass "ICMP (ping) connectivity works"
else
    warn "ICMP (ping) connectivity failed (may be blocked by VPN)"
fi

# 10. Routing Check
section "Routing"

DEFAULT_ROUTE=$(sudo ip netns exec "$NAMESPACE" ip route show default | awk '{print $3}' || echo "")
if [ -n "$DEFAULT_ROUTE" ]; then
    if [ "$DEFAULT_ROUTE" = "$VPN_INTERFACE" ]; then
        pass "Traffic is routed through VPN interface"
    else
        warn "Default route via $DEFAULT_ROUTE (expected: $VPN_INTERFACE)"
    fi
else
    fail "No default route found"
fi

# Cleanup
rm -f /tmp/qb_cookies.txt

# Summary
section "Summary"

TOTAL=$((PASSED + FAILED + WARNINGS))
echo "Passed:  $PASSED"
echo "Failed:  $FAILED"
echo "Warnings: $WARNINGS"
echo ""

if [ "$FAILED" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo -e "${GREEN}? All checks passed! qBittorrent seeding health is good.${NC}"
    exit 0
elif [ "$FAILED" -eq 0 ]; then
    echo -e "${YELLOW}? Some warnings, but no critical failures.${NC}"
    exit 0
else
    echo -e "${RED}? Some checks failed. Please review the issues above.${NC}"
    exit 1
fi
