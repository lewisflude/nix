#!/usr/bin/env bash
# Load minimal project context at session start
# Shows git status, recent commits, and basic flake info

set -euo pipefail

# Change to project directory if set (for Claude Code hooks)
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  cd "$CLAUDE_PROJECT_DIR" || exit 0
else
  # For manual testing, use current directory
  cd "$(dirname "$(dirname "$(readlink -f "$0")")")" 2>/dev/null || exit 0
fi

# Output context as plain text (will be added to Claude's context)
cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Nix Configuration Context
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current Branch: $(git branch --show-current 2>/dev/null || echo "unknown")

Recent Commits:
$(git log -3 --oneline --decorate 2>/dev/null || echo "No git history available")

Working Tree Status:
$(git status --short 2>/dev/null | head -10 || echo "No changes")

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

exit 0
