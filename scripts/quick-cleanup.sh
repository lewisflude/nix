#!/usr/bin/env bash
# Quick cleanup script - removes safe-to-delete files
# SAFE operations only - trash and empty directories

set -euo pipefail

echo "=== Quick Cleanup Script ==="
echo ""
echo "This will delete:"
echo "  1. Trash directories (~1.1GB)"
echo "  2. Empty directories in torrents (minimal space)"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Deleting trash directories..."
sudo rm -rf /mnt/disk1/.Trash-1000/files/* /mnt/disk1/.Trash-1000/info/*
sudo rm -rf /mnt/disk2/.Trash-1000/files/* /mnt/disk2/.Trash-1000/info/*
echo "✓ Trash cleared"

echo ""
echo "Removing empty directories in torrents..."
sudo find /mnt/disk1/torrents /mnt/disk2/torrents -type d -empty -delete 2>/dev/null || true
echo "✓ Empty directories removed"

echo ""
echo "=== Space freed ==="
df -h /mnt/disk1 /mnt/disk2 | tail -2
