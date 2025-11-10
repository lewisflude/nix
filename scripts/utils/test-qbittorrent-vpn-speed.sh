#!/usr/bin/env bash
# Test torrent speed through qBittorrent VPN
# Monitors network traffic on the VPN interface and optionally uses qBittorrent API

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
VPN_NAMESPACE="qbittor"
VPN_INTERFACE="qbittor0"
WEBUI_PORT="${QBITTORRENT_WEBUI_PORT:-8080}"
WEBUI_HOST="${QBITTORRENT_WEBUI_HOST:-localhost}"
WEBUI_USER="${QBITTORRENT_WEBUI_USER:-}"
WEBUI_PASS="${QBITTORRENT_WEBUI_PASS:-}"
MONITOR_INTERVAL="${MONITOR_INTERVAL:-2}"  # seconds

# Check if running as root (needed for namespace access)
NEEDS_ROOT=false
if ! ip netns list 2>/dev/null | grep -q "^${VPN_NAMESPACE} "; then
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}Warning: Not running as root. Some features may be limited.${NC}"
        echo "For full functionality, run with: sudo $0"
        NEEDS_ROOT=true
    fi
fi

# Function to format bytes (no bc dependency)
format_bytes() {
    local bytes=$1
    if [ "$bytes" -ge 1073741824 ]; then
        local gb=$((bytes * 100 / 1073741824))
        printf "%d.%02d GB" $((gb / 100)) $((gb % 100))
    elif [ "$bytes" -ge 1048576 ]; then
        local mb=$((bytes * 100 / 1048576))
        printf "%d.%02d MB" $((mb / 100)) $((mb % 100))
    elif [ "$bytes" -ge 1024 ]; then
        local kb=$((bytes * 100 / 1024))
        printf "%d.%02d KB" $((kb / 100)) $((kb % 100))
    else
        printf "%d B" "$bytes"
    fi
}

# Function to format speed (no bc dependency)
format_speed() {
    local bytes=$1
    if [ "$bytes" -ge 1048576 ]; then
        local mb=$((bytes * 100 / 1048576))
        printf "%d.%02d MB/s" $((mb / 100)) $((mb % 100))
    elif [ "$bytes" -ge 1024 ]; then
        local kb=$((bytes * 100 / 1024))
        printf "%d.%02d KB/s" $((kb / 100)) $((kb % 100))
    else
        printf "%d B/s" "$bytes"
    fi
}

# Function to get interface stats from namespace
get_interface_stats() {
    local namespace=$1
    local interface=$2

    if [ "$EUID" -eq 0 ]; then
        ip netns exec "$namespace" cat "/sys/class/net/${interface}/statistics/rx_bytes" 2>/dev/null || echo "0"
        ip netns exec "$namespace" cat "/sys/class/net/${interface}/statistics/tx_bytes" 2>/dev/null || echo "0"
    else
        # Try without namespace (may not work)
        cat "/sys/class/net/${interface}/statistics/rx_bytes" 2>/dev/null || echo "0"
        cat "/sys/class/net/${interface}/statistics/tx_bytes" 2>/dev/null || echo "0"
    fi
}

# Function to check VPN namespace and interface
check_vpn_setup() {
    echo -e "${CYAN}=== Checking VPN Setup ===${NC}"
    echo ""

    # Check namespace
    if [ "$EUID" -eq 0 ]; then
        if ip netns list | grep -q "^${VPN_NAMESPACE} "; then
            echo -e "   ${GREEN}?${NC} VPN namespace '${VPN_NAMESPACE}' exists"
        else
            echo -e "   ${RED}?${NC} VPN namespace '${VPN_NAMESPACE}' not found"
            return 1
        fi

        # Check interface
        if ip netns exec "$VPN_NAMESPACE" ip link show "$VPN_INTERFACE" >/dev/null 2>&1; then
            echo -e "   ${GREEN}?${NC} VPN interface '${VPN_INTERFACE}' exists"
            VPN_IP=$(ip netns exec "$VPN_NAMESPACE" ip addr show "$VPN_INTERFACE" 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 || echo "")
            if [ -n "$VPN_IP" ]; then
                echo -e "   ${GREEN}?${NC} VPN IP: $VPN_IP"
            fi
        else
            echo -e "   ${RED}?${NC} VPN interface '${VPN_INTERFACE}' not found"
            return 1
        fi

        # Check qBittorrent service
        if systemctl is-active --quiet qbittorrent.service; then
            echo -e "   ${GREEN}?${NC} qBittorrent service is running"
        else
            echo -e "   ${YELLOW}?${NC} qBittorrent service is not running"
        fi

        # Check port forwarding service
        if systemctl is-active --quiet protonvpn-port-forwarding.service; then
            echo -e "   ${GREEN}?${NC} Port forwarding service is running"
        else
            echo -e "   ${YELLOW}?${NC} Port forwarding service is not running"
        fi
    else
        echo -e "   ${YELLOW}?${NC} Running without root - limited checks available"
    fi

    echo ""
    return 0
}

