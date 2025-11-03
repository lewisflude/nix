#!/usr/bin/env bash
# Check disk space for media storage
# Helps diagnose SABnzbd "No space left on device" errors

set -euo pipefail

echo "=== Disk Space Check ==="
echo ""

echo "MergerFS mount (/mnt/storage):"
df -h /mnt/storage | tail -1
echo ""

echo "Underlying disks:"
echo "Disk 1 (/mnt/disk1):"
df -h /mnt/disk1 | tail -1
echo ""

echo "Disk 2 (/mnt/disk2):"
df -h /mnt/disk2 | tail -1
echo ""

echo "=== Inode Usage ==="
echo "MergerFS mount:"
df -i /mnt/storage | tail -1
echo ""

echo "Disk 1:"
df -i /mnt/disk1 | tail -1
echo ""

echo "Disk 2:"
df -i /mnt/disk2 | tail -1
echo ""

echo "=== MergerFS Settings ==="
echo "Note: minfreespace=1G means writes will fail if any disk has <1GB free"
echo ""

echo "=== SABnzbd Directories ==="
echo "Checking usenet directories:"
ls -ld /mnt/storage/usenet* 2>/dev/null || echo "Directories not found or not accessible"
echo ""

echo "=== Recommendations ==="
# Get free space in bytes, then convert to GB
DISK1_FREE_BYTES=$(df -B1 /mnt/disk1 | tail -1 | awk '{print $4}')
DISK2_FREE_BYTES=$(df -B1 /mnt/disk2 | tail -1 | awk '{print $4}')
DISK1_FREE_GB=$(echo "scale=2; $DISK1_FREE_BYTES / 1073741824" | bc)
DISK2_FREE_GB=$(echo "scale=2; $DISK2_FREE_BYTES / 1073741824" | bc)

# Check if less than 1GB free (1073741824 bytes)
if [ "$DISK1_FREE_BYTES" -lt 1073741824 ] || [ "$DISK2_FREE_BYTES" -lt 1073741824 ]; then
    echo "⚠️  CRITICAL: One or both disks have less than 1GB free!"
    echo "   Disk 1 free: ${DISK1_FREE_GB}GB"
    echo "   Disk 2 free: ${DISK2_FREE_GB}GB"
    echo ""
    echo "   MergerFS will refuse writes due to minfreespace=1G setting"
    echo "   This is why SABnzbd is failing with 'No space left on device'"
    echo ""
    echo "   ACTION REQUIRED:"
    echo "   1. Free up space on the affected disk(s):"
    echo "      - Delete old/unwanted downloads"
    echo "      - Clean up incomplete downloads"
    echo "      - Remove duplicate or unnecessary files"
    echo "      - Check for large files: find /mnt/disk1 -type f -size +10G -ls"
    echo "      - Check for large files: find /mnt/disk2 -type f -size +10G -ls"
    echo ""
    echo "   2. Consider temporarily lowering minfreespace (RISKY - only if absolutely necessary):"
    echo "      Edit hosts/jupiter/hardware-configuration.nix"
    echo "      Change 'minfreespace=1G' to 'minfreespace=100M' (not recommended)"
    echo ""
    echo "   3. Check what's using space:"
    echo "      du -sh /mnt/disk1/* | sort -h | tail -20"
    echo "      du -sh /mnt/disk2/* | sort -h | tail -20"
else
    echo "✓ Both disks have sufficient free space (>1GB)"
    echo "   Disk 1 free: ${DISK1_FREE_GB}GB"
    echo "   Disk 2 free: ${DISK2_FREE_GB}GB"
fi
