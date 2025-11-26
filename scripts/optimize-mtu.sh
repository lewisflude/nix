#!/usr/bin/env bash
# MTU Optimizer for regular network and qBittorrent VPN namespace
# Uses binary search with ping + Don't Fragment flag to find optimal MTU
#
# Usage:
#   ./optimize-mtu.sh [options]
#
# Options:
#   --vpn-only          Only test VPN namespace MTU
#   --regular-only      Only test regular interface MTU
#   --namespace NAME    VPN namespace name (default: qbt)
#   --apply             Apply the discovered MTU settings automatically
#   --dry-run           Show what would be done without applying

set -euo pipefail

# Configuration
NAMESPACE="${NAMESPACE:-qbt}"
VPN_TEST_HOST="8.8.8.8"  # Google DNS for VPN testing
REGULAR_TEST_HOST="1.1.1.1"  # Cloudflare DNS for regular testing
PING_COUNT=3
PING_TIMEOUT=2

# MTU Search ranges
# WireGuard overhead is typically 60 bytes (80 with IPv6)
# Standard Ethernet MTU is 1500
# ICMP/IP headers add 28 bytes
MIN_PACKET_SIZE=1200
MAX_PACKET_SIZE=1472  # 1500 - 28 (IP/ICMP headers)

# Flags
TEST_VPN=true
TEST_REGULAR=true
APPLY_CHANGES=false
DRY_RUN=false

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${BLUE}${BOLD}================================================================${NC}"
    echo -e "${BLUE}${BOLD}$1${NC}"
    echo -e "${BLUE}${BOLD}================================================================${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${CYAN}${BOLD}>>> $1${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_failure() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_result() {
    echo -e "${BOLD}$1${NC}"
}

usage() {
    cat << EOF
MTU Optimizer - Find optimal MTU for network interfaces

Usage: $0 [OPTIONS]

Options:
    --vpn-only          Only test VPN namespace MTU
    --regular-only      Only test regular interface MTU
    --namespace NAME    VPN namespace name (default: qbt)
    --apply             Apply the discovered MTU settings
    --dry-run           Show what would be done without applying
    -h, --help          Show this help message

Examples:
    # Test both interfaces
    $0

    # Test only VPN and apply settings
    $0 --vpn-only --apply

    # Test both with dry-run
    $0 --apply --dry-run
EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --vpn-only)
            TEST_REGULAR=false
            shift
            ;;
        --regular-only)
            TEST_VPN=false
            shift
            ;;
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --apply)
            APPLY_CHANGES=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            APPLY_CHANGES=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Check if we're running as root for certain operations
check_root() {
    if [[ $EUID -ne 0 ]] && [[ "$APPLY_CHANGES" == true ]] && [[ "$DRY_RUN" == false ]]; then
        print_failure "Root privileges required to apply MTU changes"
        echo "Run with sudo or use --dry-run to see recommendations"
        exit 1
    fi
}

# Binary search for optimal packet size
# Returns the largest packet size that doesn't fragment
find_optimal_packet_size() {
    local test_host=$1
    local namespace=${2:-}  # Optional namespace
    local min=$MIN_PACKET_SIZE
    local max=$MAX_PACKET_SIZE
    local optimal=$min

    print_info "Testing MTU range: $((min + 28)) - $((max + 28)) bytes" >&2
    print_info "Using binary search algorithm..." >&2
    echo "" >&2

    while [[ $min -le $max ]]; do
        local mid=$(( (min + max) / 2 ))

        # Construct ping command
        local ping_cmd="ping -c $PING_COUNT -W $PING_TIMEOUT -M do -s $mid $test_host"

        if [[ -n "$namespace" ]]; then
            ping_cmd="ip netns exec $namespace $ping_cmd"
        fi

        # Test this packet size
        echo -n "  Testing packet size: $mid bytes (MTU: $((mid + 28)))... " >&2

        if eval "$ping_cmd" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC}" >&2
            optimal=$mid
            min=$((mid + 1))
        else
            echo -e "${RED}✗ (fragmented)${NC}" >&2
            max=$((mid - 1))
        fi
    done

    echo "" >&2
    print_success "Optimal packet size found: $optimal bytes" >&2

    # Return optimal MTU (packet size + 28 bytes for IP/ICMP headers) - clean output
    echo $((optimal + 28))
}

# Get current MTU of an interface
get_current_mtu() {
    local interface=$1
    local namespace=${2:-}

    if [[ -n "$namespace" ]]; then
        ip netns exec "$namespace" ip link show "$interface" | grep -oP 'mtu \K[0-9]+'
    else
        ip link show "$interface" | grep -oP 'mtu \K[0-9]+'
    fi
}

