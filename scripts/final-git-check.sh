#!/usr/bin/env bash
# Final git check before session ends
# Used by Claude Code SessionEnd hook

set -euo pipefail

# Change to project directory if set
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  cd "$CLAUDE_PROJECT_DIR" || exit 0
fi

# Output final session summary
cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Session Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current Branch: $(git branch --show-current 2>/dev/null || echo "unknown")

Working Tree Status:
$(git status --short 2>/dev/null || echo "No changes")

Recent Activity:
$(git log -3 --oneline --decorate 2>/dev/null || echo "No recent commits")

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Session complete - review changes above
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

exit 0
