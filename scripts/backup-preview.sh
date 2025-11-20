#!/usr/bin/env bash
# Preview what will be backed up to Samsung Drive

set -euo pipefail

BACKUP_ROOT="/Volumes/Samsung Drive"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== Backup Preview ===${NC}"
echo "Target: ${BACKUP_ROOT}"
echo ""

# Check if Samsung Drive is mounted
if [[ ! -d "${BACKUP_ROOT}" ]]; then
    echo -e "${YELLOW}⚠ Samsung Drive is not mounted${NC}"
    exit 1
fi

# Function to show directory info
show_dir() {
    local path="$1"
    local description="$2"

    if [[ -d "${path}" ]]; then
        local size=$(du -sh "${path}" 2>/dev/null | cut -f1)
        local file_count=$(find "${path}" -type f 2>/dev/null | wc -l | tr -d ' ')
        echo -e "${GREEN}✓${NC} ${description}"
        echo "   Path: ${path}"
        echo "   Size: ${size}"
        echo "   Files: ${file_count}"
        echo ""
    else
        echo -e "${YELLOW}⚠${NC} ${description} (not found)"
        echo "   Path: ${path}"
        echo ""
    fi
}

echo -e "${BLUE}--- Music & Audio Production ---${NC}"
show_dir "${HOME}/Music/Ableton" "Ableton Projects"
show_dir "${HOME}/Music/Sample Library" "Sample Library"
show_dir "${HOME}/Music/FastGarage Project" "FastGarage Project"
show_dir "${HOME}/Music/Music" "Music Projects"
show_dir "${HOME}/Desktop/Guitar1 Project" "Guitar1 Project"
show_dir "${HOME}/Documents/ModularPolyGrandJam Project" "ModularPolyGrandJam Project"

echo -e "${BLUE}--- Ableton Application Support ---${NC}"
show_dir "${HOME}/Library/Application Support/Ableton" "Ableton Preferences & Database"

echo -e "${BLUE}--- Max/MSP Projects ---${NC}"
show_dir "${HOME}/Documents/Max 8" "Max 8 Projects"
show_dir "${HOME}/Documents/Max 9" "Max 9 Projects"

echo -e "${BLUE}--- Development & Creative Projects ---${NC}"
show_dir "${HOME}/Code" "Code Projects"
show_dir "${HOME}/Documents/Obsidian" "Obsidian"
show_dir "${HOME}/Documents/Obsidian Vault" "Obsidian Vault"
show_dir "${HOME}/Documents/Unreal Projects" "Unreal Projects"

echo -e "${BLUE}--- Audio Plugin Libraries & Samples ---${NC}"
show_dir "${HOME}/Library/Application Support/Toontrack/Superior3" "Toontrack Superior Drummer 3"
show_dir "${HOME}/Library/Application Support/FabFilter" "FabFilter Plugin Presets"
show_dir "${HOME}/Library/Application Support/Sonarworks" "Sonarworks SoundID Reference"

echo -e "${BLUE}--- Application Data & Workspaces ---${NC}"
show_dir "${HOME}/Library/Application Support/obsidian" "Obsidian Application Support"
show_dir "${HOME}/Library/Application Support/Cursor" "Cursor Workspace Data"

echo -e "${BLUE}--- Security & Configuration ---${NC}"
show_dir "${HOME}/.ssh" "SSH Keys"
show_dir "${HOME}/.gnupg" "GPG Keys"
show_dir "${HOME}/Backups" "Existing Backups"

# Calculate total
echo -e "${BLUE}--- Summary ---${NC}"
TOTAL=0
for dir in \
    "${HOME}/Music/Ableton" \
    "${HOME}/Music/Sample Library" \
    "${HOME}/Music/FastGarage Project" \
    "${HOME}/Music/Music" \
    "${HOME}/Desktop/Guitar1 Project" \
    "${HOME}/Documents/ModularPolyGrandJam Project" \
    "${HOME}/Library/Application Support/Ableton" \
    "${HOME}/Documents/Max 8" \
    "${HOME}/Documents/Max 9" \
    "${HOME}/Code" \
    "${HOME}/Documents/Obsidian" \
    "${HOME}/Documents/Obsidian Vault" \
    "${HOME}/Documents/Unreal Projects" \
    "${HOME}/Library/Application Support/Toontrack/Superior3" \
    "${HOME}/Library/Application Support/FabFilter" \
    "${HOME}/Library/Application Support/Sonarworks" \
    "${HOME}/Library/Application Support/obsidian" \
    "${HOME}/Library/Application Support/Cursor" \
    "${HOME}/.ssh" \
    "${HOME}/.gnupg" \
    "${HOME}/Backups"; do
    if [[ -d "${dir}" ]]; then
        SIZE=$(du -sm "${dir}" 2>/dev/null | cut -f1)
        TOTAL=$((TOTAL + SIZE))
    fi
done

TOTAL_GB=$(echo "scale=2; ${TOTAL}/1024" | bc)
echo "Total size: ${TOTAL_GB} GB (${TOTAL} MB)"
echo ""

# Check available space
AVAILABLE=$(df -m "${BACKUP_ROOT}" | tail -1 | awk '{print $4}')
AVAILABLE_GB=$(echo "scale=2; ${AVAILABLE}/1024" | bc)
echo "Available space on Samsung Drive: ${AVAILABLE_GB} GB (${AVAILABLE} MB)"

if [[ ${TOTAL} -lt ${AVAILABLE} ]]; then
    echo -e "${GREEN}✓ Sufficient space available${NC}"
else
    echo -e "${YELLOW}⚠ Warning: May not have enough space${NC}"
fi
