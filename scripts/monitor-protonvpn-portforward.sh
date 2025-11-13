#!/usr/bin/env bash
# Monitor ProtonVPN Port Forwarding Status
# Comprehensive monitoring script for VPN namespace and port forwarding

set -euo pipefail

# Configuration
NAMESPACE="${NAMESPACE:-qbt}"
VPN_GATEWAY="${VPN_GATEWAY:-10.2.0.1}"
QBITTORRENT_CONFIG="/var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Status tracking
ISSUES=0

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}?${NC} $1"
}

print_error() {
    echo -e "${RED}?${NC} $1"
    ((ISSUES++))
}

print_warning() {
    echo -e "${YELLOW}?${NC} $1"
}

print_info() {
    echo -e "  $1"
}

# Check 1: Namespace exists
check_namespace() {
    print_header "1. VPN Namespace"

    if ip netns list | grep -q "^${NAMESPACE}"; then
        print_success "Namespace '${NAMESPACE}' exists"
    else
        print_error "Namespace '${NAMESPACE}' does not exist"
        return 1
    fi
}

# Check 2: WireGuard interface
check_wireguard() {
    print_header "2. WireGuard Interface"

    local wg_output
    if wg_output=$(ip netns exec "$NAMESPACE" wg show 2>&1); then
        print_success "WireGuard interface exists"

        # Show interface details
        local interface
        interface=$(echo "$wg_output" | grep -oP '^interface: \K.*' | head -1)
        if [[ -n "$interface" ]]; then
            print_info "Interface: $interface"

            # Get IP address
            local ip_addr
            ip_addr=$(ip netns exec "$NAMESPACE" ip addr show "$interface" 2>/dev/null | grep -oP 'inet \K[0-9.]+/[0-9]+' || echo "unknown")
            print_info "IP Address: $ip_addr"

            # Check handshake
            local handshake
            handshake=$(echo "$wg_output" | grep "latest handshake" || echo "")
            if [[ -n "$handshake" ]]; then
                print_info "Handshake: $handshake"
            else
                print_warning "No recent handshake"
            fi
        fi
    else
        print_error "WireGuard interface not found in namespace"
    fi
}

