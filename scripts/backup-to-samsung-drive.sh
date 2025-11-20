#!/usr/bin/env bash
# Backup important files to Samsung Drive
# Excludes files already backed up via iCloud (photos, most documents)

set -euo pipefail

BACKUP_ROOT="/Volumes/Samsung Drive"
BACKUP_DIR="${BACKUP_ROOT}/Backups/$(hostname)"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Samsung Drive is mounted
if [[ ! -d "${BACKUP_ROOT}" ]]; then
    echo -e "${RED}Error: Samsung Drive is not mounted at ${BACKUP_ROOT}${NC}" >&2
    exit 1
fi

# Create backup directory structure
mkdir -p "${BACKUP_DIR}"

# Logging function
log() {
    echo -e "$1" | tee -a "${LOG_FILE}"
}

log "${BLUE}=== Starting Backup to Samsung Drive ===${NC}"
log "Backup directory: ${BACKUP_DIR}"
log "Timestamp: ${TIMESTAMP}"
log ""

# Function to backup a directory
backup_dir() {
    local source="$1"
    local dest="$2"
    local description="$3"

    if [[ ! -d "${source}" ]]; then
        log "${YELLOW}⚠ Skipping ${description}: ${source} does not exist${NC}"
        return 0
    fi

    local size=$(du -sh "${source}" 2>/dev/null | cut -f1)
    log "${BLUE}📦 Backing up ${description} (${size})...${NC}"
    log "   Source: ${source}"
    log "   Dest:   ${dest}"

    # Create destination directory if it doesn't exist
    mkdir -p "${dest}"

    # Use rsync with progress and preserve attributes
    if rsync -avh --progress --delete "${source}/" "${dest}/" >> "${LOG_FILE}" 2>&1; then
        log "${GREEN}✓ Completed: ${description}${NC}"
        return 0
    else
        log "${RED}✗ Failed: ${description}${NC}"
        # Show last few lines of error from log
        log "${YELLOW}Error details:${NC}"
        tail -10 "${LOG_FILE}" | grep -E "(rsync|error|failed)" | tail -5 | while IFS= read -r line; do
            log "   ${line}"
        done
        return 1
    fi
}

# Track backup results
SUCCESS_COUNT=0
FAIL_COUNT=0

# ============================================================================
# MUSIC & AUDIO PRODUCTION FILES
# ============================================================================
log "${BLUE}--- Music & Audio Production ---${NC}"

# Ableton Projects (MOST IMPORTANT - 41GB)
if backup_dir \
    "${HOME}/Music/Ableton" \
    "${BACKUP_DIR}/Music/Ableton" \
    "Ableton Projects"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# Sample Library
if backup_dir \
    "${HOME}/Music/Sample Library" \
    "${BACKUP_DIR}/Music/Sample Library" \
    "Sample Library"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# FastGarage Project
if backup_dir \
    "${HOME}/Music/FastGarage Project" \
    "${BACKUP_DIR}/Music/FastGarage Project" \
    "FastGarage Project"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# Music folder (other projects)
if backup_dir \
    "${HOME}/Music/Music" \
    "${BACKUP_DIR}/Music/Music" \
    "Music Projects"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# Guitar1 Project (on Desktop)
if backup_dir \
    "${HOME}/Desktop/Guitar1 Project" \
    "${BACKUP_DIR}/Music/Guitar1 Project" \
    "Guitar1 Project"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# ModularPolyGrandJam Project (in Documents)
if backup_dir \
    "${HOME}/Documents/ModularPolyGrandJam Project" \
    "${BACKUP_DIR}/Music/ModularPolyGrandJam Project" \
    "ModularPolyGrandJam Project"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# ============================================================================
# ABLETON APPLICATION SUPPORT (Preferences, Database, etc.)
# ============================================================================
log ""
log "${BLUE}--- Ableton Application Support ---${NC}"

if backup_dir \
    "${HOME}/Library/Application Support/Ableton" \
    "${BACKUP_DIR}/Library/Application Support/Ableton" \
    "Ableton Application Support (Preferences & Database)"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# ============================================================================
# MAX/MSP PROJECTS
# ============================================================================
log ""
log "${BLUE}--- Max/MSP Projects ---${NC}"

if backup_dir \
    "${HOME}/Documents/Max 8" \
    "${BACKUP_DIR}/Documents/Max 8" \
    "Max 8 Projects"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

