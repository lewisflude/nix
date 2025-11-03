# Disk Cleanup Analysis

**Date:** $(date)
**Status:** ⚠️ CRITICAL - Both disks at 100% capacity (65MB free each)

## Immediate Actions (Safe to Delete)

### 1. Trash Directories (~1.1GB total)

- `/mnt/disk1/.Trash-1000/` - 745MB
- `/mnt/disk2/.Trash-1000/` - 382MB

**Action:** Run `sudo /home/lewis/.config/nix/scripts/quick-cleanup.sh` or manually:

```bash
sudo rm -rf /mnt/disk1/.Trash-1000/* /mnt/disk2/.Trash-1000/*
```

### 2. Empty Directories (57 found)

- Minimal space but cleans up clutter
- Automatically handled by quick-cleanup.sh

## Major Space Consumers

### Torrents Directories (155GB total)

- `/mnt/disk1/torrents/` - 56GB
- `/mnt/disk2/torrents/` - 99GB

**Breakdown:**

- TV shows: 198GB (disk1) + 307GB (disk2) = **505GB**
- XXX content: 29GB (disk1) + 83GB (disk2) = **112GB**
- Movies: 4GB (disk1) + 8.5MB (disk2) = **4GB**
- Music/samples: Various sample packs totaling several GB

**Recommendation:**

- If these torrents have been moved to `/media/`, you can delete the torrent directories
- Check if completed downloads exist in both `torrents/` and `media/` directories
- Consider running: `sudo rmlint /mnt/disk1/torrents /mnt/disk2/torrents /mnt/disk1/media /mnt/disk2/media` to find duplicates

### Usenet Directories (6.9GB total)

- `/mnt/disk1/usenet/` - 4GB
- `/mnt/disk2/usenet/` - 2.9GB

**Recommendation:** Review and delete old completed downloads if they're already in `/media/`

### Media Directories (13TB each!)

- `/mnt/disk1/media/` - 13TB
- `/mnt/disk2/media/` - 13TB

**Largest individual files found:**

- Movies: Some are 66-78GB each (likely 4K Remux files)
- TV shows: Some are 11-12GB each

**This is your main storage - be very careful here!**

## Analysis Tools Created

1. **`find-files-to-delete.sh`** - Comprehensive analysis of deletable files
2. **`quick-cleanup.sh`** - Safe cleanup (trash + empty dirs only)

## Recommended Strategy

1. **Immediate (do now):**
   - Run `quick-cleanup.sh` to free ~1.1GB
   - This buys you a tiny bit of breathing room

2. **Short-term (today):**
   - Review torrents directories - if completed downloads are in `/media/`, delete from `/torrents/`
   - Review usenet directories - same principle
   - This could free 150-200GB

3. **Medium-term (this week):**
   - Run `rmlint` to find duplicate files between:
     - `torrents/` and `media/` directories
     - `disk1/media/` and `disk2/media/` (if you have redundancy)
   - Consider removing very large Remux files if you have streaming copies

4. **Long-term:**
   - Set up automated cleanup of completed torrents/usenet downloads
   - Consider using hardlinks if you want to keep both `torrents/` and `media/` copies
   - Review if you need 13TB of media on each disk (is there redundancy?)

## Commands Reference

```bash
# Find large files (>10GB)
sudo find /mnt/disk1 /mnt/disk2 -type f -size +10G -exec ls -lh {} \;

# Check for duplicates (requires rmlint)
sudo rmlint /mnt/disk1 /mnt/disk2

# Find files older than X days in torrents
sudo find /mnt/disk1/torrents /mnt/disk2/torrents -type f -mtime +30

# Check disk space
df -h /mnt/disk1 /mnt/disk2

# Check what's using space
sudo du -sh /mnt/disk1/* /mnt/disk2/* | sort -h | tail -20
```

## Warnings

⚠️ **DO NOT DELETE FROM `/media/` DIRECTORIES** without:

- Verifying files are backed up elsewhere
- Confirming they're duplicates
- Ensuring you have a backup strategy

⚠️ **MergerFS Configuration:**

- Your system uses MergerFS with `minfreespace=1G`
- Both disks must have >1GB free for writes to succeed
- Currently both have only 65MB free - writes will fail!
