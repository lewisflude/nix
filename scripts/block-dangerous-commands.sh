#!/usr/bin/env bash
# Block dangerous commands per CLAUDE.md and user preferences
# Blocks: system rebuilds, destructive file ops, git force ops, production access

set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Exit if no command (shouldn't happen, but be safe)
[[ -z "$command" ]] && exit 0

# Production hostname patterns (regex format)
# Matches: prod, production, *-prod, prod-*, *-production, production-*
check_production_host() {
  local cmd="$1"

  # Simple patterns
  [[ "$cmd" =~ (ssh|scp|rsync)[[:space:]].*prod ]] && return 0
  [[ "$cmd" =~ (ssh|scp|rsync)[[:space:]].*production ]] && return 0

  return 1
}

# Check for system rebuild commands (CLAUDE.md requirement)
if [[ "$command" =~ (nh[[:space:]]+os[[:space:]]+switch|nh[[:space:]]+os[[:space:]]+boot) ]] ||
   [[ "$command" =~ (nixos-rebuild[[:space:]]+switch|nixos-rebuild[[:space:]]+boot) ]] ||
   [[ "$command" =~ (darwin-rebuild[[:space:]]+switch|darwin-rebuild[[:space:]]+activate) ]]; then
  cat << EOF >&2
❌ System rebuild commands are blocked per CLAUDE.md guidelines.

Please run this command manually:
  $command

Reason: System rebuilds require elevated privileges and should be
reviewed by the user before execution.
EOF
  exit 2
fi

# Check for destructive file operations
if [[ "$command" =~ rm[[:space:]]+-([a-zA-Z]*r[a-zA-Z]*f|[a-zA-Z]*f[a-zA-Z]*r)[[:space:]] ]] ||
   [[ "$command" =~ rm[[:space:]]+-rf[[:space:]]*/[^[:space:]]* ]] ||
   [[ "$command" =~ mv[[:space:]].*[[:space:]]/dev/null ]]; then
  cat << EOF >&2
❌ Potentially destructive file operation blocked.

Command: $command

Please review and run manually if this is intentional.
EOF
  exit 2
fi

# Check for git force operations
if [[ "$command" =~ git[[:space:]]+push[[:space:]].*--force ]] ||
   [[ "$command" =~ git[[:space:]]+push[[:space:]].*-f[[:space:]] ]] ||
   [[ "$command" =~ git[[:space:]]+reset[[:space:]]+--hard ]]; then
  cat << EOF >&2
❌ Git force operation blocked.

Command: $command

This could cause loss of git history. Please run manually if needed.
EOF
  exit 2
fi

# Check for production host access
if check_production_host "$command"; then
  cat << EOF >&2
❌ Production host access blocked.

Command: $command

Production hosts should be accessed manually with appropriate review.
Blocked patterns: prod*, production*, *-prod, *-production
EOF
  exit 2
fi

# All checks passed
exit 0
