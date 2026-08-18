#!/usr/bin/env bash
# Simple script to show the current ProtonVPN forwarded port.
# Standalone diagnostic: queries NAT-PMP inside the VPN namespace directly.
# (modules/protonvpn-portforward.nix does not shell out to this script.)

set -euo pipefail

# Configuration
NAMESPACE="${NAMESPACE:-qbt}"
VPN_GATEWAY="${VPN_GATEWAY:-10.2.0.1}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Query NAT-PMP directly for the currently mapped public port
echo -e "${YELLOW}Querying NAT-PMP...${NC}"

if ! command -v natpmpc &>/dev/null; then
  echo -e "${RED}Error:${NC} natpmpc not found. Install libnatpmp."
  exit 1
fi

PORT=$(sudo ip netns exec "$NAMESPACE" natpmpc -a 1 0 tcp 60 -g "$VPN_GATEWAY" 2>/dev/null |
  grep 'Mapped public port' | awk '{print $4}' || echo "")

if [[ -n $PORT && $PORT -gt 0 ]]; then
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
