#!/usr/bin/env bash
# Pre-edit validation hook for dendritic pattern enforcement
#
# Claude Code Documentation:
# - Hooks receive tool call JSON via stdin
# - Exit code 0: allow action
# - Exit code 2: block action (shows error to user and Claude)
# - Exit code 1: hook error (shows warning)
#
# This hook enforces dendritic pattern anti-patterns in real-time
# before code is written to disk.

set -euo pipefail

# Read the tool call input from stdin
INPUT=$(cat)

# Extract file path from the tool call
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only validate .nix files under modules/
if [[ $FILE_PATH != */modules/*.nix ]]; then
  exit 0
fi

# Get content being written/edited
# - For Write tool: content field (full file)
# - For Edit tool: new_string field (fragment only)
CONTENT=""
IS_EDIT=false
if echo "$INPUT" | jq -e '.tool_input.content' >/dev/null 2>&1; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content')
elif echo "$INPUT" | jq -e '.tool_input.new_string' >/dev/null 2>&1; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string')
  IS_EDIT=true
fi

# If no content to validate, allow
if [[ -z $CONTENT ]]; then
  exit 0
fi

ERRORS=()

# ======================================================================
# DENDRITIC PATTERN VALIDATION
# ======================================================================

# Anti-pattern 1: with pkgs;
# See DENDRITIC_PATTERN.md#anti-patterns
if echo "$CONTENT" | grep -q "with pkgs;"; then
  ERRORS+=("❌ Anti-pattern 'with pkgs;' detected")
  ERRORS+=("   Use explicit package references: pkgs.curl pkgs.wget")
  ERRORS+=("   See: DENDRITIC_PATTERN.md line 1020-1026")
fi

# Anti-pattern 2: specialArgs / extraSpecialArgs
# See DENDRITIC_PATTERN.md#value-sharing-no-specialargs
if echo "$CONTENT" | grep -qE "(specialArgs|extraSpecialArgs)"; then
  ERRORS+=("❌ Anti-pattern 'specialArgs/extraSpecialArgs' detected")
  ERRORS+=("   Access values via top-level config instead")
  ERRORS+=("   See: DENDRITIC_PATTERN.md line 477-527")
fi

# Anti-pattern 3: Direct constant imports
# See DENDRITIC_PATTERN.md#accessing-constants
if echo "$CONTENT" | grep -qE "import.*(lib/constants|constants\.nix)"; then
  ERRORS+=("❌ Anti-pattern: importing constants directly")
  ERRORS+=("   Access via config.constants")
  ERRORS+=("   See: DENDRITIC_PATTERN.md line 723-766")
fi

# Anti-pattern 4: Importing flake-parts.flakeModules.modules outside infrastructure
# Infrastructure modules should import this, not feature modules
if [[ $FILE_PATH != */infrastructure/* ]] && echo "$CONTENT" | grep -q "flake-parts.flakeModules.modules"; then
  ERRORS+=("⚠️  flakeModules.modules should only be imported in infrastructure/flake-parts.nix")
  ERRORS+=("   See: DENDRITIC_PATTERN.md line 129-148")
fi

# Pattern validation: Feature modules should define flake.modules.*
# (Skip infrastructure and host definition files)
# (Skip for Edit operations since we only see a fragment, not full file)
if [[ $IS_EDIT == false ]] &&
  [[ $FILE_PATH =~ ^.*/modules/[^/]+\.nix$ ]] &&
  [[ $FILE_PATH != */infrastructure/* ]] &&
  [[ $FILE_PATH != */hosts/* ]] &&
  [[ $FILE_PATH != */constants.nix ]] &&
  [[ $FILE_PATH != */meta.nix ]] &&
  [[ $FILE_PATH != */systems.nix ]]; then

  # Check if it defines flake.modules.*
  if ! echo "$CONTENT" | grep -q "flake\.modules\."; then
    ERRORS+=("⚠️  Feature module should define flake.modules.* options")
    ERRORS+=("   Example: flake.modules.nixos.myFeature = { ... };")
    ERRORS+=("   See: DENDRITIC_PATTERN.md line 280-348")
  fi
fi

# Scope confusion check: shadowing config
# Look for pattern where outer function has config, inner function also has config
# This is a heuristic check - may have false positives
if echo "$CONTENT" | grep -qP '{\s*config.*?flake\.modules\.\w+\.\w+\s*=\s*{\s*config'; then
  ERRORS+=("⚠️  Possible config scope confusion detected")
  ERRORS+=("   Use named parameter (nixosArgs) to avoid shadowing outer config")
  ERRORS+=("   See: DENDRITIC_PATTERN.md line 306-341")
fi

# ======================================================================
# REPORT ERRORS
# ======================================================================

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "🚫 Dendritic Pattern Violation in: $FILE_PATH" >&2
  echo "" >&2
  printf "   %s\n" "${ERRORS[@]}" >&2
  echo "" >&2
  echo "   📖 Read DENDRITIC_PATTERN.md for complete pattern guide" >&2
  echo "   💡 Ask: 'Can you fix this following dendritic pattern?'" >&2
  exit 2 # Exit code 2 blocks the action
fi

# All checks passed
exit 0
