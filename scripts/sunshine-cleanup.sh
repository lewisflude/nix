#!/usr/bin/env bash
# Sunshine prep-cmd "undo" script
# Moves all windows back to DP-3 and disables HDMI-A-4 after streaming ends

set -euo pipefail

# Log to journalctl for debugging
log() {
    echo "[sunshine-cleanup] $*" | systemd-cat -t sunshine-cleanup -p info
}

log "Starting Sunshine stream cleanup"

# Get all windows from HDMI-A-4 workspace
# We need to move the workspace back to DP-3 first
log "Moving workspace from HDMI-A-4 back to DP-3"
niri msg action move-workspace-to-monitor-left

# Small delay to ensure workspace movement completes
sleep 0.3

# Disable HDMI-A-4 output
log "Disabling HDMI-A-4 output"
niri msg output HDMI-A-4 off

log "Cleanup complete - all windows back on DP-3, HDMI-A-4 disabled"
