# ZFS Rebuild Testing Checklist

## Before Rebuild

Run the pre-rebuild snapshot script:
```bash
./scripts/zfs/pre-rebuild-snapshot.sh
```

Or manually capture key metrics:

### 1. Check Current ARC Size
```bash
# Current ARC max setting
cat /sys/module/zfs/parameters/zfs_arc_max
# Expected: 12884901888 (12GB)

# Current ARC usage
echo "ARC: $(( $(grep "^size" /proc/spl/kstat/zfs/arcstats | awk '{print $3}') / 1024 / 1024 / 1024 ))GB / $(( $(cat /sys/module/zfs/parameters/zfs_arc_max) / 1024 / 1024 / 1024 ))GB"
```

### 2. Check Snapshot Schedule
```bash
# See what's enabled
systemctl list-timers | grep zfs-snapshot

# Count current snapshots
zfs list -t snapshot | wc -l

# Snapshots by type
for type in frequent hourly daily weekly monthly; do
  echo "$type: $(zfs list -t snapshot | grep -c $type || echo 0)"
done
```

### 3. Check Scrub Interval
```bash
systemctl status zfs-scrub.timer
# Note the "Trigger:" line - weekly or monthly?
```

### 4. Check Module Parameters
```bash
# bclone support (for cp --reflink)
cat /sys/module/zfs/parameters/zfs_bclone_enabled 2>/dev/null || echo "not found"
```

### 5. Check Dataset Properties
```bash
# Key datasets
for ds in npool npool/root npool/home npool/docker; do
  echo "=== $ds ==="
  zfs get atime,relatime,compression,xattr,acltype,recordsize $ds
  echo ""
done
```

### 6. Check I/O Schedulers
```bash
# NVMe devices
for d in /sys/block/nvme*/queue/scheduler; do 
  [ -e "$d" ] && echo "$(basename $(dirname $(dirname $d))): $(cat $d)"
done

# SATA devices
for d in /sys/block/sd*/queue/scheduler; do 
  [ -e "$d" ] && echo "$(basename $(dirname $(dirname $d))): $(cat $d)"
done
```

---

## After Rebuild & Reboot

Run the post-rebuild check script:
```bash
./scripts/zfs/post-rebuild-check.sh
```

Or manually verify changes:

### 1. Verify ARC Setting
```bash
# Should still be 12GB (12884901888 bytes)
cat /sys/module/zfs/parameters/zfs_arc_max
```

### 2. Verify Snapshot Timers
```bash
# List active ZFS timers
systemctl list-timers | grep zfs-snapshot

# Verify configuration
systemctl cat zfs-snapshot-frequent.timer
systemctl cat zfs-snapshot-hourly.timer
```

### 3. Verify Scrub Interval
```bash
# Should show weekly
systemctl status zfs-scrub.timer | grep "Trigger:"
```

### 4. Test bclone (if enabled)
```bash
# Create test file on ZFS
dd if=/dev/zero of=/tmp/test.dat bs=1M count=100

# Try reflink copy
cp --reflink=auto /tmp/test.dat /tmp/test-clone.dat

# Check if it worked (should be instant)
ls -lh /tmp/test*.dat
rm /tmp/test*.dat
```

### 5. Verify Dataset Properties
```bash
# Check if properties changed
for ds in npool npool/root npool/home; do
  echo "=== $ds ==="
  zfs get atime,relatime,xattr,acltype $ds | grep -v "inherit"
  echo ""
done
```

### 6. Check for New Services
```bash
# Look for new optimization services
systemctl list-units 'zfs-optimize*' --all
systemctl list-units 'zfs-trim-monthly*' --all
```

### 7. Monitor First Snapshot
```bash
# Wait 15 minutes (if frequent enabled), then check
zfs list -t snapshot | tail -5

# Watch logs
journalctl -u zfs-snapshot-frequent -f
```

---

## Quick Health Check Anytime

```bash
# Pool status
zpool status npool

# Pool capacity and health
zpool list npool

# Recent snapshots
zfs list -t snapshot -s creation | tail -10

# Active timers
systemctl list-timers | grep zfs

# ARC usage
echo "ARC: $(( $(grep "^size" /proc/spl/kstat/zfs/arcstats | awk '{print $3}') / 1024 / 1024 / 1024 ))GB / $(( $(cat /sys/module/zfs/parameters/zfs_arc_max) / 1024 / 1024 / 1024 ))GB"

# Run comprehensive health check
./scripts/zfs/health-check.sh
```

---

## Rollback Commands (if needed)

If something goes wrong:

```bash
# Stop all ZFS timers
sudo systemctl stop 'zfs-*.timer'

# Revert to previous generation
sudo nixos-rebuild switch --rollback

# Reboot
sudo reboot
```

---

## Expected Changes (Based on Current Config)

Since you reverted most changes, the rebuild should show:

**NO CHANGES expected** (config is back to original):
- ❌ No bclone enabled
- ❌ No frequent/hourly snapshots (still 0)
- ❌ No monthly TRIM service
- ❌ No dataset optimization service
- ❌ No relatime changes
- ✓ Scrub stays weekly
- ✓ ARC stays at current setting (12GB or 16GB from host config)

**Only changes if you had modified earlier:**
- Any formatting/whitespace cleanup
- Documentation additions

The config is essentially back to baseline!
