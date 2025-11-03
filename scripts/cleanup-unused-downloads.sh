#!/usr/bin/env bash
# Cleanup unused downloads from torrents/usenet directories
# Only deletes files that are already imported to media directories

set -euo pipefail

MEDIA_PATH="/mnt/storage/media"
TORRENTS_PATH="/mnt/storage/torrents"
USENET_PATH="/mnt/storage/usenet"

# Sonarr/Radarr API endpoints
SONARR_API="http://localhost:8989/api/v3"
RADARR_API="http://localhost:7878/api/v3"
SONARR_API_KEY="0c5c62e42dc6405dacd6354fa3290be9"
RADARR_API_KEY="b8210df4bda545ddbca19feecfc9c7a0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Cleanup Unused Downloads ==="
echo ""
echo "This script will:"
echo "  1. Find files in torrents/usenet directories"
echo "  2. Check if they exist in media directories (already imported)"
echo "  3. Verify they're not actively downloading"
echo "  4. Delete files that are safely duplicated in media/"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run with sudo${NC}"
    exit 1
fi

# Function to check if a file path is tracked by Sonarr
is_tracked_by_sonarr() {
    local file_path="$1"
    # Query Sonarr for all series and check file paths
    curl -s -H "X-Api-Key: $SONARR_API_KEY" "${SONARR_API}/episodeFile" 2>/dev/null | \
        grep -q "\"path\".*$(basename "$file_path")" && return 0
    return 1
}

# Function to check if a file path is tracked by Radarr
is_tracked_by_radarr() {
    local file_path="$1"
    # Query Radarr for all movies and check file paths
    curl -s -H "X-Api-Key: $RADARR_API_KEY" "${RADARR_API}/movieFile" 2>/dev/null | \
        grep -q "\"path\".*$(basename "$file_path")" && return 0
    return 1
}

# Function to normalize paths for comparison
normalize_path() {
    local path="$1"
    # Remove /mnt/storage prefix and convert to relative
    echo "$path" | sed 's|^/mnt/storage/||' | sed 's|^/mnt/disk[12]/||'
}

# Function to get filename without path
get_basename() {
    basename "$1"
}

