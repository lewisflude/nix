#!/usr/bin/env bash
# Simple cleanup: Delete files from torrents/usenet that are already in media/
# Uses a simpler approach: if content exists in media/, delete from downloads

set -euo pipefail

MEDIA_PATH="/mnt/storage/media"
TORRENTS_PATH="/mnt/storage/torrents"
USENET_PATH="/mnt/storage/usenet"

echo "=== Cleanup Unused Downloads (Simple) ==="
echo ""
echo "Strategy: Delete entire directories from torrents/usenet if the"
echo "          same content exists in media/ directories"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run with sudo"
    exit 1
fi

FILES_TO_DELETE=()
DIRS_TO_DELETE=()
TOTAL_SIZE=0

echo "Step 1: Finding directories in torrents/ that match media/ content..."
cd "$TORRENTS_PATH" 2>/dev/null || exit 1

# For each top-level directory in torrents
for torrent_dir in */; do
    [ -d "$torrent_dir" ] || continue

    dir_name=$(basename "$torrent_dir")

    # Skip special directories
    case "$dir_name" in
        incomplete|.Trash*|cleanuperr-*|lidarr|music|books|other|pc|movies|tv|xxx)
            # Check if movies/tv/xxx have content in media
            if [ "$dir_name" = "movies" ] || [ "$dir_name" = "tv" ] || [ "$dir_name" = "xxx" ]; then
                # These are category directories - check subdirectories
                echo "  Checking category: $dir_name"
                for subdir in "$torrent_dir"*/; do
                    [ -d "$subdir" ] || continue
                    subdir_name=$(basename "$subdir")

                    # Check if this content exists in media
                    if [ "$dir_name" = "movies" ]; then
                        if find "$MEDIA_PATH/movies" -type d -iname "*${subdir_name}*" 2>/dev/null | grep -q .; then
                            echo "    Found duplicate: $subdir"
                            size=$(du -sb "$subdir" 2>/dev/null | cut -f1)
                            DIRS_TO_DELETE+=("$subdir")
                            TOTAL_SIZE=$((TOTAL_SIZE + size))
                        fi
                    elif [ "$dir_name" = "tv" ]; then
                        if find "$MEDIA_PATH/tv" -type d -iname "*${subdir_name}*" 2>/dev/null | grep -q .; then
                            echo "    Found duplicate: $subdir"
                            size=$(du -sb "$subdir" 2>/dev/null | cut -f1)
                            DIRS_TO_DELETE+=("$subdir")
                            TOTAL_SIZE=$((TOTAL_SIZE + size))
                        fi
                    fi
                done
            fi
            continue
            ;;
    esac

    # For other directories, check if content exists in media
    # Extract a clean name for matching
    clean_name=$(echo "$dir_name" | sed 's/\[.*\]//g' | sed 's/\.[0-9]\{4\}.*$//' | sed 's/\.S[0-9].*$//' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')

    if [ -n "$clean_name" ] && [ ${#clean_name} -gt 3 ]; then
        # Check if this exists in media
        if find "$MEDIA_PATH" -type d -iname "*${clean_name}*" 2>/dev/null | grep -q .; then
            echo "  Found duplicate directory: $dir_name"
            size=$(du -sb "$torrent_dir" 2>/dev/null | cut -f1)
            DIRS_TO_DELETE+=("$torrent_dir")
            TOTAL_SIZE=$((TOTAL_SIZE + size))
        fi
    fi
done

# Calculate size
SIZE_HR=$(numfmt --to=iec-i --suffix=B $TOTAL_SIZE 2>/dev/null || echo "$((TOTAL_SIZE / 1024 / 1024 / 1024))GB")

echo ""
echo "=== Summary ==="
echo "Found ${#DIRS_TO_DELETE[@]} directories to delete"
echo "Total size: $SIZE_HR"
echo ""

if [ ${#DIRS_TO_DELETE[@]} -eq 0 ]; then
    echo "No duplicate directories found!"
    exit 0
fi

# Show preview
echo "Directories to delete:"
for dir in "${DIRS_TO_DELETE[@]}"; do
    echo "  - $dir"
done
echo ""

# Confirm
read -p "Delete these directories? (yes/no): " -r
echo ""
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Delete
DELETED_COUNT=0
DELETED_SIZE=0

echo "Deleting directories..."
for dir in "${DIRS_TO_DELETE[@]}"; do
    if [ -d "$dir" ]; then
        size=$(du -sb "$dir" 2>/dev/null | cut -f1 || echo 0)
        rm -rf "$dir" && DELETED_COUNT=$((DELETED_COUNT + 1)) && DELETED_SIZE=$((DELETED_SIZE + size))
        echo "  Deleted: $dir"
    fi
done

DELETED_SIZE_HR=$(numfmt --to=iec-i --suffix=B $DELETED_SIZE 2>/dev/null || echo "$((DELETED_SIZE / 1024 / 1024 / 1024))GB")

echo ""
echo "✓ Cleanup complete!"
echo "  Deleted: $DELETED_COUNT directories"
echo "  Freed: $DELETED_SIZE_HR"
echo ""
echo "=== Remaining Disk Space ==="
df -h /mnt/disk1 /mnt/disk2 | tail -2
