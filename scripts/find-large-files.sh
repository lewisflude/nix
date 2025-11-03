#!/usr/bin/env bash
# Find large files to help free up disk space

set -euo pipefail

THRESHOLD="${1:-5G}"  # Default to 5GB, can override: ./find-large-files.sh 10G

echo "=== Finding files larger than ${THRESHOLD} ==="
echo ""

echo "Disk 1 (/mnt/disk1):"
echo "-------------------"
find /mnt/disk1 -type f -size +${THRESHOLD} -exec ls -lh {} \; 2>/dev/null | \
    awk '{print $5, $9}' | \
    sort -h | \
    tail -20 || echo "No files found or error accessing disk"

echo ""
echo "Disk 2 (/mnt/disk2):"
echo "-------------------"
find /mnt/disk2 -type f -size +${THRESHOLD} -exec ls -lh {} \; 2>/dev/null | \
    awk '{print $5, $9}' | \
    sort -h | \
    tail -20 || echo "No files found or error accessing disk"

echo ""
echo "=== Top 20 directories by size ==="
echo ""
echo "Disk 1:"
du -sh /mnt/disk1/* 2>/dev/null | sort -h | tail -20
echo ""
echo "Disk 2:"
du -sh /mnt/disk2/* 2>/dev/null | sort -h | tail -20
