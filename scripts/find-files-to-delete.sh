#!/usr/bin/env bash
# Find files that can be safely deleted to free up disk space
# Run with sudo for accurate size reporting

set -euo pipefail

echo "=== Files Safe to Delete ==="
echo ""

# 1. Trash directories (745M + 382M = ~1.1GB)
echo "📁 TRASH DIRECTORIES (~1.1GB total):"
echo "-----------------------------------"
echo "Disk 1 trash:"
sudo du -sh /mnt/disk1/.Trash-1000 2>/dev/null || echo "  Not accessible"
echo ""
echo "Disk 2 trash:"
sudo du -sh /mnt/disk2/.Trash-1000 2>/dev/null || echo "  Not accessible"
echo ""
echo "To delete: sudo rm -rf /mnt/disk1/.Trash-1000/* /mnt/disk2/.Trash-1000/*"
echo ""

# 2. Sample files
echo "🎬 SAMPLE FILES:"
echo "----------------"
SAMPLE_COUNT=$(sudo find /mnt/disk1 /mnt/disk2 -type f \( -name "*.sample" -o -name "*.Sample" -o -iname "*sample*" \) 2>/dev/null | wc -l)
echo "Found $SAMPLE_COUNT sample files"
if [ "$SAMPLE_COUNT" -gt 0 ]; then
    echo "Sample files found:"
    sudo find /mnt/disk1 /mnt/disk2 -type f \( -name "*.sample" -o -name "*.Sample" -o -iname "*sample*" \) 2>/dev/null | head -20
    echo ""
    SAMPLE_SIZE=$(sudo find /mnt/disk1 /mnt/disk2 -type f \( -name "*.sample" -o -name "*.Sample" -o -iname "*sample*" \) -exec du -ch {} + 2>/dev/null | tail -1 | awk '{print $1}')
    echo "Total size: $SAMPLE_SIZE"
fi
echo ""

# 3. Large log files
echo "📋 LARGE LOG FILES (>100MB):"
echo "----------------------------"
sudo find /mnt/disk1 /mnt/disk2 -type f -name "*.log" -size +100M -exec ls -lh {} \; 2>/dev/null | awk '{print $5, $9}' || echo "  None found"
echo ""

# 4. Duplicate files (if rmlint was run)
if [ -f /mnt/disk2/rmlint.json ]; then
    echo "🔄 DUPLICATE FILES (from rmlint.json):"
    echo "--------------------------------------"
    echo "Found rmlint.json on disk2"
    echo "To analyze: sudo rmlint --check /mnt/disk2/rmlint.json"
    echo "Or view JSON: sudo cat /mnt/disk2/rmlint.json | jq"
    echo ""
fi

# 5. Empty directories in torrents
echo "📂 EMPTY TORRENT DIRECTORIES:"
echo "-----------------------------"
EMPTY_COUNT=$(sudo find /mnt/disk1/torrents /mnt/disk2/torrents -type d -empty 2>/dev/null | wc -l)
echo "Found $EMPTY_COUNT empty directories"
if [ "$EMPTY_COUNT" -gt 0 ] && [ "$EMPTY_COUNT" -lt 50 ]; then
    sudo find /mnt/disk1/torrents /mnt/disk2/torrents -type d -empty 2>/dev/null | head -20
fi
echo ""

# 6. Largest individual files
echo "📊 LARGEST FILES (>10GB):"
echo "-------------------------"
echo "Disk 1:"
sudo find /mnt/disk1 -type f -size +10G -exec ls -lh {} \; 2>/dev/null | awk '{print $5, $9}' | head -10 || echo "  None found"
echo ""
echo "Disk 2:"
sudo find /mnt/disk2 -type f -size +10G -exec ls -lh {} \; 2>/dev/null | awk '{print $5, $9}' | head -10 || echo "  None found"
echo ""

# 7. Top directories by size (to identify what to review)
echo "📈 TOP DIRECTORIES BY SIZE:"
echo "---------------------------"
echo "Disk 1 top subdirectories:"
sudo du -sh /mnt/disk1/* 2>/dev/null | sort -h | tail -10
echo ""
echo "Disk 2 top subdirectories:"
sudo du -sh /mnt/disk2/* 2>/dev/null | sort -h | tail -10
echo ""

# 8. Check for potential duplicates between disks
echo "💡 RECOMMENDATIONS:"
echo "-------------------"
echo "1. Empty trash directories: ~1.1GB"
echo "2. Review torrents directories (155GB total) for completed downloads you don't need"
echo "3. Review usenet directories (6.9GB total) for old downloads"
echo "4. Check for duplicate files between disk1 and disk2 media directories"
echo "5. Consider running: sudo rmlint /mnt/disk1 /mnt/disk2"
echo ""
echo "⚠️  CRITICAL: Both disks are at 100% capacity!"
echo "   Free up at least 10-20GB on each disk to prevent write failures"
