#!/usr/bin/env bash
# Quick port forwarding verification
# Tests key aspects of ProtonVPN port forwarding for qBittorrent

set -euo pipefail

# Configuration
NAMESPACE="${NAMESPACE:-qbt}"
VPN_GATEWAY="${VPN_GATEWAY:-10.2.0.1}"
QBITTORRENT_CONFIG="/var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}????????????????????????????????????????${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}????????????????????????????????????????${NC}"
}

print_success() {
    echo -e "${GREEN}?${NC} $1"
}

print_error() {
    echo -e "${RED}?${NC} $1"
}

print_info() {
    echo -e "  ${BLUE}?${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}?${NC} $1"
}

# Track overall status
ERRORS=0

print_header "Quick Port Forwarding Verification"

# 1. Get ProtonVPN assigned port
echo ""
echo "1. Checking ProtonVPN assigned port..."
PROTONVPN_PORT=$(sudo ip netns exec "$NAMESPACE" natpmpc -a 1 0 tcp 60 -g "$VPN_GATEWAY" 2>/dev/null | grep 'Mapped public port' | awk '{print $4}' || echo "")

if [[ -n "$PROTONVPN_PORT" && "$PROTONVPN_PORT" -gt 0 ]]; then
    print_success "ProtonVPN assigned port: $PROTONVPN_PORT"
else
    print_error "Failed to get ProtonVPN port"
    ERRORS=$((ERRORS + 1))
fi

# 2. Check qBittorrent's configured port
echo ""
echo "2. Checking qBittorrent configured port..."
QBITTORRENT_PORT=$(sudo grep 'Session\\Port' "$QBITTORRENT_CONFIG" 2>/dev/null | cut -d'=' -f2 || echo "")

if [[ -n "$QBITTORRENT_PORT" ]]; then
    print_success "qBittorrent configured port: $QBITTORRENT_PORT"
else
    print_error "Failed to read qBittorrent port from config"
    ERRORS=$((ERRORS + 1))
fi

# 3. Compare ports
echo ""
echo "3. Comparing ports..."
if [[ -n "$PROTONVPN_PORT" && -n "$QBITTORRENT_PORT" ]]; then
    if [[ "$PROTONVPN_PORT" == "$QBITTORRENT_PORT" ]]; then
        print_success "Ports match! ($PROTONVPN_PORT)"
    else
        print_error "Port mismatch!"
        print_info "ProtonVPN: $PROTONVPN_PORT"
        print_info "qBittorrent: $QBITTORRENT_PORT"
        print_warning "Run: sudo systemctl start protonvpn-portforward.service"
        ERRORS=$((ERRORS + 1))
    fi
fi

# 4. Check if qBittorrent is listening
echo ""
echo "4. Checking if qBittorrent is listening..."
if [[ -n "$QBITTORRENT_PORT" ]]; then
    if sudo ip netns exec "$NAMESPACE" ss -tulnp 2>/dev/null | grep -q ":$QBITTORRENT_PORT "; then
        print_success "qBittorrent is listening on port $QBITTORRENT_PORT"

        # Show what's listening
        LISTENER=$(sudo ip netns exec "$NAMESPACE" ss -tulnp 2>/dev/null | grep ":$QBITTORRENT_PORT " | head -1)
        print_info "$LISTENER"
    else
        print_error "qBittorrent is NOT listening on port $QBITTORRENT_PORT"
        ERRORS=$((ERRORS + 1))
    fi
fi

# 5. Check port forwarding service
echo ""
echo "5. Checking port forwarding service..."
if systemctl is-active --quiet protonvpn-portforward.timer; then
    print_success "Timer is active"

    # Show next run time
    NEXT_RUN=$(systemctl status protonvpn-portforward.timer 2>/dev/null | grep "Trigger:" | sed 's/.*Trigger: //' || echo "Unknown")
    print_info "Next run: $NEXT_RUN"
else
    print_warning "Timer is not active"
    print_info "Enable with: sudo systemctl enable --now protonvpn-portforward.timer"
fi

# Check service status
if systemctl show protonvpn-portforward.service -p ActiveState --value | grep -q "active"; then
    print_info "Service is currently running"
elif systemctl show protonvpn-portforward.service -p SubState --value | grep -q "dead"; then
    LAST_RUN=$(systemctl show protonvpn-portforward.service -p ExecMainExitTimestamp --value)
    if [[ -n "$LAST_RUN" && "$LAST_RUN" != "n/a" ]]; then
        print_info "Last completed: $LAST_RUN"
    fi
fi

# 6. Check external IP
echo ""
echo "6. Checking external IP..."
EXTERNAL_IP=$(sudo ip netns exec "$NAMESPACE" curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "")

if [[ -n "$EXTERNAL_IP" ]]; then
    print_success "External IP: $EXTERNAL_IP"
    print_warning "Verify this is a ProtonVPN IP (not your real IP)"

    if [[ -n "$PROTONVPN_PORT" ]]; then
        print_info "Test port at: https://www.yougetsignal.com/tools/open-ports/"
        print_info "IP: $EXTERNAL_IP, Port: $PROTONVPN_PORT"
    fi
else
    print_error "Failed to get external IP"
    ERRORS=$((ERRORS + 1))
fi

# 7. Check qBittorrent service
echo ""
echo "7. Checking qBittorrent service..."
if systemctl is-active --quiet qbittorrent.service; then
    print_success "qBittorrent service is running"

    # Show uptime
    UPTIME=$(systemctl show qbittorrent.service -p ActiveEnterTimestamp --value)
    print_info "Started: $UPTIME"
else
    print_error "qBittorrent service is not running"
    print_info "Start with: sudo systemctl start qbittorrent.service"
    ERRORS=$((ERRORS + 1))
fi

# Summary
print_header "Summary"

if [[ $ERRORS -eq 0 ]]; then
    echo ""
    print_success "All checks passed! Port forwarding is working correctly."
    echo ""
    echo "Quick access:"
    print_info "WebUI: http://192.168.2.249:8080 (or https://torrent.blmt.io)"
    print_info "External test: https://www.yougetsignal.com/tools/open-ports/"

    if [[ -n "$PROTONVPN_PORT" ]]; then
        echo ""
        echo "Port forwarding details:"
        print_info "Forwarded port: $PROTONVPN_PORT"
        print_info "Auto-renewal: Every 45 minutes"
        print_info "Monitor: ./scripts/monitor-protonvpn-portforward.sh"
    fi

    exit 0
else
    echo ""
    print_error "Found $ERRORS issue(s)"
    echo ""
    echo "Troubleshooting steps:"
    print_info "1. Run full verification: ./scripts/verify-qbittorrent-vpn.sh"
    print_info "2. Check logs: journalctl -u protonvpn-portforward.service -n 20"
    print_info "3. Manual update: sudo systemctl start protonvpn-portforward.service"
    print_info "4. Full monitoring: ./scripts/monitor-protonvpn-portforward.sh"

    exit 1
fi
