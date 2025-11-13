#!/usr/bin/env bash
# Unified script to detect ProtonVPN forwarded port
# Supports both NAT-PMP automatic detection and port scanning

set -euo pipefail

# Default values
NAMESPACE="${NAMESPACE:-qbittor}"
VPN_GATEWAY="${VPN_GATEWAY:-10.2.0.1}"
METHOD="auto"

# Usage information
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Detect ProtonVPN forwarded port using various methods.

OPTIONS:
    -n, --namespace NAMESPACE    Network namespace (default: qbittor)
    -g, --gateway GATEWAY        VPN gateway IP (default: 10.2.0.1)
    -m, --method METHOD          Detection method: auto, natpmp, scan (default: auto)
    -h, --help                   Show this help message

METHODS:
    auto    - Try NAT-PMP first, fall back to scanning if unavailable
    natpmp  - Use NAT-PMP protocol for automatic detection (requires natpmpc)
    scan    - Scan common ProtonVPN ports to find open ones

EXAMPLES:
    $0                                    # Auto-detect with defaults
    $0 -m natpmp                          # Force NAT-PMP detection
    $0 -m scan -n qbittor                 # Scan ports in qbittor namespace
    $0 -n vpn-ns -g 10.2.0.2 -m auto     # Custom namespace and gateway

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -g|--gateway)
            VPN_GATEWAY="$2"
            shift 2
            ;;
        -m|--method)
            METHOD="$2"
            shift 2
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

echo "ProtonVPN Port Detection"
echo "========================"
echo "Namespace: $NAMESPACE"
echo "VPN Gateway: $VPN_GATEWAY"
echo "Method: $METHOD"
echo ""

# Get external IP (used by multiple methods)
get_external_ip() {
    sudo ip netns exec "$NAMESPACE" curl -s --max-time 10 https://ipv4.icanhazip.com 2>/dev/null || echo ""
}

# Method 1: NAT-PMP detection
detect_natpmp() {
    echo "Trying NAT-PMP detection..."

    if ! command -v natpmpc >/dev/null 2>&1; then
        echo "✗ natpmpc not found. Install with: nix-shell -p natpmpc"
        return 1
    fi

    RESULT=$(sudo ip netns exec "$NAMESPACE" natpmpc -g "$VPN_GATEWAY" -a 0 0 0 2>&1 || echo "")

    if echo "$RESULT" | grep -q "external port"; then
        PORT=$(echo "$RESULT" | grep -oP 'external port \K[0-9]+' || echo "")
        if [ -n "$PORT" ] && [ "$PORT" != "0" ]; then
            echo "✓ Detected forwarded port via NAT-PMP: $PORT"
            echo "$PORT"
            return 0
        fi
    fi

    echo "✗ NAT-PMP did not return a valid port"
    return 1
}

# Method 2: Port scanning
detect_scan() {
    echo "Scanning common ProtonVPN forwarded ports..."

    EXTERNAL_IP=$(get_external_ip)

    if [ -z "$EXTERNAL_IP" ]; then
        echo "✗ Could not determine external IP (VPN may not be connected)"
        return 1
    fi

    echo "External IP: $EXTERNAL_IP"
    echo "(This will take a while - ProtonVPN often uses ports 49152-65535)"
    echo ""

    # Common ports ProtonVPN uses
    PORTS_TO_TEST=(
        6881 6882 6883 6884 6885 6886 6887 6888 6889 6890
        49152 49153 49154 49155 49156 49157 49158 49159 49160
        50000 50001 50002 50003 50004
    )

    for port in "${PORTS_TO_TEST[@]}"; do
        echo -n "Testing port $port... "

        # Use a simple TCP connection test
        RESULT=$(timeout 3 bash -c "echo > /dev/tcp/$EXTERNAL_IP/$port" 2>&1 || echo "closed")

        if [ "$RESULT" = "" ]; then
            echo "✓ OPEN!"
            echo ""
            echo "✓ Found open port: $port"
            echo "$port"
            return 0
        else
            echo "closed"
        fi
    done

    echo ""
    echo "✗ Could not find open port in common range"
    return 1
}

# Show manual detection options
show_manual_options() {
    echo ""
    echo "Manual detection options:"
    echo ""

    EXTERNAL_IP=$(get_external_ip)

    if [ -n "$EXTERNAL_IP" ]; then
        echo "1. Check external port accessibility:"
        echo "   External IP: $EXTERNAL_IP"
        echo "   Test ports: https://www.yougetsignal.com/tools/open-ports/"
        echo "   Try common ProtonVPN range: 49152-65535"
    fi

    echo ""
    echo "2. Check ProtonVPN account:"
    echo "   https://account.protonvpn.com → Downloads → WireGuard"
    echo "   (Port may be shown if port forwarding is active)"

    echo ""
    echo "3. Check qBittorrent current port:"
    echo "   Visit WebUI: Connection → Port used for incoming connections"

    echo ""
    echo "4. Try different detection method:"
    echo "   $0 -m natpmp    # Force NAT-PMP"
    echo "   $0 -m scan      # Force port scanning"
}

# Main detection logic
case "$METHOD" in
    natpmp)
        if detect_natpmp; then
            exit 0
        else
            show_manual_options
            exit 1
        fi
        ;;
    scan)
        if detect_scan; then
            exit 0
        else
            show_manual_options
            exit 1
        fi
        ;;
    auto)
        echo "Attempting automatic detection..."
        echo ""

        if detect_natpmp; then
            exit 0
        fi

        echo ""
        echo "NAT-PMP failed, trying port scan..."
        echo ""

        if detect_scan; then
            exit 0
        fi

        show_manual_options
        exit 1
        ;;
    *)
        echo "Unknown method: $METHOD"
        usage
        ;;
esac
