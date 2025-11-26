#!/usr/bin/env bash
# Claude Code Status Line Script
# Displays session information at the bottom of Claude Code
#
# Installation:
#   1. Copy to ~/.claude/statusline.sh
#   2. Make executable: chmod +x ~/.claude/statusline.sh
#   3. Add to settings.json:
#      "statusLine": {
#        "type": "command",
#        "command": "~/.claude/statusline.sh",
#        "padding": 0
#      }

set -euo pipefail

# Read session data from stdin (JSON from Claude Code)
status=$(cat)

# Extract information using jq
model=$(echo "$status" | jq -r '.model.displayName // "Unknown"')
dir=$(echo "$status" | jq -r '.directory.current // pwd' | xargs basename)
cost=$(echo "$status" | jq -r '.usage.totalCostUsd // 0')
lines_added=$(echo "$status" | jq -r '.usage.changedLines.added // 0')
lines_removed=$(echo "$status" | jq -r '.usage.changedLines.removed // 0')

# Get git branch if in git repo
if git rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git branch --show-current 2>/dev/null || echo "detached")
  git_info="$branch"
else
  git_info="no-git"
fi

# Format cost with 2 decimal places
cost_formatted=$(printf "%.2f" "$cost")

# Build status line
# Format: [model] dir:branch | +lines/-lines | $cost
echo "[$model] $dir:$git_info | +$lines_added/-$lines_removed | \$$cost_formatted"
