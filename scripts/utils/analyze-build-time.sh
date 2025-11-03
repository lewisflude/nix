#!/usr/bin/env bash
# Analyze build times from a Nix build log
# Usage: ./analyze-build-time.sh [build.log]
# Supports both bar-with-logs and internal-json formats

set -euo pipefail

LOG_FILE="${1:-/tmp/build.log}"

if [[ ! -f "$LOG_FILE" ]]; then
  echo "Error: Build log not found: $LOG_FILE"
  echo "Usage: $0 [path/to/build.log]"
  exit 1
fi

echo "🔍 Analyzing build times from: $LOG_FILE"
echo ""

# Check if it's JSON format (with or without @nix prefix)
if head -1 "$LOG_FILE" | grep -q "^@nix " || head -1 "$LOG_FILE" | jq -e . >/dev/null 2>&1; then
  # JSON format - parse with jq
  echo "📊 Parsing JSON log format..."
  echo ""

  # Extract derivations that were built (from "building" text messages)
  echo "🏗️  Derivations built:"
  echo ""

  sed 's/^@nix //' "$LOG_FILE" | jq -r 'select(.text != null) | select(.text | startswith("building")) | .text' 2>/dev/null | sed "s/building '//" | sed "s/'$//" | while IFS= read -r drv; do
    if [[ -n "$drv" ]]; then
      # Extract package name from derivation path
      pkg_name=$(basename "$drv" | sed 's/-[0-9].*//' | sed 's/^[^-]*-//' | sed 's/\.drv$//')
      printf "  %s\n" "$pkg_name"
    fi
  done

  echo ""
  echo "📈 Summary:"
  total_drvs=$(sed 's/^@nix //' "$LOG_FILE" | jq -r '[inputs] | map(select(.text != null and (.text | startswith("building")))) | length' 2>/dev/null || echo "0")

  echo "  Total derivations in log: $total_drvs"
  echo ""
  echo "💡 Note: This log shows final system derivations (likely cached/fast)."
  echo "   Your 3-5 minute build time suggests slow builds occurred earlier."
  echo ""
  echo "   To find what's actually slow, try:"
  echo ""
  echo "   1. Check total dependency count:"
  echo "      nix-store --query --requisites \\"
  echo "        \$(nix eval --raw '.#nixosConfigurations.jupiter.config.system.build.toplevel') \\"
  echo "        | wc -l"
  echo ""
  echo "   2. Use nix-tree to visualize dependencies:"
  echo "      nix-tree \\"
  echo "        \$(nix eval --raw '.#nixosConfigurations.jupiter.config.system.build.toplevel')"
  echo ""
  echo "   3. Profile with time(1) to see where time is spent:"
  echo "      time nix build '.#nixosConfigurations.jupiter.config.system.build.toplevel'"
  echo ""
  echo "   4. Check evaluation time separately:"
  echo "      ./scripts/utils/profile-build.sh nixosConfigurations.jupiter"

else
  # Text format - parse grep patterns
  echo "📊 Build Summary:"
  echo ""

  # Count total derivations
  total_drvs=$(grep -c "building '/nix/store" "$LOG_FILE" 2>/dev/null || echo "0")
  echo "  Total derivations built: $total_drvs"

  # Find derivations that took time (look for patterns indicating build vs fetch)
  echo ""
  echo "🏗️  Derivations that were built (not fetched):"
  grep -E "building '/nix/store.*\.drv'" "$LOG_FILE" | sed 's/.*building //' | sed "s/'//g" | while read -r drv; do
    # Extract package name from derivation path
    pkg_name=$(basename "$drv" | sed 's/-[0-9].*//' | sed 's/^[^-]*-//')
    echo "  - $pkg_name ($(basename "$drv"))"
  done

  echo ""
  echo "💡 For detailed timing, use JSON format:"
  echo "   nix build '.#nixosConfigurations.jupiter.config.system.build.toplevel' \\"
  echo "     --log-format internal-json \\"
  echo "     --max-jobs 1 2>&1 | tee build-timing.json"
  echo ""
  echo "   Then analyze with: $0 build-timing.json"
fi
