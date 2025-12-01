#!/usr/bin/env bash
# Check if port 64243 is correctly configured and accessible for Transmission and qBittorrent
# This script verifies both VPN port forwarding and client configurations

set -euo pipefail

# Configuration
TARGET_PORT=64243
NAMESPACE="${NAMESPACE:-qbt}"
VPN_GATEWAY="${VPN_GATEWAY:-10.2.0.1}"
QBITTORRENT_CONFIG="/var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf"
TRANSMISSION_CONFIG="/var/lib/transmission/.config/transmission-daemon/settings.json"
PORTFORWARD_STATE="/var/lib/protonvpn-portforward.state"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Status tracking
ERRORS=0
WARNINGS=0

print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${CYAN}▶ $1${NC}"
}

print_success() {
    echo -e "  ${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "  ${RED}✗${NC} $1"
    ((ERRORS++))
}

print_warning() {
    echo -e "  ${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

print_info() {
    echo -e "    ${BLUE}ℹ${NC} $1"
}

# Check if namespace exists
check_namespace() {
    print_section "1. VPN Namespace Check"

    if sudo ip netns list | grep -q "^${NAMESPACE}"; then
        print_success "VPN namespace '${NAMESPACE}' exists"

        # Check if VPN interface is up
        if sudo ip netns exec "${NAMESPACE}" ip addr show qbt0 &>/dev/null; then
            local vpn_ip
            vpn_ip=$(sudo ip netns exec "${NAMESPACE}" ip addr show qbt0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
            print_success "VPN interface 'qbt0' is up (IP: ${vpn_ip})"
        else
            print_error "VPN interface 'qbt0' not found"
            return 1
        fi
    else
        print_error "VPN namespace '${NAMESPACE}' not found"
        print_info "The VPN namespace is required for torrent clients"
        return 1
    fi
}

# Check ProtonVPN port forwarding
check_protonvpn_port() {
    print_section "2. ProtonVPN Port Forwarding"

    # Check if natpmpc is available
    if ! command -v natpmpc &>/dev/null; then
        print_error "natpmpc not found (needed for NAT-PMP queries)"
        print_info "Install with: nix-shell -p libnatpmp"
        return 1
    fi

    # Query current forwarded port
    print_info "Querying ProtonVPN for currently assigned port..."
    local forwarded_port
    forwarded_port=$(sudo ip netns exec "${NAMESPACE}" natpmpc -a 1 0 tcp 60 -g "${VPN_GATEWAY}" 2>&1 | \
        grep -oP 'Mapped public port \K[0-9]+' || echo "0")

    if [[ "$forwarded_port" -gt 0 ]]; then
        if [[ "$forwarded_port" == "$TARGET_PORT" ]]; then
            print_success "ProtonVPN currently forwarding port: ${forwarded_port} ✓ (matches target)"
        else
            print_warning "ProtonVPN forwarding port: ${forwarded_port} ✗ (target: ${TARGET_PORT})"
            print_info "ProtonVPN dynamically assigns ports - you cannot request a specific port"
            print_info "The automatic port forwarding service will update clients with assigned port"
        fi

        # Save for later comparison
        echo "$forwarded_port" > /tmp/protonvpn_current_port
    else
        print_error "Failed to query ProtonVPN NAT-PMP"
        print_info "Check VPN connection and ProtonVPN account has port forwarding enabled"
        return 1
    fi

    # Check state file
    if [[ -f "$PORTFORWARD_STATE" ]]; then
        local state_port
        state_port=$(grep "PUBLIC_PORT=" "$PORTFORWARD_STATE" | cut -d= -f2)
        if [[ -n "$state_port" ]]; then
            print_info "Last recorded state: port ${state_port}"
            if [[ "$state_port" != "$forwarded_port" ]]; then
                print_warning "State file port (${state_port}) differs from current (${forwarded_port})"
            fi
        fi
    fi
}

# Check qBittorrent configuration
check_qbittorrent() {
    print_section "3. qBittorrent Configuration"

    # Check service status
    if systemctl is-active --quiet qbittorrent.service; then
        print_success "qBittorrent service is running"
    else
        print_error "qBittorrent service is NOT running"
        print_info "Start with: sudo systemctl start qbittorrent.service"
        return 1
    fi

    # Check config file
    if [[ ! -f "$QBITTORRENT_CONFIG" ]]; then
        print_error "qBittorrent config not found at: ${QBITTORRENT_CONFIG}"
        return 1
    fi

    # Check configured port
    local qb_port
    qb_port=$(sudo grep "^Session\\\\Port=" "$QBITTORRENT_CONFIG" 2>/dev/null | cut -d'=' -f2 || echo "0")

    if [[ "$qb_port" -gt 0 ]]; then
        if [[ "$qb_port" == "$TARGET_PORT" ]]; then
            print_success "qBittorrent configured port: ${qb_port} ✓ (matches target)"
        else
            print_warning "qBittorrent configured port: ${qb_port} ✗ (target: ${TARGET_PORT})"

            # Compare with ProtonVPN port
            if [[ -f /tmp/protonvpn_current_port ]]; then
                local vpn_port
                vpn_port=$(cat /tmp/protonvpn_current_port)
                if [[ "$qb_port" == "$vpn_port" ]]; then
                    print_info "Port matches ProtonVPN assignment (${vpn_port})"
                    print_info "ProtonVPN assigns ports dynamically - this is expected"
                else
                    print_error "Port mismatch! qBittorrent: ${qb_port}, ProtonVPN: ${vpn_port}"
                    print_info "Run: sudo systemctl start protonvpn-portforward.service"
                fi
            fi
        fi
    else
        print_error "Could not read qBittorrent port from config"
    fi

    # Check interface binding
    local qb_interface
    qb_interface=$(sudo grep "^Session\\\\InterfaceName=" "$QBITTORRENT_CONFIG" 2>/dev/null | cut -d'=' -f2 || echo "")

    if [[ "$qb_interface" == "qbt0" ]]; then
        print_success "Interface binding correct: qbt0 (VPN)"
    else
        print_error "Interface binding incorrect: ${qb_interface} (expected: qbt0)"
        print_info "qBittorrent must bind to VPN interface"
    fi

    # Check if listening
    if [[ "$qb_port" -gt 0 ]]; then
        if sudo ip netns exec "${NAMESPACE}" ss -tuln 2>/dev/null | grep -q ":${qb_port} "; then
            print_success "qBittorrent is listening on port ${qb_port}"

            # Show protocol details
            if sudo ip netns exec "${NAMESPACE}" ss -tln 2>/dev/null | grep -q ":${qb_port} "; then
                print_info "TCP: Listening ✓"
            fi
            if sudo ip netns exec "${NAMESPACE}" ss -uln 2>/dev/null | grep -q ":${qb_port} "; then
                print_info "UDP: Listening ✓"
            fi
        else
            print_error "qBittorrent is NOT listening on port ${qb_port}"
            print_info "May need to restart qBittorrent service"
        fi
    fi
}

# Check Transmission configuration
check_transmission() {
    print_section "4. Transmission Configuration"

    # Check service status
    if systemctl is-active --quiet transmission.service; then
        print_success "Transmission service is running"
    elif systemctl list-unit-files transmission.service &>/dev/null; then
        print_warning "Transmission service exists but is not running"
        print_info "Start with: sudo systemctl start transmission.service"
        return 0  # Non-fatal, user may not use Transmission
    else
        print_info "Transmission service not configured (skipping)"
        return 0  # Not an error if not installed
    fi

    # Check config file
    if [[ ! -f "$TRANSMISSION_CONFIG" ]]; then
        print_warning "Transmission config not found at: ${TRANSMISSION_CONFIG}"
        return 0
    fi

    # Transmission service needs to be stopped to read settings.json safely
    local tr_port
    tr_port=$(sudo grep '"peer-port"' "$TRANSMISSION_CONFIG" 2>/dev/null | grep -oP '\d+' || echo "0")

    if [[ "$tr_port" -gt 0 ]]; then
        if [[ "$tr_port" == "$TARGET_PORT" ]]; then
            print_success "Transmission configured port: ${tr_port} ✓ (matches target)"
        else
            print_warning "Transmission configured port: ${tr_port} ✗ (target: ${TARGET_PORT})"

            # Compare with ProtonVPN port
            if [[ -f /tmp/protonvpn_current_port ]]; then
                local vpn_port
                vpn_port=$(cat /tmp/protonvpn_current_port)
                if [[ "$tr_port" == "$vpn_port" ]]; then
                    print_info "Port matches ProtonVPN assignment (${vpn_port})"
                else
                    print_error "Port mismatch! Transmission: ${tr_port}, ProtonVPN: ${vpn_port}"
                fi
            fi
        fi
    else
        print_warning "Could not read Transmission port from config"
    fi

    # Check if listening
    if [[ "$tr_port" -gt 0 ]]; then
        if sudo ip netns exec "${NAMESPACE}" ss -tuln 2>/dev/null | grep -q ":${tr_port} "; then
            print_success "Transmission is listening on port ${tr_port}"
        else
            print_warning "Transmission is NOT listening on port ${tr_port}"
        fi
    fi
}

# Check external connectivity
check_external_ip() {
    print_section "5. External IP & VPN Verification"

    # Get external IP from namespace
    local external_ip
    external_ip=$(sudo ip netns exec "${NAMESPACE}" curl -s --max-time 10 https://api.ipify.org 2>/dev/null || echo "")

    if [[ -n "$external_ip" ]]; then
        print_success "External IP (via VPN): ${external_ip}"
        print_warning "IMPORTANT: Verify this is NOT your real IP!"
        print_info "Check at: https://www.whatismyip.com/"
    else
        print_error "Cannot determine external IP"
        print_info "VPN connection may be down"
    fi
}

# Check port forwarding service
check_portforward_service() {
    print_section "6. Automatic Port Forwarding Service"

    # Check timer
    if systemctl is-active --quiet protonvpn-portforward.timer; then
        print_success "Port forwarding timer is active"

        # Show next run
        local next_run
        next_run=$(systemctl status protonvpn-portforward.timer 2>/dev/null | \
            grep "Trigger:" | sed 's/.*Trigger: //' || echo "Unknown")
        print_info "Next renewal: ${next_run}"
    else
        print_error "Port forwarding timer is NOT active"
        print_info "Enable with: sudo systemctl enable --now protonvpn-portforward.timer"
    fi

    # Check last service run
    if systemctl show protonvpn-portforward.service -p ExecMainExitTimestamp --value | grep -qv "n/a"; then
        local last_run
        last_run=$(systemctl show protonvpn-portforward.service -p ExecMainExitTimestamp --value)
        print_info "Last completed: ${last_run}"
    fi
}

# Test external port accessibility
test_external_port() {
    print_section "7. External Port Accessibility Test"

    local test_port="$TARGET_PORT"

    # Use ProtonVPN assigned port if different
    if [[ -f /tmp/protonvpn_current_port ]]; then
        test_port=$(cat /tmp/protonvpn_current_port)
    fi

    local external_ip
    external_ip=$(sudo ip netns exec "${NAMESPACE}" curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "")

    if [[ -n "$external_ip" ]]; then
        print_info "Manual test required - checking from external network:"
        echo ""
        echo -e "    ${CYAN}Test URL:${NC} https://www.yougetsignal.com/tools/open-ports/"
        echo -e "    ${CYAN}IP Address:${NC} ${external_ip}"
        echo -e "    ${CYAN}Port:${NC} ${test_port}"
        echo ""
        print_info "Or use: curl -s 'https://www.yougetsignal.com/tools/open-ports/' \\"
        print_info "  --data 'remoteAddress=${external_ip}&portNumber=${test_port}'"
    else
        print_error "Cannot test - external IP unknown"
    fi
}

# Provide recommendations
provide_recommendations() {
    print_header "Recommendations"

    if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
        echo -e "${GREEN}✓ All checks passed! Port ${TARGET_PORT} appears to be correctly configured.${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Test external accessibility using the link above"
        echo "  2. Add a test torrent to verify peer connections"
        echo "  3. Monitor with: ./scripts/monitor-protonvpn-portforward.sh"
        return 0
    fi

    if [[ -f /tmp/protonvpn_current_port ]]; then
        local current_port
        current_port=$(cat /tmp/protonvpn_current_port)

        if [[ "$current_port" != "$TARGET_PORT" ]]; then
            echo -e "${YELLOW}⚠ IMPORTANT:${NC} ProtonVPN assigns ports dynamically"
            echo ""
            echo "Currently assigned port: ${current_port}"
            echo "Your target port: ${TARGET_PORT}"
            echo ""
            echo "ProtonVPN does not allow requesting specific ports. Options:"
            echo "  1. Use the dynamically assigned port (${current_port}) - RECOMMENDED"
            echo "  2. Keep restarting the VPN until ${TARGET_PORT} is assigned (unreliable)"
            echo ""
            echo "The automatic port forwarding service will keep clients updated."
        fi
    fi

    if [[ $ERRORS -gt 0 ]]; then
        echo -e "${RED}✗ Found ${ERRORS} error(s) that need attention:${NC}"
        echo ""

        # Common fixes
        echo "Common fixes:"
        echo "  • VPN/namespace issues:"
        echo "    sudo systemctl restart qbt.service"
        echo ""
        echo "  • Port forwarding not working:"
        echo "    sudo systemctl start protonvpn-portforward.service"
        echo "    sudo systemctl enable --now protonvpn-portforward.timer"
        echo ""
        echo "  • Client not listening:"
        echo "    sudo systemctl restart qbittorrent.service"
        echo "    sudo systemctl restart transmission.service"
        echo ""
    fi

    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}⚠ Found ${WARNINGS} warning(s) - review above for details${NC}"
        echo ""
    fi

    echo "Additional diagnostic tools:"
    echo "  • Full verification: ./scripts/verify-qbittorrent-vpn.sh"
    echo "  • Quick check: ./scripts/test-vpn-port-forwarding.sh"
    echo "  • Live monitoring: ./scripts/monitor-protonvpn-portforward.sh"
    echo "  • Network test: ./scripts/test-qbittorrent-connectivity.sh"
}

# Summary
print_summary() {
    print_header "Port ${TARGET_PORT} Check Summary"

    if [[ -f /tmp/protonvpn_current_port ]]; then
        local vpn_port
        vpn_port=$(cat /tmp/protonvpn_current_port)
        echo -e "  ProtonVPN Assigned Port: ${CYAN}${vpn_port}${NC}"
    fi

    echo -e "  Target Port: ${CYAN}${TARGET_PORT}${NC}"
    echo -e "  Errors: ${RED}${ERRORS}${NC}"
    echo -e "  Warnings: ${YELLOW}${WARNINGS}${NC}"
    echo ""

    if [[ $ERRORS -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Cleanup
cleanup() {
    rm -f /tmp/protonvpn_current_port
}
trap cleanup EXIT

# Main execution
main() {
    print_header "Torrent Port ${TARGET_PORT} Verification"
    echo "Checking configuration for both Transmission and qBittorrent..."

    check_namespace || true
    check_protonvpn_port || true
    check_qbittorrent || true
    check_transmission || true
    check_external_ip || true
    check_portforward_service || true
    test_external_port || true

    provide_recommendations
    print_summary
}

main "$@"
