#!/usr/bin/env bash
# Sunshine prep-cmd "do" script
# Enables HDMI-A-4 output and moves current workspace to it for streaming

set -euo pipefail

# Log to journalctl for debugging
log() {
    echo "[sunshine-prep] $*" | systemd-cat -t sunshine-prep -p info
}

log "Starting Sunshine stream preparation"

# Enable HDMI-A-4 output
log "Enabling HDMI-A-4 output"
niri msg output HDMI-A-4 on

# Small delay to ensure output is fully initialized
# This prevents race conditions with Sunshine's display detection
sleep 0.5

# Get current workspace and move it to HDMI-A-4 (right monitor)
current_ws=$(niri msg --json workspaces | jq -r '.[] | select(.is_focused == true) | .idx')
log "Moving workspace $current_ws to HDMI-A-4"
niri msg action move-workspace-to-monitor-right

# Additional small delay to ensure workspace is settled
sleep 0.3

log "Preparation complete - workspace $current_ws is now on HDMI-A-4"
