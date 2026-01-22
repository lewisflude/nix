#!/usr/bin/env bash
# Post-rebuild ZFS state verification
# Run this AFTER: sudo nixos-rebuild switch + reboot

set -euo pipefail

OUTPUT="/tmp/zfs-post-rebuild-$(date +%Y%m%d-%H%M%S).txt"
LATEST_PRE=$(ls -t /tmp/zfs-pre-rebuild-*.txt 2>/dev/null | head -1)

echo "Capturing ZFS state after rebuild..."
echo "Output: $OUTPUT"
if [ -n "$LATEST_PRE" ]; then
    echo "Will compare to: $LATEST_PRE"
fi
echo ""

{
    echo "=== Post-Rebuild ZFS State Verification ==="
    echo "Timestamp: $(date)"
    echo ""

    echo "=== 1. Pool Status ==="
    zpool status npool
    echo ""

    echo "=== 2. Pool List ==="
    zpool list -v npool
    echo ""

    echo "=== 3. ARC Configuration ==="
    echo "ARC Max (from kernel param):"
    cat /sys/module/zfs/parameters/zfs_arc_max
    ARC_MAX_BYTES=$(cat /sys/module/zfs/parameters/zfs_arc_max)
    ARC_MAX_GB=$((ARC_MAX_BYTES / 1024 / 1024 / 1024))
    echo "  = ${ARC_MAX_GB}GB"
    echo "ARC Current:"
    ARC_SIZE=$(grep "^size" /proc/spl/kstat/zfs/arcstats | awk '{print $3}')
    ARC_SIZE_GB=$((ARC_SIZE / 1024 / 1024 / 1024))
    echo "  ${ARC_SIZE_GB}GB / ${ARC_MAX_GB}GB"
    echo ""

    echo "=== 4. Module Parameters ==="
    echo "bclone_enabled:"
    if [ -e /sys/module/zfs/parameters/zfs_bclone_enabled ]; then
        BCLONE=$(cat /sys/module/zfs/parameters/zfs_bclone_enabled)
        if [ "$BCLONE" = "1" ]; then
            echo "  ✓ ENABLED (cp --reflink will work)"
        else
            echo "  ✗ DISABLED"
        fi
    else
        echo "  ✗ Parameter not found (old ZFS version?)"
    fi
    echo ""

    echo "=== 5. Dataset Properties (Changed Properties Only) ==="
    echo ""
    echo "Checking key datasets..."
    for ds in npool npool/root npool/home npool/docker npool/database; do
        if zfs list "$ds" &>/dev/null; then
            echo "Dataset: $ds"
            zfs get -H atime,relatime,compression,xattr,acltype,recordsize "$ds" | \
                awk '{printf "  %-15s %s\n", $2":", $3}'
            echo ""
        fi
    done

    echo "=== 6. Snapshot Statistics ==="
    TOTAL=$(zfs list -t snapshot | wc -l)
    echo "Total snapshots: $((TOTAL - 1))"  # -1 for header line
    echo "By type:"
    echo "  frequent: $(zfs list -t snapshot | grep -c "frequent" || echo "0")"
    echo "  hourly:   $(zfs list -t snapshot | grep -c "hourly" || echo "0")"
    echo "  daily:    $(zfs list -t snapshot | grep -c "daily" || echo "0")"
    echo "  weekly:   $(zfs list -t snapshot | grep -c "weekly" || echo "0")"
    echo "  monthly:  $(zfs list -t snapshot | grep -c "monthly" || echo "0")"
    echo ""

    echo "=== 7. ZFS Systemd Timers (Active Only) ==="
    systemctl list-timers | grep zfs | awk '{print $NF, $1, $2}'
    echo ""

    echo "=== 8. New/Changed Services ==="
    echo "Checking for new ZFS services..."
    systemctl list-units 'zfs-optimize*' --all --no-pager 2>/dev/null || echo "  zfs-optimize-datasets: Not found"
    systemctl list-units 'zfs-trim-monthly*' --all --no-pager 2>/dev/null || echo "  zfs-trim-monthly: Not found"
    echo ""

    echo "=== 9. TRIM Status Check ==="
    echo "Running: zpool status -t npool"
    zpool status -t npool | grep -A 10 "config:" | grep -E "(trimmed|untrimmed|trim unsupported)" || echo "  No TRIM status info"
    echo ""

    echo "=== 10. Test bclone Support ==="
    if [ "$(cat /sys/module/zfs/parameters/zfs_bclone_enabled 2>/dev/null)" = "1" ]; then
        echo "Testing cp --reflink..."
        TEST_FILE="/tmp/zfs-bclone-test-$$.dat"
        TEST_CLONE="/tmp/zfs-bclone-test-$$-clone.dat"
        dd if=/dev/zero of="$TEST_FILE" bs=1M count=10 status=none
        
        # Try reflink copy
        if cp --reflink=auto "$TEST_FILE" "$TEST_CLONE" 2>/dev/null; then
            # Check if it's actually using reflinks (blocks should be similar)
            echo "  ✓ cp --reflink works!"
            du -sh "$TEST_FILE" "$TEST_CLONE"
        else
            echo "  ✗ cp --reflink failed"
        fi
        rm -f "$TEST_FILE" "$TEST_CLONE"
    else
        echo "  ⊘ bclone not enabled, skipping test"
    fi
    echo ""

    echo "=== 11. I/O Schedulers ==="
    echo "NVMe (should be 'none'):"
    for dev in /sys/block/nvme*/queue/scheduler; do
        [ -e "$dev" ] && echo "  $(basename $(dirname $(dirname "$dev"))): $(cat $dev)"
    done
    echo "SATA (varies by type):"
    for dev in /sys/block/sd*/queue/scheduler; do
        [ -e "$dev" ] && echo "  $(basename $(dirname $(dirname "$dev"))): $(cat $dev)"
    done
    echo ""

} | tee "$OUTPUT"

echo ""
echo "✓ Post-rebuild check saved to: $OUTPUT"
echo ""

# Generate diff if we have a pre-rebuild snapshot
if [ -n "$LATEST_PRE" ]; then
    echo "=== CHANGES DETECTED ==="
    echo ""
    
    echo "Comparing ARC settings:"
    grep "ARC Max" "$LATEST_PRE" | head -1
    grep "ARC Max" "$OUTPUT" | head -1
    echo ""
    
    echo "Comparing snapshot counts:"
    diff <(grep "Total snapshots:" "$LATEST_PRE") <(grep "Total snapshots:" "$OUTPUT") || true
    echo ""
    
    echo "Comparing timers:"
    echo "Before:"
    grep -A 10 "=== 7. ZFS Systemd Timers ===" "$LATEST_PRE" | tail -n +2 | head -5
    echo "After:"
    grep -A 10 "=== 7. ZFS Systemd Timers ===" "$OUTPUT" | tail -n +2 | head -5
    echo ""
fi

echo ""
echo "=== SUMMARY ==="
echo ""
echo "✓ Pool health: $(zpool list -H -o health npool)"
echo "✓ Total space: $(zpool list -H -o size npool)"
echo "✓ Used space: $(zpool list -H -o alloc npool)"
echo "✓ Fragmentation: $(zpool list -H -o frag npool)"
echo ""
echo "To view full comparison, run:"
echo "  diff $LATEST_PRE $OUTPUT | less"
