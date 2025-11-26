#!/usr/bin/env bash
# Auto-format Nix files after Write/Edit operations
# Uses nixfmt-rfc-style as configured in the flake

set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Only process .nix files
[[ "$file_path" != *.nix ]] && exit 0

# Verify file exists
[[ ! -f "$file_path" ]] && exit 0

# Change to project directory if set (for Claude Code hooks)
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  cd "$CLAUDE_PROJECT_DIR" || exit 0
fi

# Try to format with nixfmt (nixfmt-rfc-style)
if command -v nixfmt &> /dev/null; then
  if nixfmt "$file_path" 2>/dev/null; then
    # Output to stdout (shown in verbose mode)
    echo "✓ Formatted: $file_path"
    exit 0
  else
    # Format failed - show error to Claude
    cat << EOF >&2
⚠️  Failed to format $file_path

The file may have syntax errors. Please fix the Nix syntax.
You can manually check with: nixfmt $file_path
EOF
    exit 2
  fi
else
  # nixfmt not available - warn but don't block
  echo "⚠️  nixfmt not found - run 'nix develop' to enable formatting" >&2
  exit 0
fi
