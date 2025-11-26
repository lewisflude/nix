#!/usr/bin/env bash
# Simple script to show the current ProtonVPN forwarded port
# Used by: protonvpn-portforward.nix

set -euo pipefail

# Configuration
NAMESPACE="${NAMESPACE:-qbt}"
VPN_GATEWAY="${VPN_GATEWAY:-10.2.0.1}"
STATE_FILE="/var/lib/protonvpn-portforward.state"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Try to get port from state file first (faster)
if [[ -f "$STATE_FILE" ]]; then
    PORT=$(grep PUBLIC_PORT "$STATE_FILE" 2>/dev/null | cut -d= -f2 || echo "")

    if [[ -n "$PORT" && "$PORT" -gt 0 ]]; then
        echo -e "${GREEN}ProtonVPN Forwarded Port:${NC} $PORT"

        # Show when it was last updated
        TIMESTAMP=$(stat -c %y "$STATE_FILE" 2>/dev/null | cut -d. -f1 || echo "Unknown")
        echo -e "${BLUE}Last updated:${NC} $TIMESTAMP"

        exit 0
    fi
fi

# Fallback: Query NAT-PMP directly (slower but always accurate)
echo -e "${YELLOW}State file not found, querying NAT-PMP...${NC}"

if ! command -v natpmpc &>/dev/null; then
    echo -e "${RED}Error:${NC} natpmpc not found. Install libnatpmp."
    exit 1
fi

PORT=$(sudo ip netns exec "$NAMESPACE" natpmpc -a 1 0 tcp 60 -g "$VPN_GATEWAY" 2>/dev/null | \
    grep 'Mapped public port' | awk '{print $4}' || echo "")

if [[ -n "$PORT" && "$PORT" -gt 0 ]]; then
    echo -e "${GREEN}ProtonVPN Forwarded Port:${NC} $PORT"
    echo -e "${BLUE}Source:${NC} NAT-PMP query"
else
    echo -e "${RED}Error:${NC} Failed to get forwarded port"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check VPN is running: sudo ip netns exec $NAMESPACE ip addr"
    echo "  2. Check service status: systemctl status protonvpn-portforward.service"
    echo "  3. Run port forwarding: sudo systemctl start protonvpn-portforward.service"
    exit 1
fi
