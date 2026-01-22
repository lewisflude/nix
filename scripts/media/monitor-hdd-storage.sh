#!/usr/bin/env bash

# HDD Storage and I/O Monitor for qBittorrent + Jellyfin + Media Server Setup
# Purpose: Monitor disk utilization, I/O activity, and health for 24TB HDD array
# Usage: monitor-hdd-storage.sh [--continuous] [--interval <seconds>] [--json]

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STORAGE_PATH="${STORAGE_PATH:-/mnt/storage}"
INCOMPLETE_PATH="${INCOMPLETE_PATH:-/mnt/nvme/qbittorrent/incomplete}"
INTERVAL="${INTERVAL:-5}"
CONTINUOUS="${CONTINUOUS:-false}"
JSON_OUTPUT="${JSON_OUTPUT:-false}"

# Thresholds (in percentage or Mbps)
DISK_USAGE_WARN=80
DISK_USAGE_CRIT=90
IO_BUSY_WARN=70
IO_BUSY_CRIT=90

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    local title="$1"
    echo -e "\n${BLUE}=== ${title} ===${NC}"
}

print_info() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_value() {
    local label="$1"
    local value="$2"
    local unit="${3:-}"
    printf "  %-30s: %s %s\n" "$label" "$value" "$unit"
}

format_bytes() {
    local bytes=$1
    if ((bytes >= 1099511627776)); then
        echo "$(printf '%.2f' $((bytes * 100 / 1099511627776)))TB"
    elif ((bytes >= 1073741824)); then
        echo "$(printf '%.2f' $((bytes * 100 / 1073741824)))GB"
    elif ((bytes >= 1048576)); then
        echo "$(printf '%.2f' $((bytes * 100 / 1048576)))MB"
    else
        echo "${bytes}B"
    fi
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Some operations require root. Some features will be limited."
        return 1
    fi
}

# ============================================================================
# Disk Usage Monitoring
# ============================================================================

monitor_disk_usage() {
    print_header "Disk Usage Analysis"

    # Check main storage
    local storage_info=$(df -B1 "$STORAGE_PATH" 2>/dev/null | tail -1)
    local storage_device=$(echo "$storage_info" | awk '{print $1}')
    local storage_total=$(echo "$storage_info" | awk '{print $2}')
    local storage_used=$(echo "$storage_info" | awk '{print $3}')
    local storage_avail=$(echo "$storage_info" | awk '{print $4}')
    local storage_percent=$(echo "$storage_info" | awk '{print $5}' | sed 's/%//')

    print_value "Storage Device" "$storage_device"
    print_value "Total Capacity" "$(format_bytes "$storage_total")"
    print_value "Used Space" "$(format_bytes "$storage_used")" "($(printf '%d' "$storage_percent")%)"
    print_value "Available Space" "$(format_bytes "$storage_avail")"

    # Warn if approaching capacity
    if ((storage_percent >= DISK_USAGE_CRIT)); then
        print_error "CRITICAL: Storage at ${storage_percent}% capacity!"
    elif ((storage_percent >= DISK_USAGE_WARN)); then
        print_warn "WARNING: Storage at ${storage_percent}% capacity"
    else
        print_info "Storage usage healthy at ${storage_percent}%"
    fi

    # Check incomplete downloads path
    if [[ -d "$INCOMPLETE_PATH" ]]; then
        local incomplete_info=$(df -B1 "$INCOMPLETE_PATH" 2>/dev/null | tail -1)
        local incomplete_total=$(echo "$incomplete_info" | awk '{print $2}')
        local incomplete_used=$(echo "$incomplete_info" | awk '{print $3}')
        local incomplete_percent=$(echo "$incomplete_info" | awk '{print $5}' | sed 's/%//')

        print_value "Incomplete Downloads Device" "$(echo "$incomplete_info" | awk '{print $1}')"
        print_value "SSD Used Space" "$(format_bytes "$incomplete_used")" "($(printf '%d' "$incomplete_percent")%)"
        print_value "SSD Capacity" "$(format_bytes "$incomplete_total")"

        if ((incomplete_percent >= DISK_USAGE_WARN)); then
            print_warn "SSD staging area getting full (${incomplete_percent}%)"
        fi
    fi

    # Breakdown by category
    print_header "Storage by Category"
    for category in movies tv music books pc; do
        local category_path="$STORAGE_PATH/$category"
        if [[ -d "$category_path" ]]; then
            local category_size=$(du -sb "$category_path" 2>/dev/null | awk '{print $1}')
            local category_formatted=$(format_bytes "$category_size")
            print_value "  $category" "$category_formatted"
        fi
    done
}

