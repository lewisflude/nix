#!/usr/bin/env bash
# Restore important files from Samsung Drive backup to a new host
# This is the inverse of backup-to-samsung-drive.sh

set -euo pipefail

BACKUP_ROOT="/Volumes/Samsung Drive"
BACKUP_DIR="${BACKUP_ROOT}/Backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if Samsung Drive is mounted
if [[ ! -d "${BACKUP_ROOT}" ]]; then
    echo -e "${RED}Error: Samsung Drive is not mounted at ${BACKUP_ROOT}${NC}" >&2
    exit 1
fi

# Function to list available backups
list_backups() {
    echo -e "${BLUE}Available backups:${NC}"
    if [[ -d "${BACKUP_DIR}" ]]; then
        local count=0
        for backup in "${BACKUP_DIR}"/*; do
            if [[ -d "${backup}" ]]; then
                ((count++))
                local hostname=$(basename "${backup}")
                local size=$(du -sh "${backup}" 2>/dev/null | cut -f1)
                echo -e "  ${GREEN}${count}.${NC} ${CYAN}${hostname}${NC} (${size})"
            fi
        done
        if [[ ${count} -eq 0 ]]; then
            echo -e "${YELLOW}  No backups found${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}  No backups directory found${NC}"
        return 1
    fi
    return 0
}

# Prompt for backup selection
select_backup() {
    list_backups
    echo ""
    read -p "$(echo -e ${CYAN}Select backup to restore from [hostname]: ${NC})" selected_hostname

    if [[ -z "${selected_hostname}" ]]; then
        echo -e "${RED}Error: No hostname provided${NC}" >&2
        exit 1
    fi

    SOURCE_BACKUP="${BACKUP_DIR}/${selected_hostname}"

    if [[ ! -d "${SOURCE_BACKUP}" ]]; then
        echo -e "${RED}Error: Backup not found: ${SOURCE_BACKUP}${NC}" >&2
        exit 1
    fi

    echo -e "${GREEN}Selected backup: ${CYAN}${selected_hostname}${NC}"
    echo ""
}

# Confirm restoration
confirm_restore() {
    echo -e "${YELLOW}⚠ WARNING: This will restore files from backup to your current system.${NC}"
    echo -e "${YELLOW}Existing files may be overwritten.${NC}"
    echo ""
    read -p "$(echo -e ${CYAN}Continue? [y/N]: ${NC})" confirm
    if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Restore cancelled.${NC}"
        exit 0
    fi
}

# Function to restore a directory
restore_dir() {
    local source="$1"
    local dest="$2"
    local description="$3"

    if [[ ! -d "${source}" ]]; then
        echo -e "${YELLOW}⚠ Skipping ${description}: ${source} does not exist in backup${NC}"
        return 0
    fi

    local size=$(du -sh "${source}" 2>/dev/null | cut -f1)
    echo -e "${BLUE}📥 Restoring ${description} (${size})...${NC}"
    echo "   Source: ${source}"
    echo "   Dest:   ${dest}"

    # Create destination directory if it doesn't exist
    mkdir -p "$(dirname "${dest}")"

    # Use rsync with progress and preserve attributes
    if rsync -avh --progress "${source}/" "${dest}/" 2>&1; then
        echo -e "${GREEN}✓ Completed: ${description}${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed: ${description}${NC}"
        return 1
    fi
}

# Track restore results
SUCCESS_COUNT=0
FAIL_COUNT=0

# Main restore process
main() {
    echo -e "${BLUE}=== Restore from Samsung Drive ===${NC}"
    echo ""

    # Select backup
    select_backup

    # Confirm
    confirm_restore

    echo ""
    echo -e "${BLUE}=== Starting Restore ===${NC}"
    echo "Source: ${SOURCE_BACKUP}"
    echo "Destination: ${HOME}"
    echo ""

    # ============================================================================
    # MUSIC & AUDIO PRODUCTION FILES
    # ============================================================================
    echo -e "${BLUE}--- Music & Audio Production ---${NC}"

    if restore_dir \
        "${SOURCE_BACKUP}/Music/Ableton" \
        "${HOME}/Music/Ableton" \
        "Ableton Projects"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    if restore_dir \
        "${SOURCE_BACKUP}/Music/Sample Library" \
        "${HOME}/Music/Sample Library" \
        "Sample Library"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    if restore_dir \
        "${SOURCE_BACKUP}/Music/FastGarage Project" \
        "${HOME}/Music/FastGarage Project" \
        "FastGarage Project"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    if restore_dir \
        "${SOURCE_BACKUP}/Music/Music" \
        "${HOME}/Music/Music" \
        "Music Projects"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    if restore_dir \
        "${SOURCE_BACKUP}/Music/Guitar1 Project" \
        "${HOME}/Desktop/Guitar1 Project" \
        "Guitar1 Project"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    if restore_dir \
        "${SOURCE_BACKUP}/Music/ModularPolyGrandJam Project" \
        "${HOME}/Documents/ModularPolyGrandJam Project" \
        "ModularPolyGrandJam Project"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    # ============================================================================
    # ABLETON APPLICATION SUPPORT
    # ============================================================================
    echo ""
    echo -e "${BLUE}--- Ableton Application Support ---${NC}"

    if restore_dir \
        "${SOURCE_BACKUP}/Library/Application Support/Ableton" \
        "${HOME}/Library/Application Support/Ableton" \
        "Ableton Application Support"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    # ============================================================================
    # MAX/MSP PROJECTS
    # ============================================================================
    echo ""
    echo -e "${BLUE}--- Max/MSP Projects ---${NC}"

    if restore_dir \
        "${SOURCE_BACKUP}/Documents/Max 8" \
        "${HOME}/Documents/Max 8" \
        "Max 8 Projects"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    if restore_dir \
        "${SOURCE_BACKUP}/Documents/Max 9" \
        "${HOME}/Documents/Max 9" \
        "Max 9 Projects"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    # ============================================================================
    # DEVELOPMENT & CREATIVE PROJECTS
    # ============================================================================
    echo ""
    echo -e "${BLUE}--- Development & Creative Projects ---${NC}"

    if restore_dir \
        "${SOURCE_BACKUP}/Code" \
        "${HOME}/Code" \
        "Code Projects"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    if restore_dir \
        "${SOURCE_BACKUP}/Documents/Obsidian" \
        "${HOME}/Documents/Obsidian" \
        "Obsidian"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    if restore_dir \
        "${SOURCE_BACKUP}/Documents/Obsidian Vault" \
        "${HOME}/Documents/Obsidian Vault" \
        "Obsidian Vault"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    if restore_dir \
        "${SOURCE_BACKUP}/Documents/Unreal Projects" \
        "${HOME}/Documents/Unreal Projects" \
        "Unreal Projects"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    # ============================================================================
    # AUDIO PLUGIN LIBRARIES & SAMPLES
    # ============================================================================
    echo ""
    echo -e "${BLUE}--- Audio Plugin Libraries & Samples ---${NC}"

    if restore_dir \
        "${SOURCE_BACKUP}/Library/Application Support/Toontrack/Superior3" \
        "${HOME}/Library/Application Support/Toontrack/Superior3" \
        "Toontrack Superior Drummer 3"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    if restore_dir \
        "${SOURCE_BACKUP}/Library/Application Support/FabFilter" \
        "${HOME}/Library/Application Support/FabFilter" \
        "FabFilter Plugin Presets"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    if restore_dir \
        "${SOURCE_BACKUP}/Library/Application Support/Sonarworks" \
        "${HOME}/Library/Application Support/Sonarworks" \
        "Sonarworks SoundID Reference"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    # ============================================================================
    # APPLICATION DATA & WORKSPACES
    # ============================================================================
    echo ""
    echo -e "${BLUE}--- Application Data & Workspaces ---${NC}"

    if restore_dir \
        "${SOURCE_BACKUP}/Library/Application Support/obsidian" \
        "${HOME}/Library/Application Support/obsidian" \
        "Obsidian Application Support"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    if restore_dir \
        "${SOURCE_BACKUP}/Library/Application Support/Cursor" \
        "${HOME}/Library/Application Support/Cursor" \
        "Cursor Workspace Data"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    # ============================================================================
    # SECURITY & CONFIGURATION
    # ============================================================================
    echo ""
    echo -e "${BLUE}--- Security & Configuration ---${NC}"

    if restore_dir \
        "${SOURCE_BACKUP}/.ssh" \
        "${HOME}/.ssh" \
        "SSH Keys"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    if restore_dir \
        "${SOURCE_BACKUP}/.gnupg" \
        "${HOME}/.gnupg" \
        "GPG Keys"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    if restore_dir \
        "${SOURCE_BACKUP}/Backups" \
        "${HOME}/Backups" \
        "Existing Backups"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi

    # ============================================================================
    # SUMMARY
    # ============================================================================
    echo ""
    echo -e "${BLUE}=== Restore Summary ===${NC}"
    echo -e "Successful restores: ${GREEN}${SUCCESS_COUNT}${NC}"
    if [[ ${FAIL_COUNT} -gt 0 ]]; then
        echo -e "Failed restores: ${RED}${FAIL_COUNT}${NC}"
    fi

    if [[ ${FAIL_COUNT} -eq 0 ]]; then
        echo -e "${GREEN}✓ All restores completed successfully!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some restores failed.${NC}"
        exit 1
    fi
}

# Run main function
main
