#!/usr/bin/env bash
set -euo pipefail

# Enhanced Nix Store Cleanup Script
# Removes old/unused package versions, debug packages, and duplicates
# Run with: sudo bash scripts/cleanup-duplicates.sh

# Detect non-interactive mode
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"
if [ -t 0 ]; then
    NON_INTERACTIVE="false"
else
    NON_INTERACTIVE="true"
fi

# Auto-detect current system
if [ -L /run/current-system ]; then
    CURRENT_SYSTEM=$(readlink -f /run/current-system)
else
    CURRENT_SYSTEM=$(find /nix/store -maxdepth 1 -name "*-nixos-system-*" -type l 2>/dev/null | head -1 || echo "")
    if [ -z "$CURRENT_SYSTEM" ]; then
        echo "Error: Could not determine current system."
        exit 1
    fi
fi

echo "=== Enhanced Nix Store Cleanup Script ==="
echo ""
echo "Current system: $CURRENT_SYSTEM"
echo ""

# Function to check if a path is referenced
is_referenced() {
    local path="$1"
    nix-store -qR "$CURRENT_SYSTEM" 2>/dev/null | grep -q "^$path$" && return 0
    for profile in /nix/var/nix/profiles/per-user/*/*; do
        [ -L "$profile" ] || continue
        nix-store -qR "$(readlink -f "$profile")" 2>/dev/null | grep -q "^$path$" && return 0
    done
    return 1
}

PATHS_TO_DELETE=()

# ... (keep existing cleanup code) ...

# NEW: Remove debug packages
echo "=== Analyzing debug packages ==="
for path in /nix/store/*debug*; do
    [ -e "$path" ] || continue
    if ! is_referenced "$path"; then
        PATHS_TO_DELETE+=("$path")
        echo "  Will delete: $(basename $path)"
    fi
done

# NEW: Remove duplicate CUDA libraries
echo "=== Analyzing CUDA libraries ==="
CUDA_LIBS=$(du -sh /nix/store/*libcublas* 2>/dev/null | sort -rh | head -3)
if [ -n "$CUDA_LIBS" ]; then
    # Keep only the first one (usually latest), delete exact duplicates
    KEEP_LIB=$(echo "$CUDA_LIBS" | head -1 | awk '{print $2}')
    for path in /nix/store/*libcublas*; do
        [ -e "$path" ] || continue
        [ "$path" = "$KEEP_LIB" ] && continue
        if ! is_referenced "$path"; then
            PATHS_TO_DELETE+=("$path")
            echo "  Will delete: $(basename $path)"
        fi
    done
fi

# ... (rest of existing cleanup code) ...
