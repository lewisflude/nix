#!/usr/bin/env bash
# Post-edit linting hook for Nix files
#
# Claude Code Documentation:
# - PostToolUse hooks run after Write/Edit operations
# - This hook runs linters to detect issues
# - Exit code 0: success (shows output to Claude)
# - Exit code 1: warning (shows error but doesn't fail)
#
# This hook detects issues but does NOT block (exit 0 always)
# Claude sees the output and can self-correct

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only lint .nix files
if [[ $FILE_PATH != *.nix ]]; then
  exit 0
fi

# Check if file exists
if [[ ! -f $FILE_PATH ]]; then
  exit 0
fi

echo "🔍 Linting: $FILE_PATH"

ISSUES=()

# Check 1: statix (Nix linter)
if command -v statix &>/dev/null; then
  STATIX_OUTPUT=$(statix check "$FILE_PATH" 2>&1 || true)
  if [[ -n $STATIX_OUTPUT ]]; then
    ISSUES+=("$STATIX_OUTPUT")
  fi
fi

# Check 2: deadnix (dead code detection)
if command -v deadnix &>/dev/null; then
  DEADNIX_OUTPUT=$(deadnix "$FILE_PATH" 2>&1 || true)
  if [[ -n $DEADNIX_OUTPUT ]]; then
    ISSUES+=("Dead code detected:")
    ISSUES+=("$DEADNIX_OUTPUT")
  fi
fi

# Check 3: nix flake check (if modifying flake inputs)
if [[ $FILE_PATH == */flake.nix ]] || [[ $FILE_PATH == */flake.lock ]]; then
  echo "🧪 Running nix flake check..."
  FLAKE_CHECK_OUTPUT=$(nix flake check --no-build 2>&1 || true)
  if [[ -n $FLAKE_CHECK_OUTPUT ]]; then
    ISSUES+=("Flake check issues:")
    ISSUES+=("$FLAKE_CHECK_OUTPUT")
  fi
fi

# Report issues
if [ ${#ISSUES[@]} -gt 0 ]; then
  echo "⚠️  Linting issues found:"
  printf "%s\n" "${ISSUES[@]}"
  echo ""
  echo "💡 Claude: Please review and fix these issues"
else
  echo "✅ No linting issues found"
fi

# Always exit 0 so Claude sees output but isn't blocked
exit 0