# Function to authenticate with qBittorrent API
qbittorrent_login() {
    if [ -z "$WEBUI_USER" ] || [ -z "$WEBUI_PASS" ]; then
        return 1
    fi

    local response
    response=$(curl -s -c /tmp/qbittorrent-cookies.txt \
        -X POST \
        "http://${WEBUI_HOST}:${WEBUI_PORT}/api/v2/auth/login" \
        -d "username=${WEBUI_USER}&password=${WEBUI_PASS}" 2>/dev/null || echo "error")

    if [ "$response" = "Ok." ]; then
        return 0
    else
        return 1
    fi
}

# Function to get qBittorrent global transfer info
get_qbittorrent_speed() {
    if ! qbittorrent_login; then
        return 1
    fi

    local response
    response=$(curl -s -b /tmp/qbittorrent-cookies.txt \
        "http://${WEBUI_HOST}:${WEBUI_PORT}/api/v2/transfer/info" 2>/dev/null || echo "{}")

    # Parse JSON (requires jq or basic parsing)
    if command -v jq >/dev/null 2>&1; then
        echo "$response" | jq -r '.dl_info_speed, .up_info_speed' 2>/dev/null || echo ""
    else
        # Basic parsing without jq
        echo "$response" | grep -o '"dl_info_speed":[0-9]*' | cut -d: -f2 || echo ""
        echo "$response" | grep -o '"up_info_speed":[0-9]*' | cut -d: -f2 || echo ""
    fi
}

# Global variables for summary
MONITOR_START_TIME=0
MONITOR_MAX_DL=0
MONITOR_MAX_UL=0
MONITOR_TOTAL_DL=0
MONITOR_TOTAL_UL=0
MONITOR_SAMPLES=0

# Function to monitor network interface
monitor_interface() {
    echo -e "${CYAN}=== Monitoring VPN Interface Traffic ===${NC}"
    echo ""
    echo "Press Ctrl+C to stop monitoring"
    echo ""

    # Get initial stats
    local prev_rx prev_tx
    if [ "$EUID" -eq 0 ]; then
        read -r prev_rx prev_tx <<< "$(get_interface_stats "$VPN_NAMESPACE" "$VPN_INTERFACE")"
    else
        echo -e "${RED}Error: Need root access to monitor VPN interface${NC}"
        echo "Run with: sudo $0"
        return 1
    fi

    MONITOR_START_TIME=$(date +%s)
    MONITOR_MAX_DL=0
    MONITOR_MAX_UL=0
    MONITOR_TOTAL_DL=0
    MONITOR_TOTAL_UL=0
    MONITOR_SAMPLES=0

    # Header
    printf "%-12s %-15s %-15s %-15s %-15s\n" "Time" "Download" "Upload" "Max DL" "Max UL"
    printf "%s\n" "$(printf '=%.0s' {1..72})"

    while true; do
        sleep "$MONITOR_INTERVAL"

        # Get current stats
        local curr_rx curr_tx
        read -r curr_rx curr_tx <<< "$(get_interface_stats "$VPN_NAMESPACE" "$VPN_INTERFACE")"

        # Calculate speeds (bytes per second)
        local dl_speed=$(( (curr_rx - prev_rx) / MONITOR_INTERVAL ))
        local ul_speed=$(( (curr_tx - prev_tx) / MONITOR_INTERVAL ))

        # Handle negative values (interface reset)
        [ "$dl_speed" -lt 0 ] && dl_speed=0
        [ "$ul_speed" -lt 0 ] && ul_speed=0

        # Update max speeds
        [ "$dl_speed" -gt "$MONITOR_MAX_DL" ] && MONITOR_MAX_DL=$dl_speed
        [ "$ul_speed" -gt "$MONITOR_MAX_UL" ] && MONITOR_MAX_UL=$ul_speed

        # Update totals
        MONITOR_TOTAL_DL=$((MONITOR_TOTAL_DL + dl_speed * MONITOR_INTERVAL))
        MONITOR_TOTAL_UL=$((MONITOR_TOTAL_UL + ul_speed * MONITOR_INTERVAL))
        MONITOR_SAMPLES=$((MONITOR_SAMPLES + 1))

        # Display current speeds
        local timestamp=$(date +%H:%M:%S)
        printf "%-12s %-15s %-15s %-15s %-15s\n" \
            "$timestamp" \
            "$(format_speed $dl_speed)" \
            "$(format_speed $ul_speed)" \
            "$(format_speed $MONITOR_MAX_DL)" \
            "$(format_speed $MONITOR_MAX_UL)"

        # Update previous values
        prev_rx=$curr_rx
        prev_tx=$curr_tx
    done
}

