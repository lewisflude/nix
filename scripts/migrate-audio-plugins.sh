#!/usr/bin/env bash
# Migrate audio plugins (VST, Audio Units, VST3) from one Mac to another
# Usage: ./scripts/migrate-audio-plugins.sh [source_path] [destination_path]

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default paths
SOURCE_MAC="${1:-}"
DEST_MAC="${2:-$HOME}"

# Plugin locations to migrate
declare -a PLUGIN_LOCATIONS=(
    # System-wide plugins
    "/Library/Audio/Plug-Ins/VST"
    "/Library/Audio/Plug-Ins/VST3"
    "/Library/Audio/Plug-Ins/Components"

    # User plugins
    "~/Library/Audio/Plug-Ins/VST"
    "~/Library/Audio/Plug-Ins/VST3"
    "~/Library/Audio/Plug-Ins/Components"
)

# Application Support locations (presets, settings, etc.)
declare -a APP_SUPPORT_LOCATIONS=(
    "~/Library/Application Support/FabFilter"
    "~/Library/Application Support/Toontrack"
    "~/Library/Application Support/Native Instruments"
    "~/Library/Application Support/iZotope"
    "~/Library/Application Support/Waves"
    "~/Library/Application Support/Plugin Alliance"
    "~/Library/Application Support/Universal Audio"
    "~/Library/Application Support/Sonarworks"
    "~/Library/Application Support/Avid"  # Pro Tools
    "~/Library/Application Support/Steinberg"  # Cubase, Nuendo
    "~/Library/Application Support/PreSonus"  # Studio One
)

# Function to expand tilde in paths
expand_path() {
    local path="$1"
    if [[ "${path:0:1}" == "~" ]]; then
        echo "${path/\~/$HOME}"
    else
        echo "$path"
    fi
}

# Function to copy directory
copy_directory() {
    local source="$1"
    local dest="$2"
    local description="$3"
    local use_ssh="${4:-false}"

    local source_expanded
    local dest_expanded=$(expand_path "$dest")

    if [[ "$use_ssh" == "true" ]]; then
        source_expanded="$source"
        # For SSH, we can't check if directory exists easily, so we'll try and let rsync handle it
    else
        source_expanded=$(expand_path "$source")
        if [[ ! -d "${source_expanded}" ]]; then
            echo -e "${YELLOW}⚠ Skipping ${description}: ${source_expanded} does not exist${NC}"
            return 0
        fi
    fi

    # Try to get size (works for local, may not work for SSH)
    local size="unknown"
    if [[ "$use_ssh" != "true" ]]; then
        size=$(du -sh "${source_expanded}" 2>/dev/null | cut -f1 || echo "unknown")
    fi

    echo -e "${BLUE}📥 Copying ${description} (${size})...${NC}"
    echo "   Source: ${source_expanded}"
    echo "   Dest:   ${dest_expanded}"

    # Create destination directory
    mkdir -p "$(dirname "${dest_expanded}")"

    # Copy with rsync for better progress and error handling
    # rsync automatically handles SSH paths
    if rsync -av --progress "${source_expanded}/" "${dest_expanded}/" 2>&1 | grep -v "^$" | head -20; then
        echo -e "${GREEN}✅ Copied ${description}${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to copy ${description}${NC}" >&2
        return 1
    fi
}

# Function to check if running as root (needed for system-wide plugins)
check_root() {
    if [[ $EUID -ne 0 ]] && [[ "$1" == "/Library"* ]]; then
        echo -e "${YELLOW}⚠ Note: System-wide plugins in ${1} require sudo privileges${NC}"
        echo -e "${YELLOW}   You may need to run this script with sudo for system plugins${NC}"
        return 1
    fi
    return 0
}