# Get default network interface
get_default_interface() {
    ip route show default | grep -oP 'dev \K\S+'
}

# Test regular network interface
test_regular_interface() {
    print_header "Testing Regular Network Interface"

    # Get default interface
    local interface
    interface=$(get_default_interface)

    if [[ -z "$interface" ]]; then
        print_failure "Could not determine default network interface"
        return 1
    fi

    print_info "Default interface: $interface"

    local current_mtu
    current_mtu=$(get_current_mtu "$interface")
    print_info "Current MTU: $current_mtu"

    # Test connectivity first
    print_section "Testing connectivity to $REGULAR_TEST_HOST..."
    if ! ping -c 2 -W 3 "$REGULAR_TEST_HOST" >/dev/null 2>&1; then
        print_failure "Cannot reach test host $REGULAR_TEST_HOST"
        return 1
    fi
    print_success "Connectivity OK"

    # Find optimal MTU
    print_section "Finding optimal MTU..."
    local optimal_mtu
    optimal_mtu=$(find_optimal_packet_size "$REGULAR_TEST_HOST")

    # Results
    print_section "Results - Regular Interface"
    print_result "Interface:    $interface"
    print_result "Current MTU:  $current_mtu"
    print_result "Optimal MTU:  $optimal_mtu"

    if [[ $optimal_mtu -lt $current_mtu ]]; then
        print_info "Recommendation: Lower MTU to $optimal_mtu to avoid fragmentation"
    elif [[ $optimal_mtu -gt $current_mtu ]]; then
        print_success "You can increase MTU to $optimal_mtu for better performance"
    else
        print_success "Current MTU is optimal!"
    fi

    # Store for later
    REGULAR_INTERFACE="$interface"
    REGULAR_OPTIMAL_MTU="$optimal_mtu"
    REGULAR_CURRENT_MTU="$current_mtu"
}

# Test VPN namespace
test_vpn_interface() {
    print_header "Testing VPN Namespace Interface"

    # Check if namespace exists
    if ! ip netns list | grep -q "^${NAMESPACE}"; then
        print_failure "Namespace '$NAMESPACE' not found"
        print_info "Available namespaces:"
        ip netns list
        return 1
    fi

    print_success "Namespace '$NAMESPACE' found"

    # Get VPN interface (should be qbt0 for namespace qbt)
    local vpn_interface="${NAMESPACE}0"

    # Check if interface exists in namespace
    if ! ip netns exec "$NAMESPACE" ip link show "$vpn_interface" &>/dev/null; then
        print_failure "Interface '$vpn_interface' not found in namespace"
        print_info "Available interfaces in namespace:"
        ip netns exec "$NAMESPACE" ip link show
        return 1
    fi

    print_info "VPN interface: $vpn_interface"

    local current_mtu
    current_mtu=$(get_current_mtu "$vpn_interface" "$NAMESPACE")
    print_info "Current MTU: $current_mtu"

    # Test connectivity first
    print_section "Testing VPN connectivity to $VPN_TEST_HOST..."
    if ! ip netns exec "$NAMESPACE" ping -c 2 -W 3 "$VPN_TEST_HOST" >/dev/null 2>&1; then
        print_failure "Cannot reach test host $VPN_TEST_HOST through VPN"
        return 1
    fi
    print_success "VPN connectivity OK"

    # Find optimal MTU for VPN
    print_section "Finding optimal MTU for VPN..."
    local optimal_mtu
    optimal_mtu=$(find_optimal_packet_size "$VPN_TEST_HOST" "$NAMESPACE")

    # For WireGuard, we need to account for encapsulation overhead
    # WireGuard adds ~60 bytes overhead (80 with IPv6)
    # So if we found optimal packet MTU, that's already accounting for the path

    # Results
    print_section "Results - VPN Interface"
    print_result "Namespace:    $NAMESPACE"
    print_result "Interface:    $vpn_interface"
    print_result "Current MTU:  $current_mtu"
    print_result "Optimal MTU:  $optimal_mtu"

    if [[ $optimal_mtu -lt $current_mtu ]]; then
        print_info "Recommendation: Lower MTU to $optimal_mtu to avoid fragmentation"
        print_info "This is CRITICAL for VPN performance!"
    elif [[ $optimal_mtu -gt $current_mtu ]]; then
        print_success "You can increase MTU to $optimal_mtu for better performance"
    else
        print_success "Current MTU is optimal!"
    fi

    # Store for later
    VPN_INTERFACE="$vpn_interface"
    VPN_OPTIMAL_MTU="$optimal_mtu"
    VPN_CURRENT_MTU="$current_mtu"
}

