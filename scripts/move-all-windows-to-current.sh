#!/usr/bin/env bash
# Move all windows from all workspaces to the current workspace on DP-3

set -euo pipefail

# Get current workspace info
current_ws=$(niri msg --json workspaces | jq -r '.[] | select(.is_focused == true) | .idx')
current_output=$(niri msg --json workspaces | jq -r '.[] | select(.is_focused == true) | .output')

echo "Current workspace: $current_ws on $current_output"

# First, ensure the current workspace is on DP-3
if [ "$current_output" != "DP-3" ]; then
    echo "Moving current workspace to DP-3..."
    niri msg action focus-monitor-left || niri msg action focus-monitor-right
    # Move workspace to DP-3 (left monitor)
    niri msg action move-workspace-to-monitor-left
    echo "Workspace moved to DP-3"
fi

# Get all windows from all workspaces
windows=$(niri msg --json windows)

# Count total windows
total_windows=$(echo "$windows" | jq 'length')
echo "Found $total_windows windows to move"

if [ "$total_windows" -eq 0 ]; then
    echo "No windows to move"
    exit 0
fi

# For each window, focus it and move its column to the current workspace
echo "$windows" | jq -r '.[] | "\(.id) \(.workspace_idx // "none")"' | while read -r window_id workspace_idx; do
    # Skip windows already on the current workspace
    if [ "$workspace_idx" = "$current_ws" ]; then
        echo "Window $window_id already on workspace $current_ws, skipping"
        continue
    fi

    echo "Moving window $window_id from workspace $workspace_idx to workspace $current_ws..."

    # Focus the window
    niri msg action focus-window --id "$window_id" 2>/dev/null || {
        echo "Warning: Could not focus window $window_id, skipping"
        continue
    }

    # Move the column to the target workspace
    niri msg action move-column-to-workspace "$current_ws" 2>/dev/null || {
        echo "Warning: Could not move window $window_id, skipping"
        continue
    }
done

echo "All windows moved to workspace $current_ws on DP-3"

# Return focus to the current workspace
niri msg action focus-workspace "$current_ws"
