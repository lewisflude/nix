#!/usr/bin/env bash
# DEPRECATED: This script has been merged into detect-protonvpn-port.sh
# Redirecting to the unified script with scan method

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Note: find-protonvpn-forwarded-port.sh is deprecated"
echo "Using unified script: detect-protonvpn-port.sh"
echo ""

NAMESPACE="${1:-qbittor}"

exec "$SCRIPT_DIR/detect-protonvpn-port.sh" -n "$NAMESPACE" -m scan
