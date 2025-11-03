#!/usr/bin/env bash
# Practical cleanup: Delete files/directories from torrents/usenet that match media/

set -euo pipefail

MEDIA_PATH="/mnt/storage/media"
TORRENTS_PATH="/mnt/storage/torrents"
USENET_PATH="/mnt/storage/usenet"

echo "=== Cleanup Unused Downloads ==="
echo ""

if [ "$EUID" -ne 0 ]; then
    echo "Error: Run with sudo"
    exit 1
fi

ITEMS_TO_DELETE=()
TOTAL_SIZE=0

# Function to clean a name for matching
clean_name() {
    echo "$1" | \
        sed 's/\[.*\]//g' | \
        sed 's/(.*)//g' | \
        sed 's/\.[0-9]\{4\}.*$//' | \
        sed 's/\.S[0-9].*$//' | \
        sed 's/\.E[0-9].*$//' | \
        sed 's/[0-9]\{3,4\}p.*$//' | \
        sed 's/\.WEB.*$//' | \
        sed 's/\.BluRay.*$//' | \
        sed 's/\.DVD.*$//' | \
        sed 's/\.x264.*$//' | \
        sed 's/\.x265.*$//' | \
        sed 's/\.h264.*$//' | \
        sed 's/\.h265.*$//' | \
        sed 's/\.HEVC.*$//' | \
        sed 's/\.H264.*$//' | \
        tr '[:upper:]' '[:lower:]' | \
        sed 's/[^a-z0-9]//g' | \
        sed 's/^the//' | \
        sed 's/^a//'
}

# Function to check if content exists in media
exists_in_media() {
    local item_path="$1"
    local item_name=$(basename "$item_path")
    local clean_item=$(clean_name "$item_name")

    if [ ${#clean_item} -lt 5 ]; then
        return 1
    fi

    # Check movies
    for media_dir in "$MEDIA_PATH/movies"/*/; do
        [ -d "$media_dir" ] || continue
        local media_name=$(basename "$media_dir")
        local clean_media=$(clean_name "$media_name")

        if [ "$clean_item" = "$clean_media" ] || [[ "$clean_media" == *"$clean_item"* ]] || [[ "$clean_item" == *"$clean_media"* ]]; then
            return 0
        fi
    done

    # Check TV
    for media_dir in "$MEDIA_PATH/tv"/*/; do
        [ -d "$media_dir" ] || continue
        local media_name=$(basename "$media_dir")
        local clean_media=$(clean_name "$media_name")

        if [ "$clean_item" = "$clean_media" ] || [[ "$clean_media" == *"$clean_item"* ]] || [[ "$clean_item" == *"$clean_media"* ]]; then
            return 0
        fi
    done

    return 1
}

echo "Scanning torrents/tv..."
cd "$TORRENTS_PATH/tv" 2>/dev/null || true
for item in *; do
    [ -e "$item" ] || continue
    item_path="$TORRENTS_PATH/tv/$item"

    if exists_in_media "$item_path"; then
        echo "  MATCH: $item"
        size=$(du -sb "$item_path" 2>/dev/null | cut -f1 || echo 0)
        ITEMS_TO_DELETE+=("$item_path")
        TOTAL_SIZE=$((TOTAL_SIZE + size))
    fi
done

echo "Scanning torrents/movies..."
cd "$TORRENTS_PATH/movies" 2>/dev/null || true
for item in *; do
    [ -e "$item" ] || continue
    item_path="$TORRENTS_PATH/movies/$item"

    if exists_in_media "$item_path"; then
        echo "  MATCH: $item"
        size=$(du -sb "$item_path" 2>/dev/null | cut -f1 || echo 0)
        ITEMS_TO_DELETE+=("$item_path")
        TOTAL_SIZE=$((TOTAL_SIZE + size))
    fi
done

echo "Scanning usenet..."
cd "$USENET_PATH" 2>/dev/null || true
for item in *; do
    [ -e "$item" ] || continue
    [ "$item" = "complete" ] && continue
    [ "$item" = "incomplete" ] && continue

    item_path="$USENET_PATH/$item"

    if exists_in_media "$item_path"; then
        echo "  MATCH: $item"
        size=$(du -sb "$item_path" 2>/dev/null | cut -f1 || echo 0)
        ITEMS_TO_DELETE+=("$item_path")
        TOTAL_SIZE=$((TOTAL_SIZE + size))
    fi
done

SIZE_HR=$(numfmt --to=iec-i --suffix=B $TOTAL_SIZE 2>/dev/null || echo "$((TOTAL_SIZE / 1024 / 1024 / 1024))GB")

echo ""
echo "=== Summary ==="
echo "Found ${#ITEMS_TO_DELETE[@]} items to delete"
echo "Total size: $SIZE_HR"
echo ""

if [ ${#ITEMS_TO_DELETE[@]} -eq 0 ]; then
    echo "No matches found!"
    exit 0
fi

echo "Items to delete:"
for item in "${ITEMS_TO_DELETE[@]}"; do
    echo "  - $item"
done
echo ""

read -p "Delete these items? (yes/no): " -r
echo ""
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Aborted."
    exit 0
fi

DELETED_COUNT=0
DELETED_SIZE=0

echo "Deleting..."
for item in "${ITEMS_TO_DELETE[@]}"; do
    if [ -e "$item" ]; then
        size=$(du -sb "$item" 2>/dev/null | cut -f1 || echo 0)
        rm -rf "$item" && DELETED_COUNT=$((DELETED_COUNT + 1)) && DELETED_SIZE=$((DELETED_SIZE + size))
        echo "  Deleted: $item"
    fi
done

DELETED_SIZE_HR=$(numfmt --to=iec-i --suffix=B $DELETED_SIZE 2>/dev/null || echo "$((DELETED_SIZE / 1024 / 1024 / 1024))GB")

echo ""
echo "✓ Deleted: $DELETED_COUNT items"
echo "✓ Freed: $DELETED_SIZE_HR"
echo ""
df -h /mnt/disk1 /mnt/disk2 | tail -2
