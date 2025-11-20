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
    # System-wide plugins (standard locations)
    "/Library/Audio/Plug-Ins/VST"
    "/Library/Audio/Plug-Ins/VST3"
    "/Library/Audio/Plug-Ins/Components"
    "/Library/Application Support/Avid/Audio/Plug-Ins"  # AAX plugins (Pro Tools)

    # Additional system locations (less common)
    "/usr/local/lib/vst"
    "/usr/local/lib/vst3"
    "/opt/local/lib/vst"
    "/opt/local/lib/vst3"

    # User plugins (standard locations)
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

# Function to construct source path for user plugins
# Handles cases where source_base might be a volume root
construct_user_source_path() {
    local source_base="$1"
    local user_location="$2"  # e.g., ~/Library/...
    local use_ssh="$3"

    if [[ "$use_ssh" == "true" ]]; then
        # For SSH, just append the path
        echo "${source_base}${user_location#~/}"
    else
        # For local paths, check if source_base looks like a volume root
        # If it ends with a volume name (no /Users/...), try to find the user
        if [[ "$source_base" =~ ^/Volumes/ ]] && [[ ! "$source_base" =~ /Users/ ]]; then
            # Try to find the first user directory
            local users_dir="${source_base}/Users"
            if [[ -d "$users_dir" ]]; then
                # Find the first non-shared user directory (skip Shared, .localized, etc.)
                local user_dir=$(find "$users_dir" -maxdepth 1 -type d -not -name "Shared" -not -name ".*" -not -name "Users" | head -1)
                if [[ -n "$user_dir" ]]; then
                    echo "${user_dir}${user_location#~/}"
                else
                    # Fallback: try current username
                    echo "${source_base}/Users/${USER}${user_location#~/}"
                fi
            else
                # No Users directory, try current username
                echo "${source_base}/Users/${USER}${user_location#~/}"
            fi
        else
            # Source base already includes user path or is root
            echo "${source_base}${user_location#~/}"
        fi
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
    # Use a temporary file to capture output and check exit code properly
    local temp_output=$(mktemp)
    local rsync_exit=0

    # Run rsync with options:
    # -a: archive mode (preserves permissions, timestamps, etc.)
    # -v: verbose
    # --progress: show progress
    # --partial: keep partially transferred files (allows resuming)
    # --partial-dir: store partial files in a hidden directory
    # --human-readable: show sizes in human-readable format
    if rsync -av --progress --partial --partial-dir=".rsync-partial" "${source_expanded}/" "${dest_expanded}/" > "$temp_output" 2>&1; then
        rsync_exit=0
    else
        rsync_exit=$?
    fi

    # Show output (filter empty lines and limit to last 30 lines for readability)
    grep -v "^$" "$temp_output" | tail -30

    # Clean up temp file
    rm -f "$temp_output"

    # Check exit code
    if [[ $rsync_exit -eq 0 ]]; then
        echo -e "${GREEN}✅ Copied ${description}${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to copy ${description} (exit code: ${rsync_exit})${NC}" >&2
        case $rsync_exit in
            1)
                echo -e "${YELLOW}   Error: Syntax or usage error${NC}" >&2
                ;;
            2)
                echo -e "${YELLOW}   Error: Protocol incompatibility${NC}" >&2
                ;;
            3)
                echo -e "${YELLOW}   Error: File selection errors (e.g., file not found)${NC}" >&2
                ;;
            4)
                echo -e "${YELLOW}   Error: Requested action not supported${NC}" >&2
                ;;
            5)
                echo -e "${YELLOW}   Error: Error starting client-server protocol${NC}" >&2
                ;;
            10)
                echo -e "${YELLOW}   Error: Socket I/O error${NC}" >&2
                ;;
            11)
                echo -e "${YELLOW}   Error: File I/O error (check disk space and permissions)${NC}" >&2
                ;;
            12)
                echo -e "${YELLOW}   Error: rsync protocol data stream error${NC}" >&2
                ;;
            13)
                echo -e "${YELLOW}   Error: Diagnostics error${NC}" >&2
                ;;
            14)
                echo -e "${YELLOW}   Error: IPC (code) error${NC}" >&2
                ;;
            20)
                echo -e "${YELLOW}   Error: Received SIGUSR1 or SIGINT${NC}" >&2
                ;;
            21)
                echo -e "${YELLOW}   Error: Waitpid() error${NC}" >&2
                ;;
            22)
                echo -e "${YELLOW}   Error: Alloc core memory error${NC}" >&2
                ;;
            23)
                echo -e "${YELLOW}   Error: Partial transfer due to error${NC}" >&2
                echo -e "${YELLOW}   Some files may have been copied. You can re-run to resume.${NC}" >&2
                ;;
            24)
                echo -e "${YELLOW}   Error: Partial transfer due to vanished source files${NC}" >&2
                ;;
            25)
                echo -e "${YELLOW}   Error: File system limits exceeded${NC}" >&2
                ;;
            30)
                echo -e "${YELLOW}   Error: Timeout in data send/receive${NC}" >&2
                ;;
            35)
                echo -e "${YELLOW}   Error: Timeout waiting for daemon connection${NC}" >&2
                ;;
            *)
                echo -e "${YELLOW}   Check the output above for specific error messages${NC}" >&2
                ;;
        esac
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

    # Detect and show user directory if source is a volume root
    if [[ "$use_ssh" != "true" ]] && [[ "$source_base" =~ ^/Volumes/ ]] && [[ ! "$source_base" =~ /Users/ ]]; then
        local users_dir="${source_base}/Users"
        if [[ -d "$users_dir" ]]; then
            local user_dir=$(find "$users_dir" -maxdepth 1 -type d -not -name "Shared" -not -name ".*" -not -name "Users" 2>/dev/null | head -1)
            if [[ -n "$user_dir" ]]; then
                echo -e "${CYAN}Detected user directory: ${user_dir}${NC}"
            fi
        fi
    fi
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
            # For local paths, handle user vs system locations
            if [[ "$location" == ~/* ]]; then
                # User location - use helper to find correct user path
                source_path=$(construct_user_source_path "$source_base" "$location" "$use_ssh")
            else
                # System location
                source_path="${source_base}${location}"
            fi
            source_path=$(expand_path "$source_path")
        fi

        dest_path=$(expand_path "$dest_path")

        # Check if we need root for system plugins
        # Skip root check for: SSH, AAX plugins, /usr/local, /opt (usually user-writable)
        if [[ "$location" == "/Library"* ]] && \
           [[ "$location" != "/Library/Application Support"* ]] && \
           [[ "$location" != "/usr/local"* ]] && \
           [[ "$location" != "/opt"* ]] && \
           [[ "$use_ssh" != "true" ]]; then
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
            # Use helper to find correct user path for Application Support
            source_path=$(construct_user_source_path "$source_base" "$location" "$use_ssh")
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
    - System-wide plugins in /Library/ require sudo privileges
    - Plugins in /usr/local/ and /opt/ are usually user-writable (no sudo needed)
    - Most plugins will need re-activation on the new Mac
    - Large sample libraries may need to be migrated separately
    - Custom plugin locations not in the standard paths will be skipped

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
