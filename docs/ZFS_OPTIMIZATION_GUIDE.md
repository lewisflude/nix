# ZFS Optimization Guide

This guide documents the ZFS optimizations applied to this system based on Arch Linux ZFS Wiki best practices.

## Summary of Changes

### 1. **Module Parameters** (`modules/nixos/system/zfs.nix`)

- **bclone support enabled**: Allows `cp --reflink` and other copy-on-write operations
  - Requires ZFS 2.2.2+ with pool feature flags upgraded
  - Run `zpool upgrade npool` if needed (after backup!)

### 2. **Snapshot Strategy** (Enhanced Granularity)

```
frequent:  4 snapshots (every 15 min, 1 hour coverage)
hourly:   24 snapshots (1 day coverage)  
daily:     7 snapshots (1 week coverage)
weekly:    4 snapshots (1 month coverage)
monthly:  12 snapshots (1 year coverage)
```

**Rationale**: Arch Wiki recommends snapshotting at least as often as oldest backup expires. More frequent snapshots provide better point-in-time recovery without significant overhead.

### 3. **Scrubbing** (Optimized Interval)

- **Changed from weekly to monthly**
- **Rationale**: Arch Wiki recommends monthly scrubs for most use cases. Weekly is overkill for a healthy system and creates unnecessary I/O contention.
- For consumer disks, monthly strikes the right balance

### 4. **TRIM Strategy** (Dual Approach)

- **Weekly automatic TRIM** (existing, kept)
- **NEW: Monthly full TRIM** via systemd timer
- **Rationale**: Arch Wiki notes that automatic TRIM and full TRIM differ in operation. Both can be beneficial for SSD health.

### 5. **Dataset Properties** (Runtime Optimization)

New service `zfs-optimize-datasets.service` applies on every boot:

```bash
# Enable relatime (instead of atime=off)
atime=on relatime=on

# Performance: Store extended attributes efficiently  
xattr=sa

# Enable POSIX ACLs
acltype=posixacl
```

**Key Change - `relatime` vs `atime=off`**:

- **Old**: `atime=off` (no access time updates)
- **New**: `atime=on relatime=on` (smart access time updates)
- **Benefits**: 
  - Updates atime only if mtime/ctime changed OR atime not updated in 24h
  - Better compatibility with applications that need atime (mail clients, tmpwatch, etc.)
  - Negligible performance difference on modern systems
  - Arch Wiki recommendation as "best compromise"

### 6. **I/O Scheduler** (`modules/nixos/system/zfs-io-scheduler.nix`)

Automatic per-disk I/O scheduler selection:

```
NVMe devices → 'none' (lowest overhead for NVMe internal scheduling)
SATA SSDs    → 'mq-deadline' (better fairness for SATA)
HDDs         → 'bfq' (better interactive performance)
```

**Rationale**: Arch Wiki notes ZFS works well with modern schedulers. Each device type has optimal settings.

### 7. **Monitoring** (Enhanced)

- **ZED (ZFS Event Daemon)**: Enhanced logging
  - Added `ZED_SYSLOG_SUBCLASS_INCLUDE = "history_event"` for better audit trail
  - LED notifications enabled (if hardware supports)
  
- **Health Check Script**: `scripts/zfs/health-check.sh`
  - Comprehensive pool health monitoring
  - Fragmentation, capacity, errors, scrub status
  - ARC statistics and compression ratios
  - TRIM status per device

## Current ZFS Setup

### Pool Configuration

```
npool: 6.34TB pool (25% used)
├─ nvme-Samsung_SSD_980_PRO_1TB
├─ nvme-Samsung_SSD_990_PRO_2TB
├─ nvme-Samsung_SSD_990_PRO_2TB
└─ ata-WDC_WDS200T2B0B_2TB
```

### Dataset Structure

```
npool/
├─ root/         (128K recordsize, zstd-3 compression)
├─ home/         (128K recordsize, zstd-3 compression)
├─ docker/       (64K recordsize, zstd-3 compression) ✓ optimized
└─ database/     (64K recordsize, zstd-3 compression) ✓ optimized
```

### ARC Configuration

- **Jupiter host**: 16GB ARC limit (gaming priority)
- **Rationale**: With 64GB RAM, 16GB ARC leaves plenty for games while still providing substantial cache

## Commands Reference

### Health Monitoring

```bash
# Run comprehensive health check
./scripts/zfs/health-check.sh

# Check pool status
zpool status -v npool

# Check ARC usage
cat /proc/spl/kstat/zfs/arcstats | grep "^c\|^size"

# Check compression effectiveness
zfs get compressratio,used npool

# Check TRIM status
zpool status -t npool
```

### Maintenance

