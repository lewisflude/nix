#!/usr/bin/env bash
# Verification script for qBittorrent VPN setup
# Works through the verification guide checklist

set -euo pipefail

# Configuration
NAMESPACE="${NAMESPACE:-qbt}"
VPN_GATEWAY="${VPN_GATEWAY:-10.2.0.1}"
QBITTORRENT_CONFIG="/var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_phase() {
    echo ""
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}? $1${NC}"
}

print_success() {
    echo -e "${GREEN}? $1${NC}"
}

print_failure() {
    echo -e "${RED}? $1${NC}"
}

run_check() {
    local description=$1
    local command=$2

    print_step "$description"
    echo "  Command: $command"
    echo ""

    if eval "$command"; then
        print_success "PASS"
        return 0
    else
        print_failure "FAIL"
        return 1
    fi
}

print_result() {
    local description=$1
    local result=$2

    echo "  Result: $result"
}

# Phase 1: Basic Connectivity
phase1_connectivity() {
    print_phase "Phase 1: Basic Connectivity Tests"

    # Step 1: Check namespace exists
    print_step "Step 1: Verify namespace exists"
    if ip netns list | grep -q "^${NAMESPACE}"; then
        print_success "Namespace '$NAMESPACE' exists"
    else
        print_failure "Namespace '$NAMESPACE' NOT found"
        return 1
    fi

    # Step 2: Check WireGuard interface
    print_step "Step 2: Verify WireGuard interface"
    local wg_interface="${NAMESPACE}0"

    if ip netns exec "$NAMESPACE" ip addr show "$wg_interface" &>/dev/null; then
        print_success "WireGuard interface found: $wg_interface"

        local ip_addr
        ip_addr=$(ip netns exec "$NAMESPACE" ip addr show "$wg_interface" | grep -oP 'inet \K[0-9.]+/[0-9]+' || echo "")
        print_result "IP Address" "$ip_addr"
    else
        print_failure "WireGuard interface NOT found (expected: $wg_interface)"
        return 1
    fi

    # Step 3: Check route
    print_step "Step 3: Verify routing table"
    if ip netns exec "$NAMESPACE" ip route show | grep -q "10.2.0.0/24"; then
        print_success "Route to 10.2.0.0/24 exists"
        local route
        route=$(ip netns exec "$NAMESPACE" ip route show | grep "10.2.0.0/24")
        print_result "Route" "$route"
    else
        print_failure "Route to 10.2.0.0/24 NOT found"
        return 1
    fi

    # Step 4: Ping gateway
    print_step "Step 4: Test gateway connectivity"
    if ip netns exec "$NAMESPACE" ping -c 3 -W 5 "$VPN_GATEWAY" >/dev/null 2>&1; then
        print_success "VPN gateway $VPN_GATEWAY is reachable"

        local latency
        latency=$(ip netns exec "$NAMESPACE" ping -c 3 -W 5 "$VPN_GATEWAY" 2>/dev/null | grep "avg" | grep -oP 'mdev = [0-9.]+/\K[0-9.]+' || echo "N/A")
        print_result "Average latency" "${latency}ms"
    else
        print_failure "Cannot reach VPN gateway $VPN_GATEWAY"
        return 1
    fi

    # Step 5: External IP check
    print_step "Step 5: Verify traffic goes through VPN"
    local external_ip
    external_ip=$(ip netns exec "$NAMESPACE" curl -s --max-time 10 https://api.ipify.org 2>/dev/null || echo "")

    if [[ -n "$external_ip" ]]; then
        print_success "External connectivity working"
        print_result "External IP" "$external_ip"
        echo "  ? Verify this is NOT your real IP!"
    else
        print_failure "Cannot determine external IP"
        return 1
    fi
}

# Phase 2: NAT-PMP Port Forwarding
phase2_natpmp() {
    print_phase "Phase 2: NAT-PMP Port Forwarding"

    # Check natpmpc availability
    if ! command -v natpmpc >/dev/null 2>&1; then
        print_failure "natpmpc not found. Install with: nix-shell -p libnatpmp"
        return 1
    fi

    print_success "natpmpc is available"

    # Manual NAT-PMP query
    print_step "Step 6: Manual NAT-PMP query"
    echo "  Running: natpmpc -a 0 0 tcp 60 -g $VPN_GATEWAY"
    echo ""

    local natpmp_output
    natpmp_output=$(ip netns exec "$NAMESPACE" natpmpc -a 0 0 tcp 60 -g "$VPN_GATEWAY" 2>&1 || echo "FAILED")

    echo "$natpmp_output"
    echo ""

    if echo "$natpmp_output" | grep -q "Mapped public port"; then
        local port
        port=$(echo "$natpmp_output" | grep "Mapped public port" | grep -oP 'Mapped public port \K[0-9]+')

        if [[ -n "$port" && "$port" -gt 0 ]]; then
            print_success "NAT-PMP assigned port: $port"
            echo "$port" > /tmp/natpmp_port
            return 0
        fi
    fi

    print_failure "NAT-PMP query failed"
    return 1
}

# Phase 3: qBittorrent Configuration
phase3_qbittorrent() {
    print_phase "Phase 3: qBittorrent Configuration"

    # Check service
    print_step "Step 7: Check qBittorrent service status"
    if systemctl is-active --quiet qbittorrent.service; then
        print_success "qBittorrent service is running"
    else
        print_failure "qBittorrent service is NOT running"
        echo "  Run: systemctl start qbittorrent.service"
        return 1
    fi

    # Check config file
    print_step "Step 8: Check qBittorrent configuration"
    if [[ ! -f "$QBITTORRENT_CONFIG" ]]; then
        print_failure "Config file not found at $QBITTORRENT_CONFIG"
        return 1
    fi

    print_success "Config file exists"

    # Check port
    local qb_port
    qb_port=$(grep "^Session\\\\Port=" "$QBITTORRENT_CONFIG" 2>/dev/null | cut -d'=' -f2 || echo "")

    if [[ -n "$qb_port" ]]; then
        print_result "Configured port" "$qb_port"

        # Compare with NAT-PMP port
        if [[ -f /tmp/natpmp_port ]]; then
            local natpmp_port
            natpmp_port=$(cat /tmp/natpmp_port)

            if [[ "$qb_port" == "$natpmp_port" ]]; then
                print_success "Port matches NAT-PMP assignment"
            else
                print_failure "Port mismatch! qBittorrent: $qb_port, NAT-PMP: $natpmp_port"
                echo "  Run: ./scripts/protonvpn-natpmp-portforward.sh"
            fi
        fi
    else
        print_failure "No port configured"
    fi

    # Check interface binding
    print_step "Step 9: Verify interface binding"
    local interface
    interface=$(grep "^Session\\\\InterfaceName=" "$QBITTORRENT_CONFIG" 2>/dev/null | cut -d'=' -f2 || echo "")

    if [[ -n "$interface" ]]; then
        print_result "Interface" "$interface"

        if [[ "$interface" == "${NAMESPACE}0" ]]; then
            print_success "Interface binding is correct"
        else
            print_failure "Interface binding incorrect (expected: ${NAMESPACE}0)"
        fi
    else
        print_failure "No interface binding configured"
    fi

    # Check listening
    print_step "Step 10: Check if qBittorrent is listening"
    if [[ -n "$qb_port" ]]; then
        if ip netns exec "$NAMESPACE" ss -tuln | grep -q ":${qb_port} "; then
            print_success "qBittorrent is listening on port $qb_port"
        else
            print_failure "qBittorrent is NOT listening on port $qb_port"
        fi
    fi
}

# Phase 4: Summary
phase4_summary() {
    print_phase "Phase 4: Summary & Next Steps"

    echo "Verification complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Add a test torrent (Ubuntu ISO, etc.)"
    echo "  2. Verify external port is open:"
    echo "     https://www.yougetsignal.com/tools/open-ports/"
    echo "  3. Check for incoming peer connections"
    echo ""
    echo "Automation:"
    echo "  - Run monitoring: ./scripts/monitor-protonvpn-portforward.sh"
    echo "  - Update port: ./scripts/protonvpn-natpmp-portforward.sh"
    echo ""
    echo "WebUI: http://$(hostname -I | awk '{print $1}'):8080"

    # Cleanup
    [[ -f /tmp/natpmp_port ]] && rm /tmp/natpmp_port
}

# Main
main() {
    echo ""
    echo "======================================================================"
    echo "  qBittorrent VPN Setup Verification"
    echo "======================================================================"
    echo ""
    echo "Configuration:"
    echo "  Namespace: $NAMESPACE"
    echo "  VPN Gateway: $VPN_GATEWAY"
    echo "  Config: $QBITTORRENT_CONFIG"
    echo ""

    phase1_connectivity || {
        echo ""
        echo "Phase 1 failed. Fix connectivity issues before proceeding."
        exit 1
    }

    phase2_natpmp || {
        echo ""
        echo "Phase 2 failed. NAT-PMP port forwarding not working."
        echo "Check VPN configuration and ProtonVPN account."
        exit 1
    }

    phase3_qbittorrent || {
        echo ""
        echo "Phase 3 failed. qBittorrent configuration needs attention."
        exit 1
    }

    phase4_summary
}

main "$@"