# Function to show summary statistics
show_summary() {
    local duration=$1
    local total_dl=$2
    local total_ul=$3
    local max_dl=$4
    local max_ul=$5

    echo ""
    echo -e "${CYAN}=== Summary Statistics ===${NC}"
    echo ""
    echo "Monitoring duration: ${duration}s"
    echo "Total downloaded: $(format_bytes $total_dl)"
    echo "Total uploaded: $(format_bytes $total_ul)"
    echo "Peak download speed: $(format_speed $max_dl)"
    echo "Peak upload speed: $(format_speed $max_ul)"
    echo ""

    if [ "$total_dl" -gt 0 ] || [ "$total_ul" -gt 0 ]; then
        local avg_dl=$((total_dl / duration))
        local avg_ul=$((total_ul / duration))
        echo "Average download speed: $(format_speed $avg_dl)"
        echo "Average upload speed: $(format_speed $avg_ul)"
    fi
}

# Function to suggest test torrents
suggest_test_torrents() {
    echo -e "${CYAN}=== Test Torrent Suggestions ===${NC}"
    echo ""
    echo "To test VPN speed, you can add a well-seeded torrent:"
    echo ""
    echo "1. Ubuntu ISO (recommended - very well seeded):"
    echo "   https://releases.ubuntu.com/22.04/ubuntu-22.04.3-desktop-amd64.iso.torrent"
    echo ""
    echo "2. Debian ISO:"
    echo "   https://cdimage.debian.org/debian-cd/current/amd64/bt-cd/debian-12.2.0-amd64-netinst.iso.torrent"
    echo ""
    echo "3. Linux Mint ISO:"
    echo "   https://torrents.linuxmint.com/torrents/linuxmint-21.2-cinnamon-64bit.iso.torrent"
    echo ""
    echo "Add via qBittorrent WebUI:"
    echo "   http://${WEBUI_HOST}:${WEBUI_PORT}"
    echo ""
}

# Main function
main() {
    echo -e "${BLUE}?????????????????????????????????????????????????????????????${NC}"
    echo -e "${BLUE}?   qBittorrent VPN Speed Test                            ?${NC}"
    echo -e "${BLUE}?????????????????????????????????????????????????????????????${NC}"
    echo ""

    # Check VPN setup
    if ! check_vpn_setup; then
        echo -e "${RED}VPN setup check failed. Please ensure qBittorrent VPN is configured correctly.${NC}"
        exit 1
    fi

    # Parse arguments
    local mode="monitor"
    case "${1:-}" in
        --suggest|--help|-h)
            suggest_test_torrents
            exit 0
            ;;
        --monitor|-m|"")
            mode="monitor"
            ;;
        *)
            echo "Usage: $0 [--monitor|--suggest|--help]"
            echo ""
            echo "Options:"
            echo "  --monitor, -m    Monitor VPN interface traffic (default)"
            echo "  --suggest       Show test torrent suggestions"
            echo "  --help, -h      Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  QBITTORRENT_WEBUI_PORT  WebUI port (default: 8080)"
            echo "  QBITTORRENT_WEBUI_HOST  WebUI host (default: localhost)"
            echo "  QBITTORRENT_WEBUI_USER  WebUI username (optional, for API access)"
            echo "  QBITTORRENT_WEBUI_PASS  WebUI password (optional, for API access)"
            echo "  MONITOR_INTERVAL        Update interval in seconds (default: 2)"
            exit 0
            ;;
    esac

    # Start monitoring
    if [ "$mode" = "monitor" ]; then
        # Set up trap for cleanup
        trap 'echo "";
              local duration=$(( $(date +%s) - MONITOR_START_TIME ));
              show_summary $duration $MONITOR_TOTAL_DL $MONITOR_TOTAL_UL $MONITOR_MAX_DL $MONITOR_MAX_UL;
              exit 0' INT TERM

        monitor_interface
    fi
}

# Run main function
main "$@"
