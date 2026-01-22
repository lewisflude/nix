#!/usr/bin/env bash
# Pre-rebuild ZFS state snapshot
# Run this BEFORE: sudo nixos-rebuild switch

set -euo pipefail

OUTPUT="/tmp/zfs-pre-rebuild-$(date +%Y%m%d-%H%M%S).txt"

echo "Capturing ZFS state before rebuild..."
echo "Output: $OUTPUT"
echo ""

{
    echo "=== Pre-Rebuild ZFS State Snapshot ==="
    echo "Timestamp: $(date)"
    echo ""

    echo "=== 1. Pool Status ==="
    zpool status npool
    echo ""

    echo "=== 2. Pool List (Capacity, Fragmentation, Health) ==="
    zpool list -v npool
    echo ""

    echo "=== 3. ARC Configuration ==="
    echo "ARC Max (from kernel param):"
    cat /sys/module/zfs/parameters/zfs_arc_max
    echo "ARC Current Size:"
    grep "^size" /proc/spl/kstat/zfs/arcstats | awk '{print $3}'
    echo "ARC Max Size:"
    grep "^c_max" /proc/spl/kstat/zfs/arcstats | awk '{print $3}'
    echo ""

    echo "=== 4. Module Parameters ==="
    echo "bclone_enabled:"
    cat /sys/module/zfs/parameters/zfs_bclone_enabled 2>/dev/null || echo "Parameter not found"
    echo ""

    echo "=== 5. Dataset Properties (Key Properties Only) ==="
    echo "Root datasets:"
    zfs get -Hp atime,relatime,compression,xattr,acltype,recordsize,sync npool npool/root npool/home npool/docker npool/database 2>/dev/null || true
    echo ""

    echo "=== 6. Snapshot Count and Schedule ==="
    echo "Total snapshots:"
    zfs list -t snapshot | wc -l
    echo ""
    echo "Snapshots by type:"
    zfs list -t snapshot | grep -c "frequent" || echo "frequent: 0"
    zfs list -t snapshot | grep -c "hourly" || echo "hourly: 0"
    zfs list -t snapshot | grep -c "daily" || echo "daily: 0"
    zfs list -t snapshot | grep -c "weekly" || echo "weekly: 0"
    zfs list -t snapshot | grep -c "monthly" || echo "monthly: 0"
    echo ""

    echo "=== 7. ZFS Systemd Timers ==="
    systemctl list-timers | grep zfs
    echo ""

    echo "=== 8. ZFS Services Status ==="
    systemctl status zfs-snapshot-frequent.timer --no-pager 2>/dev/null || echo "frequent: not active"
    echo "---"
    systemctl status zfs-snapshot-hourly.timer --no-pager 2>/dev/null || echo "hourly: not active"
    echo "---"
    systemctl status zfs-scrub.timer --no-pager 2>/dev/null || echo "scrub: not active"
    echo "---"
    systemctl status zfs-trim.timer --no-pager 2>/dev/null || echo "trim: not active"
    echo ""

    echo "=== 9. Custom ZFS Services ==="
    systemctl list-units 'zfs-*' --all --no-pager
    echo ""

    echo "=== 10. TRIM Status ==="
    zpool status -t npool | grep -E "(nvme|ata|sd)" || true
    echo ""

    echo "=== 11. Scrub Status ==="
    zpool status npool | grep -A 2 "scan:"
    echo ""

    echo "=== 12. I/O Scheduler (for ZFS disks) ==="
    echo "NVMe devices:"
    for dev in /sys/block/nvme*/queue/scheduler; do
        if [ -e "$dev" ]; then
            echo "  $(basename $(dirname $(dirname "$dev"))): $(cat $dev)"
        fi
    done
    echo "SATA devices:"
    for dev in /sys/block/sd*/queue/scheduler; do
        if [ -e "$dev" ]; then
            echo "  $(basename $(dirname $(dirname "$dev"))): $(cat $dev)"
        fi
    done
    echo ""

    echo "=== 13. ZED Configuration ==="
    grep -E "ZED_" /etc/zfs/zed.d/zed.rc 2>/dev/null | grep -v "^#" || echo "ZED config not found"
    echo ""

} | tee "$OUTPUT"

echo ""
echo "✓ Pre-rebuild snapshot saved to: $OUTPUT"
echo ""
echo "Next steps:"
echo "1. Run: sudo nixos-rebuild switch"
echo "2. Reboot (to load new kernel params)"
echo "3. Run: ./scripts/zfs/post-rebuild-check.sh"