```bash
# Manual scrub
zpool scrub npool

# Manual TRIM
zpool trim npool

# Check for pool upgrades
zpool status | grep feature
zpool upgrade  # List available upgrades
zpool upgrade npool  # Apply upgrades (BACKUP FIRST!)

# Enable bclone (if pool upgraded)
# Already enabled via kernel module parameter
```

### Snapshot Management

```bash
# List all snapshots
zfs list -t snapshot

# Create manual snapshot
zfs snapshot npool/home@backup-$(date +%Y%m%d)

# Rollback to snapshot
zfs rollback npool/home@snapshot-name

# Delete snapshot
zfs destroy npool/home@snapshot-name

# Clone snapshot (for testing)
zfs clone npool/home@snapshot-name npool/test-clone
```

### Performance Tuning

```bash
# Check dataset properties
zfs get all npool/docker | grep -E 'atime|compress|recordsize|sync'

# For databases (if needed)
zfs set recordsize=8K npool/database
zfs set logbias=throughput npool/database
zfs set primarycache=metadata npool/database

# For /tmp (if on ZFS)
zfs set sync=disabled npool/tmp
zfs set setuid=off npool/tmp
zfs set devices=off npool/tmp
```

## Maintenance Schedule

| Task | Frequency | Timer | Description |
|------|-----------|-------|-------------|
| Snapshots (frequent) | 15 min | `zfs-snapshot-frequent.timer` | 1 hour recovery window |
| Snapshots (hourly) | 1 hour | `zfs-snapshot-hourly.timer` | 1 day recovery window |
| Snapshots (daily) | Daily | `zfs-snapshot-daily.timer` | 1 week recovery window |
| Snapshots (weekly) | Weekly | `zfs-snapshot-weekly.timer` | 1 month recovery window |
| Snapshots (monthly) | Monthly | `zfs-snapshot-monthly.timer` | 1 year recovery window |
| Auto-TRIM | Weekly | `zfs-trim.timer` | Automatic TRIM |
| Full TRIM | Monthly | `zfs-trim-monthly.timer` | Full pool TRIM |
| Scrub | Monthly | `zfs-scrub.timer` | Data integrity check |

## Troubleshooting

### High Memory Usage

ZFS ARC will use up to the configured limit (16GB on Jupiter). This is normal and by design. The ARC releases memory when applications need it.

**Check current ARC usage**:
```bash
grep "^size\|^c_max" /proc/spl/kstat/zfs/arcstats
```

### Pool Won't Import at Boot

**Check hostid**:
```bash
hostid
cat /etc/hostid  # Should match
```

If mismatched, ZFS thinks pool is in use by another system.

### Slow Boot

**Check if unavailable pools in cache**:
```bash
zdb -C  # Check zpool.cache
```

**Fix**:
```bash
zpool set cachefile=/etc/zfs/zpool.cache npool
# Then rebuild initramfs
```

### Compression Not Working

Compression only affects new data, not existing data.

**Verify compression is enabled**:
```bash
zfs get compression npool
```

**Check actual compression ratio**:
```bash
zfs get compressratio npool
```

## Advanced Features

### Copy-on-Write (bclone)

Now that bclone is enabled, you can use instant file copies:

```bash
# Instant copy (shares blocks until modified)
cp --reflink=auto source.file dest.file

# rsync with reflink support
rsync -av --reflink=auto /source/ /dest/
```

### Encryption (for new datasets)

If you need encrypted datasets:

```bash
# Create encrypted dataset
zfs create -o encryption=on -o keyformat=passphrase npool/encrypted

# Or with key file
dd if=/dev/random of=/root/dataset.key bs=32 count=1
zfs create -o encryption=on -o keyformat=raw \
           -o keylocation=file:///root/dataset.key npool/encrypted
```

### Send/Receive (for backups)

```bash
# Send snapshot to another pool
zfs send npool/home@backup | zfs recv backup_pool/home

# Incremental send
zfs send -i @old @new npool/home | zfs recv backup_pool/home

# Send over SSH
zfs send npool/home@backup | ssh remote zfs recv remote_pool/home
```

## References

- [Arch Linux ZFS Wiki](https://wiki.archlinux.org/title/ZFS)
- [OpenZFS Documentation](https://openzfs.github.io/openzfs-docs/)
- [ZFS Best Practices Guide](https://www.solaris-cookbook.eu/solaris/solaris-10-zfs-best-practices/)
- [OpenZFS Tuning Guide](https://openzfs.github.io/openzfs-docs/Performance%20and%20Tuning/Workload%20Tuning.html)

## Changelog

**2026-01-21**: Initial optimization pass based on Arch Wiki recommendations
- Enabled bclone support
- Enhanced snapshot granularity (added frequent and hourly)
- Changed scrub from weekly to monthly
- Added monthly full TRIM
- Migrated from `atime=off` to `relatime`
- Added I/O scheduler optimization per device type
- Enhanced ZED logging
- Added comprehensive health check script
