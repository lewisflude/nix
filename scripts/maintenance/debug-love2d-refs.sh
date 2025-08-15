#!/usr/bin/env bash
set -euo pipefail

echo "🔍 Searching for unconditional 'pkgs.love' references..."
rg --no-heading --line-number 'pkgs\.love' .

echo
echo "🔍 Searching for potentially ungated love2d-related content..."
rg --no-heading --line-number 'love2d' . \
  | grep -vE '(!.*isDarwin|platformLib\.is(Linux|Darwin)|optionalAttrs|lib\.mkIf)' || true

echo
echo "🔍 Checking for mkShells that could be gated but aren’t..."
rg --no-heading --context 3 'mkShell' . \
  | grep -B3 -A3 'love' \
  | grep -vE '(!.*isDarwin|optionalAttrs|lib\.mkIf|platformLib\.is)' || true

echo
echo "🔍 Searching for deprecated toPlist usage without escape = true..."
rg --no-heading --line-number 'toPlist\s*{[^}]*' . \
  | grep -v 'escape\s*=' || true

