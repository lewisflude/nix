#!/usr/bin/env bash
# Session-end validation hook
#
# Claude Code Documentation:
# - SessionEnd hooks run when Claude session is stopping
# - Can use agent-based hooks for complex validation
# - This script prepares validation context for the agent
#
# This hook performs comprehensive dendritic pattern validation
# across all modified files in the session

set -euo pipefail

echo "🔍 Performing comprehensive dendritic pattern validation..."

# Get list of modified .nix files in modules/
MODIFIED_FILES=$(git diff --name-only --cached 2>/dev/null | grep -E '^modules/.*\.nix$' || true)

if [[ -z $MODIFIED_FILES ]]; then
  echo "✅ No Nix modules modified in this session"
  exit 0
fi

echo "📝 Modified modules:"
echo "$MODIFIED_FILES" | sed 's/^/   - /'
echo ""

# Check for common anti-patterns across all files
VIOLATIONS=()

while IFS= read -r file; do
  if [[ ! -f $file ]]; then
    continue
  fi

  CONTENT=$(cat "$file")

  # Check each anti-pattern
  if echo "$CONTENT" | grep -q "with pkgs;"; then
    VIOLATIONS+=("$file: contains 'with pkgs;'")
  fi

  if echo "$CONTENT" | grep -qE "(special|extra)Args"; then
    VIOLATIONS+=("$file: contains specialArgs/extraSpecialArgs")
  fi

  if echo "$CONTENT" | grep -qE "import.*(lib/constants|constants\.nix)"; then
    VIOLATIONS+=("$file: imports constants directly")
  fi
done <<<"$MODIFIED_FILES"

# Report violations
if [ ${#VIOLATIONS[@]} -gt 0 ]; then
  echo "⚠️  Dendritic pattern violations detected:"
  printf "   - %s\n" "${VIOLATIONS[@]}"
  echo ""
  echo "💡 Consider reviewing these files before committing"
  echo "   Run: /feature-validator to validate modules"
else
  echo "✅ All modified modules follow dendritic pattern"
fi

exit 0
