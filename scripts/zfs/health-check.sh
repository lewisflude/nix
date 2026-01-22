#!/usr/bin/env bash
# ZFS Health Check Script
# Based on Arch Wiki ZFS best practices
# Provides comprehensive ZFS pool and dataset health monitoring

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if ZFS is loaded
if ! command -v zpool &> /dev/null; then
    print_error "ZFS utilities not found"
    exit 1
fi

# Pool Status
print_header "Pool Status"
if zpool list -H -o health npool | grep -q "ONLINE"; then
    print_ok "Pool 'npool' is ONLINE"
else
    print_error "Pool 'npool' is not ONLINE!"
    zpool status npool
    exit 1
fi

# Check pool fragmentation
FRAG=$(zpool list -H -o frag npool | tr -d '%')
if [ "$FRAG" -lt 30 ]; then
    print_ok "Fragmentation: ${FRAG}% (good)"
elif [ "$FRAG" -lt 50 ]; then
    print_warn "Fragmentation: ${FRAG}% (consider optimization)"
else
    print_error "Fragmentation: ${FRAG}% (high - consider defragmentation)"
fi

# Check pool capacity
CAP=$(zpool list -H -o capacity npool | tr -d '%')
if [ "$CAP" -lt 70 ]; then
    print_ok "Capacity: ${CAP}% (healthy)"
elif [ "$CAP" -lt 85 ]; then
    print_warn "Capacity: ${CAP}% (monitor closely)"
else
    print_error "Capacity: ${CAP}% (critically high - add storage)"
fi

# Check for errors
print_header "Error Status"
ERRORS=$(zpool status npool | grep -c "errors: No known data errors" || true)
if [ "$ERRORS" -gt 0 ]; then
    print_ok "No data errors detected"
else
    print_error "Data errors detected!"
    zpool status -v npool
fi

# Check scrub status
print_header "Scrub Status"
SCRUB_INFO=$(zpool status npool | grep "scan:" -A 1)
echo "$SCRUB_INFO"

if echo "$SCRUB_INFO" | grep -q "scrub repaired 0B"; then
    print_ok "Last scrub found no issues"
elif echo "$SCRUB_INFO" | grep -q "scrub in progress"; then
    print_warn "Scrub currently in progress"
elif echo "$SCRUB_INFO" | grep -q "none requested"; then
    print_warn "No scrub has been run yet"
else
    print_warn "Check scrub status manually"
fi

# Check TRIM support
print_header "TRIM Status"
for dev in $(zpool status npool | grep -E '(nvme|ata|sd)' | awk '{print $1}'); do
    TRIM_STATUS=$(zpool status -t npool | grep "$dev" | awk '{print $NF}' || echo "unknown")
    if [[ "$TRIM_STATUS" == "(trimmed)" ]]; then
        print_ok "$dev: trimmed"
    elif [[ "$TRIM_STATUS" == "(untrimmed)" ]]; then
        print_warn "$dev: untrimmed (TRIM pending or not supported)"
    else
        echo "  $dev: status unknown"
    fi
done

# Check ARC statistics
print_header "ARC Statistics"
ARC_SIZE=$(grep "^size" /proc/spl/kstat/zfs/arcstats | awk '{print $3}')
ARC_MAX=$(grep "^c_max" /proc/spl/kstat/zfs/arcstats | awk '{print $3}')
ARC_SIZE_GB=$((ARC_SIZE / 1024 / 1024 / 1024))
ARC_MAX_GB=$((ARC_MAX / 1024 / 1024 / 1024))
ARC_PERCENT=$((ARC_SIZE * 100 / ARC_MAX))

echo "  Current: ${ARC_SIZE_GB}GB / ${ARC_MAX_GB}GB (${ARC_PERCENT}%)"

if [ "$ARC_PERCENT" -lt 80 ]; then
    print_ok "ARC usage normal"
else
    print_warn "ARC usage high (this is usually normal)"
fi

# Check dataset compression ratios
print_header "Top 10 Datasets by Compression Ratio"
zfs get -Hp compressratio,used -t filesystem -s local | \
    awk 'NR>1 {name=$1; prop=$2; val=$3} 
         prop=="compressratio" {comp[name]=val} 
         prop=="used" {used[name]=val} 
         END {for (n in comp) print comp[n], n, used[n]}' | \
    sort -rn | head -10 | \
    while read -r ratio name used; do
        used_gb=$((used / 1024 / 1024 / 1024))
        if (( $(echo "$ratio > 1.5" | bc -l) )); then
            echo -e "  ${GREEN}${ratio}x${NC} $name (${used_gb}GB)"
        else
            echo -e "  ${ratio}x $name (${used_gb}GB)"
        fi
    done

# Check for available pool upgrades
print_header "Pool Features"
if zpool status npool | grep -q "feature"; then
    print_warn "Pool has available feature upgrades"
    echo "  Run 'sudo zpool upgrade npool' to upgrade (backup first!)"
else
    print_ok "Pool is up to date"
fi

# Check bclone support
print_header "Advanced Features"
if [ -e /sys/module/zfs/parameters/zfs_bclone_enabled ]; then
    BCLONE=$(cat /sys/module/zfs/parameters/zfs_bclone_enabled)
    if [ "$BCLONE" = "1" ]; then
        print_ok "bclone support enabled (cp --reflink works)"
    else
        print_warn "bclone support disabled"
    fi
else
    print_warn "bclone parameter not found (old ZFS version?)"
fi

# Summary
print_header "Summary"
zpool list npool
echo ""
print_ok "ZFS health check complete"