if backup_dir \
    "${HOME}/Documents/Max 9" \
    "${BACKUP_DIR}/Documents/Max 9" \
    "Max 9 Projects"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# ============================================================================
# DEVELOPMENT & CREATIVE PROJECTS
# ============================================================================
log ""
log "${BLUE}--- Development & Creative Projects ---${NC}"

# Code Projects (IMPORTANT - 54GB)
if backup_dir \
    "${HOME}/Code" \
    "${BACKUP_DIR}/Code" \
    "Code Projects"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# Obsidian Vaults (if not fully synced to iCloud)
if backup_dir \
    "${HOME}/Documents/Obsidian" \
    "${BACKUP_DIR}/Documents/Obsidian" \
    "Obsidian"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

if backup_dir \
    "${HOME}/Documents/Obsidian Vault" \
    "${BACKUP_DIR}/Documents/Obsidian Vault" \
    "Obsidian Vault"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# Unreal Projects
if backup_dir \
    "${HOME}/Documents/Unreal Projects" \
    "${BACKUP_DIR}/Documents/Unreal Projects" \
    "Unreal Projects"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# ============================================================================
# AUDIO PLUGIN LIBRARIES & SAMPLES
# ============================================================================
log ""
log "${BLUE}--- Audio Plugin Libraries & Samples ---${NC}"

# Toontrack Superior Drummer 3 (VERY IMPORTANT - 224GB)
if backup_dir \
    "${HOME}/Library/Application Support/Toontrack/Superior3" \
    "${BACKUP_DIR}/Library/Application Support/Toontrack/Superior3" \
    "Toontrack Superior Drummer 3 (Samples & Presets)"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# FabFilter Plugin Presets
if backup_dir \
    "${HOME}/Library/Application Support/FabFilter" \
    "${BACKUP_DIR}/Library/Application Support/FabFilter" \
    "FabFilter Plugin Presets"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# Sonarworks SoundID Reference
if backup_dir \
    "${HOME}/Library/Application Support/Sonarworks" \
    "${BACKUP_DIR}/Library/Application Support/Sonarworks" \
    "Sonarworks SoundID Reference"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# ============================================================================
# APPLICATION DATA & WORKSPACES
# ============================================================================
log ""
log "${BLUE}--- Application Data & Workspaces ---${NC}"

# Obsidian Application Support
if backup_dir \
    "${HOME}/Library/Application Support/obsidian" \
    "${BACKUP_DIR}/Library/Application Support/obsidian" \
    "Obsidian Application Support"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# Cursor Workspace Data (optional - might be synced)
if backup_dir \
    "${HOME}/Library/Application Support/Cursor" \
    "${BACKUP_DIR}/Library/Application Support/Cursor" \
    "Cursor Workspace Data"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# ============================================================================
# SECURITY & CONFIGURATION
# ============================================================================
log ""
log "${BLUE}--- Security & Configuration ---${NC}"

# SSH Keys
if backup_dir \
    "${HOME}/.ssh" \
    "${BACKUP_DIR}/.ssh" \
    "SSH Keys"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# GPG Keys
if backup_dir \
    "${HOME}/.gnupg" \
    "${BACKUP_DIR}/.gnupg" \
    "GPG Keys"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# Existing Backups (nix-config backup)
if backup_dir \
    "${HOME}/Backups" \
    "${BACKUP_DIR}/Backups" \
    "Existing Backups"; then
    ((SUCCESS_COUNT++))
else
    ((FAIL_COUNT++))
fi

# ============================================================================
# SUMMARY
# ============================================================================
log ""
log "${BLUE}=== Backup Summary ===${NC}"
log "Successful backups: ${GREEN}${SUCCESS_COUNT}${NC}"
if [[ ${FAIL_COUNT} -gt 0 ]]; then
    log "Failed backups: ${RED}${FAIL_COUNT}${NC}"
fi

# Calculate total backup size
TOTAL_SIZE=$(du -sh "${BACKUP_DIR}" 2>/dev/null | cut -f1)
log "Total backup size: ${GREEN}${TOTAL_SIZE}${NC}"
log ""
log "Log file: ${LOG_FILE}"

if [[ ${FAIL_COUNT} -eq 0 ]]; then
    log "${GREEN}✓ All backups completed successfully!${NC}"
    exit 0
else
    log "${RED}✗ Some backups failed. Check the log file for details.${NC}"
    exit 1
fi
