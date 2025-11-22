#!/usr/bin/env bash
# Preserve important Nix context before Claude Code compacts the conversation
# Used by PreCompact hook

set -euo pipefail

# Change to project directory if set
if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  cd "$CLAUDE_PROJECT_DIR" || exit 0
fi

# Output critical context that should be preserved
cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔒 Preserving Critical Context
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CRITICAL RULES (DO NOT FORGET):
1. NEVER run system rebuild commands: nh os switch, sudo nixos-rebuild switch
2. NEVER use 'with pkgs;' - always use explicit pkgs.packageName
3. System services → modules/nixos/ or modules/darwin/
4. User apps/dotfiles → home/common/apps/
5. Always format with 'nix fmt' or 'treefmt'
6. Use constants from lib/constants.nix

Current Work Context:
Branch: $(git branch --show-current 2>/dev/null || echo "unknown")

Recent Changes:
$(git status --short 2>/dev/null | head -5 || echo "No changes")

Active Modules Being Edited:
$(git status --short 2>/dev/null | grep '\.nix$' | head -3 || echo "None")

Documentation References:
- CLAUDE.md - Module placement guidelines
- CONVENTIONS.md - Coding standards
- docs/FEATURES.md - Feature system
- docs/reference/architecture.md - Architecture

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

exit 0
