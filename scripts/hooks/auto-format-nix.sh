#!/usr/bin/env bash
# Post-edit formatting hook for Nix files
#
# Claude Code Documentation:
# - PostToolUse hooks run after Write/Edit operations
# - This hook automatically formats Nix files
# - Exit code 0: success (shows output to Claude)
# - Exit code 1: warning (shows error but doesn't fail)

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only format .nix files
if [[ "$FILE_PATH" != *.nix ]]; then
  exit 0
fi

# Check if file exists (may have been deleted)
if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

echo "🎨 Auto-formatting: $FILE_PATH"

# Try treefmt first (recommended formatter)
if command -v treefmt &> /dev/null; then
  if treefmt "$FILE_PATH" 2>&1; then
    echo "✅ Formatted with treefmt"
    exit 0
  fi
fi

# Fallback to nixfmt if treefmt unavailable
if command -v nixfmt &> /dev/null; then
  if nixfmt "$FILE_PATH" 2>&1; then
    echo "✅ Formatted with nixfmt"
    exit 0
  fi
fi

# Fallback to nix fmt
if nix fmt -- "$FILE_PATH" 2>&1; then
  echo "✅ Formatted with nix fmt"
  exit 0
fi

echo "⚠️  No formatter available (install treefmt or nixfmt)"
exit 1