# ============================================================================
# I/O Activity Monitoring
# ============================================================================

monitor_io_activity() {
    print_header "Disk I/O Activity"

    check_root || return 0

    # Get iostat if available
    if ! command -v iostat &>/dev/null; then
        print_warn "iostat not available (install sysstat package)"
        return 0
    fi

    # Get device names from storage path
    local storage_devices=$(df "$STORAGE_PATH" 2>/dev/null | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//')
    local incomplete_devices=""

    if [[ -d "$INCOMPLETE_PATH" ]]; then
        incomplete_devices=$(df "$INCOMPLETE_PATH" 2>/dev/null | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//')
    fi

    # Run iostat for 2 samples to get instantaneous data
    iostat -x 2 1 2>/dev/null | grep -E "^(Device|${storage_devices}|${incomplete_devices})" | tail -n +2 | while read -r line; do
        if [[ -n "$line" ]]; then
            local device=$(echo "$line" | awk '{print $1}')
            local r_sec=$(echo "$line" | awk '{print $6}')
            local w_sec=$(echo "$line" | awk '{print $7}')
            local util=$(echo "$line" | awk '{print $NF}' | sed 's/,/\./')

            # Convert iostat format (might be comma-separated in some locales)
            util=$(echo "$util" | sed 's/,/\./')

            local status="${GREEN}✓${NC}"
            if (( $(echo "$util >= $IO_BUSY_CRIT" | bc -l) )); then
                status="${RED}✗${NC}"
            elif (( $(echo "$util >= $IO_BUSY_WARN" | bc -l) )); then
                status="${YELLOW}⚠${NC}"
            fi

            printf "  ${status} %-10s: %8.2f MB/s read, %8.2f MB/s write, %6.2f%% util\n" \
                "$device" "$r_sec" "$w_sec" "$util"
        fi
    done
}

# ============================================================================
# HDD Health Monitoring (SMART)
# ============================================================================

monitor_hdd_health() {
    print_header "HDD Health (SMART Data)"

    check_root || {
        print_warn "Root access required for SMART monitoring"
        return 0
    }

    if ! command -v smartctl &>/dev/null; then
        print_warn "smartctl not available (install smartmontools package)"
        return 0
    fi

    # Find drives in storage path
    local storage_device=$(df "$STORAGE_PATH" 2>/dev/null | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//')

    # Get SMART status
    if smartctl -i "$storage_device" &>/dev/null; then
        local overall_status=$(smartctl -H "$storage_device" 2>/dev/null | grep "SMART overall-health" | awk -F':' '{print $2}' | xargs)

        if [[ "$overall_status" == "PASSED" ]]; then
            print_info "Overall Health: PASSED"
        else
            print_error "Overall Health: $overall_status"
        fi

        # Get relevant SMART attributes
        echo -e "\n  ${BLUE}Key SMART Attributes:${NC}"
        smartctl -A "$storage_device" 2>/dev/null | grep -E "^[[:space:]]*[0-9]+[[:space:]]+(Reallocated_Sector|Spin_Retry|Load_Cycle|Temperature|Power_On_Hours|Seek_Error)" | while read -r line; do
            local attr_id=$(echo "$line" | awk '{print $1}')
            local attr_name=$(echo "$line" | awk '{print $2}')
            local value=$(echo "$line" | awk '{print $10}')
            printf "    %-30s: %s\n" "$attr_name" "$value"
        done

        # Temperature
        local temp=$(smartctl -A "$storage_device" 2>/dev/null | grep -i "temperature" | awk '{print $10}')
        if [[ -n "$temp" ]]; then
            print_value "Drive Temperature" "${temp}°C"
            if ((temp >= 50)); then
                print_warn "HDD temperature is elevated"
            fi
        fi
    else
        print_warn "Could not read SMART data for $storage_device"
    fi
}

# ============================================================================
# Service Status Monitoring
# ============================================================================

monitor_service_status() {
    print_header "Service Status"

    # Check qBittorrent
    if systemctl is-active --quiet qbittorrent; then
        print_info "qBittorrent: Running"
    else
        print_error "qBittorrent: Stopped"
    fi

    # Check Jellyfin
    if systemctl is-active --quiet jellyfin; then
        print_info "Jellyfin: Running"
    else
        print_error "Jellyfin: Stopped"
    fi

    # Check Radarr
    if systemctl is-active --quiet radarr; then
        print_info "Radarr: Running"
    else
        print_error "Radarr: Stopped"
    fi

    # Check Sonarr
    if systemctl is-active --quiet sonarr; then
        print_info "Sonarr: Running"
    else
        print_error "Sonarr: Stopped"
    fi
}

# ============================================================================
# Performance Impact Analysis
# ============================================================================

monitor_contention() {
    print_header "Disk Contention Analysis"

    check_root || return 0

    # Estimate active torrents from process list
    local qb_procs=$(pgrep -f qbittorrent | wc -l)
    local jellyfin_procs=$(pgrep -f jellyfin | wc -l)

    print_value "qBittorrent Processes" "$qb_procs"
    print_value "Jellyfin Processes" "$jellyfin_procs"

    if command -v iotop &>/dev/null; then
        print_header "Top I/O Consumers"
        # Run iotop for 2 seconds, show top 5
        timeout 2 iotop -o -b -n 1 2>/dev/null | grep -E "(qbittorrent|jellyfin|sonarr|radarr|python)" | head -5 || true
    fi

    # Recommendations
    print_header "Recommendations"

    local disk_percent=$(df "$STORAGE_PATH" | tail -1 | awk '{print $5}' | sed 's/%//')
    if ((disk_percent >= DISK_USAGE_CRIT)); then
        print_error "Consider archiving or deleting old content"
    elif ((disk_percent >= DISK_USAGE_WARN)); then
        print_warn "Storage is getting full - plan archiving strategy"
    else
        print_info "Storage usage is healthy"
    fi

    echo -e "\n  ${BLUE}Optimization Tips:${NC}"
    echo "  • Keep incomplete downloads on SSD (/mnt/nvme/qbittorrent/incomplete)"
    echo "  • Final media should reside on HDD (/mnt/storage)"
    echo "  • Monitor when Jellyfin streaming + qBittorrent seeding overlap"
    echo "  • Check SMART health regularly, especially for older drives"
    echo "  • Consider enabling qBittorrent rate limits during peak usage hours"
}

# ============================================================================
# Output Formatting
# ============================================================================

output_json() {
    # Simple JSON output of key metrics
    local storage_info=$(df -B1 "$STORAGE_PATH" 2>/dev/null | tail -1)
    local storage_percent=$(echo "$storage_info" | awk '{print $5}' | sed 's/%//')
    local storage_used=$(echo "$storage_info" | awk '{print $3}')
    local storage_avail=$(echo "$storage_info" | awk '{print $4}')

    cat <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "storage": {
    "path": "$STORAGE_PATH",
    "percent_used": $storage_percent,
    "bytes_used": $storage_used,
    "bytes_available": $storage_avail
  },
  "services": {
    "qbittorrent": $(systemctl is-active --quiet qbittorrent && echo "running" || echo "stopped"),
    "jellyfin": $(systemctl is-active --quiet jellyfin && echo "running" || echo "stopped")
  }
}
EOF
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    while true; do
        clear
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║  HDD Storage & I/O Monitor - Media Server Optimization         ║"
        echo "║  $(date '+%Y-%m-%d %H:%M:%S')${' '*38}║"
        echo "╚════════════════════════════════════════════════════════════════╝"

        monitor_disk_usage
        monitor_io_activity
        monitor_hdd_health
        monitor_service_status
        monitor_contention

        if [[ "$JSON_OUTPUT" == "true" ]]; then
            echo ""
            output_json
        fi

        if [[ "$CONTINUOUS" != "true" ]]; then
            break
        fi

        echo -e "\n${BLUE}[Press Ctrl+C to exit. Refreshing in ${INTERVAL}s...]${NC}"
        sleep "$INTERVAL"
    done
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --continuous)
            CONTINUOUS=true
            shift
            ;;
        --interval)
            INTERVAL="$2"
            shift 2
            ;;
        --json)
            JSON_OUTPUT=true
            shift
            ;;
        --help)
            cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --continuous        Keep refreshing every INTERVAL seconds
  --interval N        Set refresh interval (default: 5 seconds)
  --json              Output results in JSON format
  --help              Show this help message

Environment Variables:
  STORAGE_PATH        Path to storage (default: /mnt/storage)
  INCOMPLETE_PATH     Path to incomplete downloads (default: /mnt/nvme/qbittorrent/incomplete)

Examples:
  # One-time report
  monitor-hdd-storage.sh

  # Continuous monitoring, updating every 10 seconds
  monitor-hdd-storage.sh --continuous --interval 10

  # JSON output for scripting
  monitor-hdd-storage.sh --json
EOF
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

main