# Apply MTU settings
apply_mtu_settings() {
    print_header "Applying MTU Settings"

    if [[ "$DRY_RUN" == true ]]; then
        print_info "DRY RUN MODE - No changes will be applied"
        echo ""
    fi

    local changes_needed=false

    # Apply regular interface MTU
    if [[ "$TEST_REGULAR" == true ]] && [[ -n "${REGULAR_OPTIMAL_MTU:-}" ]]; then
        if [[ "$REGULAR_OPTIMAL_MTU" != "$REGULAR_CURRENT_MTU" ]]; then
            changes_needed=true
            print_section "Regular Interface: $REGULAR_INTERFACE"
            echo "Change MTU: $REGULAR_CURRENT_MTU → $REGULAR_OPTIMAL_MTU"

            if [[ "$DRY_RUN" == false ]]; then
                print_info "Applying MTU to $REGULAR_INTERFACE..."
                ip link set dev "$REGULAR_INTERFACE" mtu "$REGULAR_OPTIMAL_MTU"
                print_success "MTU applied to $REGULAR_INTERFACE"
            fi

            # UniFi Dream Machine recommendation
            echo ""
            print_info "To make this permanent on UniFi Dream Machine:"
            echo "  1. Go to Settings → Networks → [Your Network]"
            echo "  2. Advanced → Manual → DHCP Options"
            echo "  3. Add option: interface-mtu $REGULAR_OPTIMAL_MTU"
            echo "  4. Or set it per-port in Device → Port → Advanced"
        else
            print_success "Regular interface MTU is already optimal"
        fi
    fi

    # Apply VPN interface MTU
    if [[ "$TEST_VPN" == true ]] && [[ -n "${VPN_OPTIMAL_MTU:-}" ]]; then
        if [[ "$VPN_OPTIMAL_MTU" != "$VPN_CURRENT_MTU" ]]; then
            changes_needed=true
            print_section "VPN Interface: $VPN_INTERFACE (namespace: $NAMESPACE)"
            echo "Change MTU: $VPN_CURRENT_MTU → $VPN_OPTIMAL_MTU"

            # For WireGuard, MTU must be set in the config file
            print_info "For WireGuard, MTU should be set in the configuration file"
            echo ""
            echo "Update your WireGuard config (SOPS secret: vpn-confinement-qbittorrent):"
            echo ""
            echo "  [Interface]"
            echo "  MTU = $VPN_OPTIMAL_MTU"
            echo "  ..."
            echo ""
            print_info "After updating, rebuild your system:"
            echo "  sudo nh os switch"
            echo ""

            if [[ "$DRY_RUN" == false ]]; then
                print_info "Temporarily applying MTU to $VPN_INTERFACE..."
                ip netns exec "$NAMESPACE" ip link set dev "$VPN_INTERFACE" mtu "$VPN_OPTIMAL_MTU"
                print_success "MTU temporarily applied to $VPN_INTERFACE"
                print_info "This will be lost on reboot - update WireGuard config!"
            fi
        else
            print_success "VPN interface MTU is already optimal"
        fi
    fi

    if [[ "$changes_needed" == false ]]; then
        print_success "All MTU settings are already optimal!"
    fi
}

