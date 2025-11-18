#!/usr/bin/env bash
# Shared helper functions for Claude Code hooks
# Source this file in hook scripts: source "$(dirname "$0")/hook-helpers.sh"

# Parse JSON input from stdin
# Usage: parse_hook_input
# Sets: $HOOK_INPUT (full JSON), $TOOL_NAME, $FILE_PATH, $COMMAND
parse_hook_input() {
  HOOK_INPUT=$(cat)
  TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty')
  FILE_PATH=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // empty')
  COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // empty')
  export HOOK_INPUT TOOL_NAME FILE_PATH COMMAND
}

# Change to project directory, handling both Claude Code and manual testing
# Usage: cd_to_project
cd_to_project() {
  if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
    cd "$CLAUDE_PROJECT_DIR" || return 1
  else
    # For manual testing, use script's parent directory
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cd "$(dirname "$script_dir")" 2>/dev/null || return 1
  fi
}

# Check if file is a Nix file
# Usage: is_nix_file "$file_path"
is_nix_file() {
  [[ "$1" == *.nix ]]
}

# Show formatted error message to Claude (stderr, exit 2)
# Usage: block_with_error "title" "message" ["suggestion"]
block_with_error() {
  local title="$1"
  local message="$2"
  local suggestion="${3:-}"

  {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ $title"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "$message"
    if [[ -n "$suggestion" ]]; then
      echo ""
      echo "$suggestion"
    fi
    echo ""
  } >&2

  exit 2
}

# Show warning message (stderr, exit 0 - non-blocking)
# Usage: warn "message"
warn() {
  echo "⚠️  $1" >&2
}

# Show success message (stdout)
# Usage: success "message"
success() {
  echo "✓ $1"
}