# Check 3: VPN connectivity
check_vpn_connectivity() {
    print_header "3. VPN Connectivity"

    # Ping gateway
    if ip netns exec "$NAMESPACE" ping -c 3 -W 5 "$VPN_GATEWAY" >/dev/null 2>&1; then
        print_success "VPN gateway $VPN_GATEWAY is reachable"
    else
        print_error "Cannot reach VPN gateway $VPN_GATEWAY"
    fi

    # Check external IP
    local external_ip
    external_ip=$(ip netns exec "$NAMESPACE" curl -s --max-time 10 https://ipv4.icanhazip.com 2>/dev/null || echo "")

    if [[ -n "$external_ip" ]]; then
        print_success "External connectivity working"
        print_info "External IP: $external_ip"
    else
        print_error "Cannot reach external internet"
    fi
}

# Check 4: NAT-PMP port forwarding
check_natpmp() {
    print_header "4. NAT-PMP Port Forwarding"

    if ! command -v natpmpc >/dev/null 2>&1; then
        print_error "natpmpc not found (install with: nix-shell -p libnatpmp)"
        return 1
    fi

    print_success "natpmpc is available"

    # Query NAT-PMP
    local natpmp_output
    natpmp_output=$(ip netns exec "$NAMESPACE" natpmpc -a 0 0 tcp 60 -g "$VPN_GATEWAY" 2>&1 || echo "")

    if echo "$natpmp_output" | grep -q "Mapped public port"; then
        local port
        port=$(echo "$natpmp_output" | grep "Mapped public port" | grep -oP 'Mapped public port \K[0-9]+')

        if [[ -n "$port" && "$port" -gt 0 ]]; then
            print_success "NAT-PMP assigned port: $port"
            echo "$port" > /tmp/natpmp_port  # Store for later checks
        else
            print_error "NAT-PMP did not return a valid port"
        fi
    else
        print_error "NAT-PMP query failed"
        print_info "Output: $natpmp_output"
    fi
}

# Check 5: qBittorrent service
check_qbittorrent_service() {
    print_header "5. qBittorrent Service"

    if systemctl is-active --quiet qbittorrent.service; then
        print_success "qBittorrent service is running"

        # Check uptime
        local uptime
        uptime=$(systemctl show qbittorrent.service -p ActiveEnterTimestamp --value)
        print_info "Started: $uptime"
    else
        print_error "qBittorrent service is not running"
        return 1
    fi
}

# Check 6: qBittorrent configuration
check_qbittorrent_config() {
    print_header "6. qBittorrent Configuration"

    if [[ ! -f "$QBITTORRENT_CONFIG" ]]; then
        print_error "qBittorrent config not found at $QBITTORRENT_CONFIG"
        return 1
    fi

    print_success "Config file exists"

    # Check configured port
    local qb_port
    qb_port=$(grep "^Session\\\\Port=" "$QBITTORRENT_CONFIG" 2>/dev/null | cut -d'=' -f2 || echo "")

    if [[ -n "$qb_port" ]]; then
        print_info "Configured port: $qb_port"

        # Compare with NAT-PMP port
        if [[ -f /tmp/natpmp_port ]]; then
            local natpmp_port
            natpmp_port=$(cat /tmp/natpmp_port)

            if [[ "$qb_port" == "$natpmp_port" ]]; then
                print_success "Port matches NAT-PMP assigned port"
            else
                print_error "Port mismatch! qBittorrent: $qb_port, NAT-PMP: $natpmp_port"
            fi
            rm /tmp/natpmp_port
        fi
    else
        print_warning "No port configured in qBittorrent config"
    fi

    # Check interface binding
    local interface
    interface=$(grep "^Session\\\\InterfaceName=" "$QBITTORRENT_CONFIG" 2>/dev/null | cut -d'=' -f2 || echo "")

    if [[ -n "$interface" ]]; then
        print_info "Interface binding: $interface"

        if [[ "$interface" == "${NAMESPACE}0" ]]; then
            print_success "Interface binding is correct"
        else
            print_warning "Interface binding may be incorrect (expected: ${NAMESPACE}0)"
        fi
    else
        print_warning "No interface binding configured"
    fi
}

# Check 7: qBittorrent listening ports
check_listening_ports() {
    print_header "7. Listening Ports"

    # Check ports in namespace
    local ports
    ports=$(ip netns exec "$NAMESPACE" ss -tuln 2>/dev/null | grep -v "127.0.0.1" | grep "LISTEN" || echo "")

    if [[ -n "$ports" ]]; then
        print_success "qBittorrent is listening on ports:"
        echo "$ports" | while read -r line; do
            print_info "$line"
        done
    else
        print_warning "No listening ports found in namespace"
    fi
}

# Check 8: Recent logs
check_logs() {
    print_header "8. Recent Service Logs"

    local logs
    logs=$(journalctl -u qbittorrent.service --since "5 minutes ago" -n 10 --no-pager 2>/dev/null || echo "")

    if [[ -n "$logs" ]]; then
        print_info "Last 10 log entries:"
        echo "$logs" | sed 's/^/  /'
    else
        print_info "No recent logs"
    fi
}

# Summary
print_summary() {
    echo ""
    print_header "Summary"

    if [[ $ISSUES -eq 0 ]]; then
        print_success "All checks passed! Port forwarding is working correctly."
    else
        print_error "Found $ISSUES issue(s) that need attention."
        echo ""
        echo "Troubleshooting:"
        echo "  - Check service status: systemctl status qbittorrent qbt"
        echo "  - View logs: journalctl -u qbittorrent -u qbt -f"
        echo "  - Verify SOPS secrets: sops -d /run/secrets/vpn-confinement-qbittorrent"
    fi
}

# Main execution
main() {
    echo ""
    print_header "ProtonVPN Port Forwarding Monitor"
    echo ""

    check_namespace
    check_wireguard
    check_vpn_connectivity
    check_natpmp
    check_qbittorrent_service
    check_qbittorrent_config
    check_listening_ports
    check_logs

    print_summary

    exit $ISSUES
}

main "$@"
