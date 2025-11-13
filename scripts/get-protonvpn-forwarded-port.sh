#!/usr/bin/env bash
# DEPRECATED: This script has been merged into detect-protonvpn-port.sh
# Redirecting to the unified script with NAT-PMP method

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Note: get-protonvpn-forwarded-port.sh is deprecated"
echo "Using unified script: detect-protonvpn-port.sh"
echo ""

NAMESPACE="${1:-qbittor}"
VPN_GATEWAY="${2:-10.2.0.1}"

exec "$SCRIPT_DIR/detect-protonvpn-port.sh" -n "$NAMESPACE" -g "$VPN_GATEWAY" -m natpmp
