#!/usr/bin/env bash
# Strict linting with statix and deadnix - blocks on issues
# Checks for antipatterns and dead code, forces fixes

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

issues=()
has_blocking_issues=false

# Run statix check
if command -v statix &> /dev/null; then
  statix_output=$(statix check "$file_path" 2>&1 || true)

  if [[ -n "$statix_output" ]] && ! echo "$statix_output" | grep -q "No errors found"; then
    issues+=("📊 Statix found antipatterns:")
    issues+=("$statix_output")
    issues+=("")
    has_blocking_issues=true
  fi
fi

# Run deadnix check
if command -v deadnix &> /dev/null; then
  deadnix_output=$(deadnix "$file_path" 2>&1 || true)

  if [[ -n "$deadnix_output" ]]; then
    issues+=("🧹 Deadnix found unused code:")
    issues+=("$deadnix_output")
    issues+=("")
    has_blocking_issues=true
  fi
fi

# Check for common antipatterns in content
content=$(cat "$file_path" 2>/dev/null || echo "")

if echo "$content" | grep -q "with pkgs;"; then
  issues+=("❌ Antipattern: 'with pkgs;' detected")
  issues+=("   Use explicit 'pkgs.packageName' instead")
  issues+=("   See CLAUDE.md for guidelines")
  issues+=("")
  has_blocking_issues=true
fi

# Check module placement antipatterns
# Convert to relative path from project root for pattern matching
relative_path="${file_path#${CLAUDE_PROJECT_DIR:-$(pwd)}/}"

if [[ "$relative_path" =~ ^home/.* ]]; then
  # Home-manager files shouldn't have system-level config
  if echo "$content" | grep -qE "(virtualisation\.(podman|docker)|hardware\.graphics)"; then
    issues+=("❌ Wrong placement: System-level config in home-manager")
    issues+=("   Move to modules/nixos/ or modules/darwin/")
    issues+=("   See CLAUDE.md Module Placement Guidelines")
    issues+=("")
    has_blocking_issues=true
  fi
elif [[ "$relative_path" =~ ^modules/(nixos|darwin)/.* ]]; then
  # System modules shouldn't have user-level config
  if echo "$content" | grep -qE "programs\.(helix|zed|vscode)\.enable"; then
    issues+=("❌ Wrong placement: User applications in system modules")
    issues+=("   Move to home/common/apps/ or home/{nixos,darwin}/")
    issues+=("   See CLAUDE.md Module Placement Guidelines")
    issues+=("")
    has_blocking_issues=true
  fi
fi

# If we found blocking issues, report them and exit with code 2
if [ "$has_blocking_issues" = true ]; then
  {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚫 Linting Issues in: $file_path"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    printf '%s\n' "${issues[@]}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Please fix these issues before continuing."
    echo ""
    echo "Quick fixes:"
    echo "  statix fix $file_path    # Auto-fix antipatterns"
    echo "  deadnix -e $file_path    # Auto-remove dead code"
    echo "  nix flake check          # Run all checks"
  } >&2
  exit 2
fi

# All checks passed
exit 0