# Main migration function
migrate_plugins() {
    local source_base="$1"
    local dest_base="$2"
    local use_ssh="${3:-false}"

    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Audio Plugin Migration${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "${BLUE}Source:${NC} ${source_base}"
    echo -e "${BLUE}Destination:${NC} ${dest_base}"
    echo ""

    # Confirm before proceeding
    read -p "$(echo -e ${CYAN}Continue with migration? [y/N]: ${NC})" confirm
    if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Migration cancelled.${NC}"
        exit 0
    fi

    local success_count=0
    local fail_count=0

    # Migrate plugin binaries
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Plugin Binaries${NC}"
    echo -e "${BLUE}========================================${NC}"

    for location in "${PLUGIN_LOCATIONS[@]}"; do
        local source_path
        local dest_path="${dest_base}${location#~/}"

        # Handle SSH vs local paths
        if [[ "$use_ssh" == "true" ]]; then
            # For SSH, construct remote path
            if [[ "$location" == ~/* ]]; then
                # User location: user@host:~/Library/...
                source_path="${source_base}${location#~/}"
            else
                # System location: user@host:/Library/...
                source_path="${source_base}${location}"
            fi
        else
            source_path="${source_base}${location#~/}"
            source_path=$(expand_path "$source_path")
        fi

        dest_path=$(expand_path "$dest_path")

        # Check if we need root for system plugins (skip for SSH)
        if [[ "$location" == "/Library"* ]] && [[ "$use_ssh" != "true" ]]; then
            check_root "$location" || continue
        fi

        if copy_directory "$source_path" "$dest_path" "$(basename "$location") plugins" "$use_ssh"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done

    # Migrate Application Support data
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Plugin Data & Presets${NC}"
    echo -e "${BLUE}========================================${NC}"

    for location in "${APP_SUPPORT_LOCATIONS[@]}"; do
        local source_path
        local dest_path="${dest_base}${location#~/}"

        # Handle SSH vs local paths
        if [[ "$use_ssh" == "true" ]]; then
            source_path="${source_base}${location#~/}"
        else
            source_path="${source_base}${location#~/}"
            source_path=$(expand_path "$source_path")
        fi

        dest_path=$(expand_path "$dest_path")

        if copy_directory "$source_path" "$dest_path" "$(basename "$location") data" "$use_ssh"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
    done

    # Summary
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Migration Summary${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}✅ Successful: ${success_count}${NC}"
    echo -e "${RED}❌ Failed: ${fail_count}${NC}"
    echo ""
    echo -e "${YELLOW}⚠ Important Next Steps:${NC}"
    echo "1. Re-authorize plugins using vendor plugin managers"
    echo "2. Transfer iLok licenses if applicable"
    echo "3. Rescan plugins in your DAW"
    echo "4. Verify all plugins load correctly"
    echo ""
    echo -e "${BLUE}See docs/AUDIO_PLUGIN_MIGRATION.md for detailed instructions${NC}"
}

# Help function
show_help() {
    cat << EOF
Audio Plugin Migration Script

Usage:
    $0 [source_path] [destination_path]

Examples:
    # Migrate from external drive to current user
    $0 /Volumes/External\ Drive /Users/username

    # Migrate from another Mac via network share
    $0 /Volumes/Other\ Mac /Users/username

    # Migrate from another Mac via SSH
    $0 user@hostname.local:/Users/user /Users/username

    # Migrate system plugins (requires sudo)
    sudo $0 /Volumes/External\ Drive /

Options:
    source_path      - Path to source Mac's root or user directory
    destination_path - Path to destination (default: current user home)

Notes:
    - System-wide plugins require sudo privileges
    - Most plugins will need re-activation on the new Mac
    - Large sample libraries may need to be migrated separately

EOF
}

# Main script logic
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    show_help
    exit 0
fi

if [[ -z "$SOURCE_MAC" ]]; then
    echo -e "${RED}Error: Source path required${NC}" >&2
    echo ""
    show_help
    exit 1
fi

# Check if source is SSH path (user@host:path format)
if [[ "$SOURCE_MAC" =~ ^[^/]+@[^:]+: ]]; then
    echo -e "${BLUE}Detected SSH source path${NC}"
    # For SSH sources, we'll use rsync directly with SSH
    SSH_SOURCE=true
else
    SSH_SOURCE=false
    if [[ ! -d "$SOURCE_MAC" ]]; then
        echo -e "${RED}Error: Source path does not exist: ${SOURCE_MAC}${NC}" >&2
        echo ""
        echo -e "${YELLOW}Tip: You can use SSH format: user@host:/path${NC}"
        echo -e "${YELLOW}Example: lewisflude@Lewiss-MacBook-Pro.local:/Users/lewisflude${NC}"
        exit 1
    fi
fi

migrate_plugins "$SOURCE_MAC" "$DEST_MAC" "$SSH_SOURCE"
