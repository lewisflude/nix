#!/usr/bin/env bash
# Verify removed feature options aren't referenced anywhere

set -euo pipefail

REMOVED_OPTIONS=(
  "gaming.lutris"
  "gaming.emulators"
  "virtualisation.qemu"
  "virtualisation.virtualbox"
  "development.kubernetes"
  "development.buildTools"
  "development.debugTools"
  "development.vscode"
  "development.helix"
  "development.neovim"
  "homeServer.homeAssistant"
  "homeServer.mediaServer"
  "homeServer.backups"
  "productivity.office"
  "media.audio.streaming"
  "media.video"
  "media.streaming"
  "security.firewall"
)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Verification: Removed Feature Options"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

errors=0

for opt in "${REMOVED_OPTIONS[@]}"; do
  # Search for references in host configs, modules, and home configs
  # Escape dots for grep regex
  escaped_opt="${opt//./\\.}"

  if rg "features\.$escaped_opt" hosts/ modules/ home/ --type nix --quiet 2>/dev/null; then
    echo "❌ Found reference to removed option: $opt"
    echo "   Locations:"
    rg "features\.$escaped_opt" hosts/ modules/ home/ --type nix --no-heading --line-number | sed 's/^/   /'
    echo ""
    errors=$((errors + 1))
  else
    echo "✓ No references to $opt"
  fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $errors -eq 0 ]; then
  echo "✅ All checks passed!"
  echo "   No references to removed options found."
  echo ""
  echo "Summary:"
  echo "  - Checked ${#REMOVED_OPTIONS[@]} removed options"
  echo "  - Searched hosts/, modules/, home/"
  echo "  - 0 issues found"
  exit 0
else
  echo "❌ Found $errors issues!"
  echo ""
  echo "Fix these references before proceeding:"
  echo "  1. Remove the references if they're no longer needed"
  echo "  2. Or restore the option if it's actually used"
  exit 1
fi
