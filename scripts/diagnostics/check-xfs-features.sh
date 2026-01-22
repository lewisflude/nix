#!/usr/bin/env bash
#
# XFS Feature Diagnostic Script
#
# This script checks XFS filesystems for modern features and suggests upgrades.
# Modern features include: bigtime, inobtcount, reflink, rmapbt
#
# Usage: ./check-xfs-features.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== XFS Feature Diagnostic ===${NC}\n"

# Find all mounted XFS filesystems
XFS_MOUNTS=$(findmnt -t xfs -n -o TARGET | sort)

if [ -z "$XFS_MOUNTS" ]; then
    echo -e "${YELLOW}No XFS filesystems found.${NC}"
    exit 0
fi

echo -e "Found XFS filesystems:\n"

for MOUNT in $XFS_MOUNTS; do
    echo -e "${GREEN}Checking: $MOUNT${NC}"
    
    # Get filesystem info
    xfs_info "$MOUNT" | head -n 20
    
    # Check for modern features
    echo -e "\n${BLUE}Feature Status:${NC}"
    
    # bigtime (Year 2038+ support)
    if xfs_info "$MOUNT" | grep -q "bigtime=1"; then
        echo -e "  ${GREEN}✓${NC} bigtime enabled (Year 2486 timestamp support)"
    else
        echo -e "  ${YELLOW}✗${NC} bigtime disabled (limited to Year 2038)"
        echo -e "    ${YELLOW}→${NC} Upgrade with: xfs_admin -O bigtime=1 <device> (requires unmount)"
    fi
    
    # inobtcount (improved inode btree)
    if xfs_info "$MOUNT" | grep -q "inobtcount=1"; then
        echo -e "  ${GREEN}✓${NC} inobtcount enabled (faster mount times)"
    else
        echo -e "  ${YELLOW}✗${NC} inobtcount disabled"
        echo -e "    ${YELLOW}→${NC} Upgrade with: xfs_admin -O inobtcount=1 <device> (requires unmount)"
    fi
    
    # reflink (CoW and deduplication)
    if xfs_info "$MOUNT" | grep -q "reflink=1"; then
        echo -e "  ${GREEN}✓${NC} reflink enabled (CoW copies and deduplication)"
    else
        echo -e "  ${YELLOW}✗${NC} reflink disabled (no deduplication support)"
        echo -e "    ${YELLOW}→${NC} Cannot upgrade on existing filesystem - mkfs only"
    fi
    
    # rmapbt (reverse mapping for better recovery)
    if xfs_info "$MOUNT" | grep -q "rmapbt=1"; then
        echo -e "  ${GREEN}✓${NC} rmapbt enabled (better filesystem repair)"
    else
        echo -e "  ${YELLOW}✗${NC} rmapbt disabled"
        echo -e "    ${YELLOW}→${NC} Cannot upgrade on existing filesystem - mkfs only"
    fi
    
    # crc (metadata checksumming)
    if xfs_info "$MOUNT" | grep -q "crc=1"; then
        echo -e "  ${GREEN}✓${NC} crc enabled (metadata checksumming)"
    else
        echo -e "  ${RED}✗${NC} crc disabled (no metadata protection)"
        echo -e "    ${RED}→${NC} Cannot upgrade on existing filesystem - mkfs only"
    fi
    
    # finobt (free inode btree)
    if xfs_info "$MOUNT" | grep -q "finobt=1"; then
        echo -e "  ${GREEN}✓${NC} finobt enabled (faster inode allocation)"
    else
        echo -e "  ${YELLOW}✗${NC} finobt disabled"
        echo -e "    ${YELLOW}→${NC} Cannot upgrade on existing filesystem - mkfs only"
    fi
    
    echo ""
    
    # Get device name
    DEVICE=$(findmnt -n -o SOURCE "$MOUNT")
    echo -e "${BLUE}Device:${NC} $DEVICE"
    
    # Show fragmentation if possible
    echo -e "\n${BLUE}Fragmentation Check:${NC}"
    if command -v xfs_db >/dev/null 2>&1; then
        sudo xfs_db -c frag -r "$DEVICE" 2>/dev/null || echo "  Unable to check fragmentation (may need root)"
    else
        echo "  xfs_db not available"
    fi
    
    echo -e "\n${BLUE}Current Mount Options:${NC}"
    findmnt -n -o OPTIONS "$MOUNT"
    
    echo -e "\n---\n"
done

echo -e "${BLUE}=== Upgrade Instructions ===${NC}\n"
echo "To upgrade features that support online upgrade (bigtime, inobtcount):"
echo "  1. Unmount the filesystem: sudo umount /mnt/diskX"
echo "  2. Run upgrade: sudo xfs_admin -O bigtime=1,inobtcount=1 /dev/disk/by-id/..."
echo "  3. Remount: sudo mount /mnt/diskX"
echo ""
echo "Features that require mkfs (crc, finobt, reflink, rmapbt) cannot be upgraded."
echo "These require backing up data and recreating the filesystem."
echo ""
echo -e "${YELLOW}Note: Always backup data before performing filesystem upgrades!${NC}"