# Generate configuration recommendations
print_recommendations() {
    print_header "Configuration Recommendations"

    if [[ "$TEST_VPN" == true ]] && [[ -n "${VPN_OPTIMAL_MTU:-}" ]]; then
        print_section "WireGuard VPN Configuration"
        echo "Edit your WireGuard configuration secret:"
        echo ""
        echo "  # Decrypt and edit the secret"
        echo "  sops secrets/secrets.yaml"
        echo ""
        echo "Add or update the MTU setting in the [Interface] section:"
        echo ""
        echo "  vpn-confinement-qbittorrent: |"
        echo "    [Interface]"
        echo "    PrivateKey = ..."
        echo "    Address = ..."
        echo "    MTU = $VPN_OPTIMAL_MTU"
        echo "    DNS = ..."
        echo ""
        echo "    [Peer]"
        echo "    ..."
        echo ""
        print_info "After updating, rebuild: sudo nh os switch"
    fi

    if [[ "$TEST_REGULAR" == true ]] && [[ -n "${REGULAR_OPTIMAL_MTU:-}" ]]; then
        print_section "Regular Network - NixOS Configuration"
        echo "To set MTU permanently in NixOS, add to your configuration:"
        echo ""
        echo "  networking.interfaces.$REGULAR_INTERFACE.mtu = $REGULAR_OPTIMAL_MTU;"
        echo ""

        print_section "Regular Network - UniFi Dream Machine"
        echo "Option 1: Network-wide (DHCP):"
        echo "  1. UniFi Console → Settings → Networks"
        echo "  2. Select your network (e.g., Default)"
        echo "  3. Advanced → Manual → DHCP Options"
        echo "  4. Add DHCP option 26 with value: $REGULAR_OPTIMAL_MTU"
        echo ""
        echo "Option 2: Per-device/port (best for specific devices):"
        echo "  1. UniFi Console → Devices → Select your switch/router"
        echo "  2. Ports → Select port"
        echo "  3. Port Settings → MTU: $REGULAR_OPTIMAL_MTU"
        echo ""

        print_section "Testing MTU Changes"
        echo "After applying changes, verify with:"
        echo ""
        if [[ "$TEST_REGULAR" == true ]]; then
            echo "  # Test regular interface"
            echo "  ping -M do -s $((REGULAR_OPTIMAL_MTU - 28)) -c 4 $REGULAR_TEST_HOST"
            echo ""
        fi
        if [[ "$TEST_VPN" == true ]]; then
            echo "  # Test VPN interface"
            echo "  ip netns exec $NAMESPACE ping -M do -s $((VPN_OPTIMAL_MTU - 28)) -c 4 $VPN_TEST_HOST"
            echo ""
        fi
    fi
}

# Main execution
main() {
    print_header "MTU Optimizer - Network Path MTU Discovery"

    echo "Configuration:"
    echo "  Test regular interface: $TEST_REGULAR"
    echo "  Test VPN namespace:     $TEST_VPN"
    if [[ "$TEST_VPN" == true ]]; then
        echo "  VPN namespace:          $NAMESPACE"
    fi
    echo "  Apply changes:          $APPLY_CHANGES"
    if [[ "$APPLY_CHANGES" == true ]]; then
        echo "  Dry run:                $DRY_RUN"
    fi
    echo ""

    # Check root if needed
    check_root

    # Run tests
    local test_failed=false

    if [[ "$TEST_REGULAR" == true ]]; then
        if ! test_regular_interface; then
            test_failed=true
        fi
    fi

    if [[ "$TEST_VPN" == true ]]; then
        if ! test_vpn_interface; then
            test_failed=true
        fi
    fi

    # Apply settings if requested
    if [[ "$APPLY_CHANGES" == true ]] && [[ "$test_failed" == false ]]; then
        apply_mtu_settings
    fi

    # Print recommendations
    if [[ "$test_failed" == false ]]; then
        print_recommendations
    fi

    # Summary
    print_header "Summary"

    if [[ "$test_failed" == true ]]; then
        print_failure "Some tests failed - check output above"
        exit 1
    fi

    if [[ "$TEST_REGULAR" == true ]]; then
        echo "Regular Network:"
        echo "  Interface: $REGULAR_INTERFACE"
        echo "  Current:   $REGULAR_CURRENT_MTU"
        echo "  Optimal:   $REGULAR_OPTIMAL_MTU"
        if [[ "$REGULAR_OPTIMAL_MTU" != "$REGULAR_CURRENT_MTU" ]]; then
            echo "  Status:    ⚠️  NEEDS ADJUSTMENT"
        else
            echo "  Status:    ✓ OPTIMAL"
        fi
        echo ""
    fi

    if [[ "$TEST_VPN" == true ]]; then
        echo "VPN Network ($NAMESPACE):"
        echo "  Interface: $VPN_INTERFACE"
        echo "  Current:   $VPN_CURRENT_MTU"
        echo "  Optimal:   $VPN_OPTIMAL_MTU"
        if [[ "$VPN_OPTIMAL_MTU" != "$VPN_CURRENT_MTU" ]]; then
            echo "  Status:    ⚠️  NEEDS ADJUSTMENT (CRITICAL FOR VPN!)"
        else
            echo "  Status:    ✓ OPTIMAL"
        fi
        echo ""
    fi

    print_success "MTU optimization complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Review the recommendations above"
    echo "  2. Update WireGuard config if VPN MTU needs adjustment"
    echo "  3. Configure UniFi Dream Machine for regular network"
    echo "  4. Test qBittorrent performance after changes"
    echo ""
}

main "$@"