# Function to check if file exists in media directory
file_exists_in_media() {
    local file_path="$1"
    local filename=$(get_basename "$file_path")

    # Exact filename match in movies
    if find "$MEDIA_PATH/movies" -name "$filename" -type f 2>/dev/null | grep -q .; then
        return 0
    fi

    # Exact filename match in TV shows
    if find "$MEDIA_PATH/tv" -name "$filename" -type f 2>/dev/null | grep -q .; then
        return 0
    fi

    # Extract show/movie name and episode info for better matching
    # Pattern: Show.Name.S01E01 or Movie.Name.2024
    local name_pattern=$(echo "$filename" | sed -E 's/\.(S[0-9]+E[0-9]+|mkv|mp4|avi|m4v|mov).*$//' | sed 's/\.[0-9]\{4\}.*$//' | sed 's/\[.*\]//g' | sed 's/\.[0-9]\+p.*$//' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')

    if [ -n "$name_pattern" ] && [ ${#name_pattern} -gt 5 ]; then
        # Check if any file in media contains this pattern
        if find "$MEDIA_PATH" -type f -iname "*${name_pattern}*" 2>/dev/null | grep -q .; then
            return 0
        fi
    fi

    # Check by directory name match (often shows are in season folders)
    local dir_name=$(dirname "$file_path")
    dir_name=$(basename "$dir_name")
    local clean_dir=$(echo "$dir_name" | sed 's/\[.*\]//g' | sed 's/\.[0-9]\{4\}.*$//' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')

    if [ -n "$clean_dir" ] && [ ${#clean_dir} -gt 5 ]; then
        if find "$MEDIA_PATH" -type d -iname "*${clean_dir}*" 2>/dev/null | grep -q .; then
            # If directory matches, check if any media file exists in that directory
            matched_dir=$(find "$MEDIA_PATH" -type d -iname "*${clean_dir}*" 2>/dev/null | head -1)
            if [ -n "$matched_dir" ] && find "$matched_dir" -type f \( -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" -o -name "*.m4v" \) 2>/dev/null | grep -q .; then
                return 0
            fi
        fi
    fi

    return 1
}

# Function to check if directory contains media files
has_media_files() {
    local dir="$1"
    find "$dir" -type f \( -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" -o -name "*.m4v" \) 2>/dev/null | head -1 | grep -q .
}

# Collect files to delete
FILES_TO_DELETE=()
DIRS_TO_DELETE=()
TOTAL_SIZE=0

echo "Scanning torrents directory..."
while IFS= read -r -d '' file; do
    # Skip if it's a directory
    [ -d "$file" ] && continue

    # Only process media files
    case "$file" in
        *.mkv|*.mp4|*.avi|*.m4v|*.mov)
            # Check if file exists in media directory (already imported)
            if file_exists_in_media "$file"; then
                # Double-check it's not actively tracked in download location
                # (if Sonarr/Radarr still reference it in torrents/, don't delete)
                if ! is_tracked_by_sonarr "$file" && ! is_tracked_by_radarr "$file"; then
                    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
                    FILES_TO_DELETE+=("$file")
                    TOTAL_SIZE=$((TOTAL_SIZE + size))
                fi
            fi
            ;;
    esac
done < <(find "$TORRENTS_PATH" -type f -print0 2>/dev/null)

echo "Scanning usenet directory..."
while IFS= read -r -d '' file; do
    [ -d "$file" ] && continue

    case "$file" in
        *.mkv|*.mp4|*.avi|*.m4v|*.mov)
            # Check if file exists in media directory (already imported)
            if file_exists_in_media "$file"; then
                # Double-check it's not actively tracked
                if ! is_tracked_by_sonarr "$file" && ! is_tracked_by_radarr "$file"; then
                    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
                    FILES_TO_DELETE+=("$file")
                    TOTAL_SIZE=$((TOTAL_SIZE + size))
                fi
            fi
            ;;
    esac
done < <(find "$USENET_PATH" -type f -print0 2>/dev/null)

# Check for empty directories or directories with no media files
echo "Checking for empty directories..."
while IFS= read -r -d '' dir; do
    # Skip if directory is in use (has non-media files that might be needed)
    if ! has_media_files "$dir"; then
        # Check if it's truly empty or only has metadata files
        has_important_files=false
        for item in "$dir"/*; do
            [ -e "$item" ] || continue
            case "$(basename "$item")" in
                *.torrent|*.nfo|*.txt|*.log|*.jpg|*.png|*.srt|*.sub)
                    continue
                    ;;
                *)
                    has_important_files=true
                    break
                    ;;
            esac
        done

        if [ "$has_important_files" = false ]; then
            DIRS_TO_DELETE+=("$dir")
        fi
    fi
done < <(find "$TORRENTS_PATH" "$USENET_PATH" -type d -print0 2>/dev/null)

# Calculate size in human readable format
SIZE_HR=$(numfmt --to=iec-i --suffix=B $TOTAL_SIZE 2>/dev/null || echo "$((TOTAL_SIZE / 1024 / 1024 / 1024))GB")

echo ""
echo "=== Files to Delete ==="
echo "Found ${#FILES_TO_DELETE[@]} files already in media directory"
echo "Total size: $SIZE_HR"
echo ""
echo "Found ${#DIRS_TO_DELETE[@]} empty/unused directories"
echo ""

if [ ${#FILES_TO_DELETE[@]} -eq 0 ] && [ ${#DIRS_TO_DELETE[@]} -eq 0 ]; then
    echo -e "${GREEN}No unused files found to delete!${NC}"
    exit 0
fi

# Show preview
if [ ${#FILES_TO_DELETE[@]} -gt 0 ]; then
    echo "Sample files to delete (first 20):"
    for file in "${FILES_TO_DELETE[@]:0:20}"; do
        echo "  - $file"
    done
    if [ ${#FILES_TO_DELETE[@]} -gt 20 ]; then
        echo "  ... and $(( ${#FILES_TO_DELETE[@]} - 20 )) more files"
    fi
    echo ""
fi

# Confirm deletion
read -p "Delete these files? (yes/no): " -r
echo ""
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Delete files
DELETED_COUNT=0
DELETED_SIZE=0

echo "Deleting files..."
for file in "${FILES_TO_DELETE[@]}"; do
    if [ -f "$file" ]; then
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
        rm -f "$file" && DELETED_COUNT=$((DELETED_COUNT + 1)) && DELETED_SIZE=$((DELETED_SIZE + size))
    fi
done

# Delete empty directories (only if truly empty)
echo "Removing empty directories..."
for dir in "${DIRS_TO_DELETE[@]}"; do
    if [ -d "$dir" ] && [ -z "$(find "$dir" -mindepth 1 2>/dev/null)" ]; then
        rmdir "$dir" 2>/dev/null && echo "  Removed: $dir"
    fi
done

DELETED_SIZE_HR=$(numfmt --to=iec-i --suffix=B $DELETED_SIZE 2>/dev/null || echo "$((DELETED_SIZE / 1024 / 1024 / 1024))GB")

echo ""
echo -e "${GREEN}✓ Cleanup complete!${NC}"
echo "  Deleted: $DELETED_COUNT files"
echo "  Freed: $DELETED_SIZE_HR"
echo ""
echo "=== Remaining Disk Space ==="
df -h /mnt/disk1 /mnt/disk2 | tail -2
