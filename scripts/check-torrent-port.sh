#!/usr/bin/env bash
# Generic torrent port checker - works for any port number
# Wrapper around the port checking logic for flexibility

set -euo pipefail

# Get port from argument or use 64243 as default
PORT="${1:-64243}"

# Validate port number
if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [[ "$PORT" -lt 1024 ]] || [[ "$PORT" -gt 65535 ]]; then
    echo "Error: Invalid port number '${PORT}'"
    echo "Usage: $0 [PORT]"
    echo "Port must be between 1024 and 65535"
    exit 1
fi

# Configuration
NAMESPACE="${NAMESPACE:-qbt}"
VPN_GATEWAY="${VPN_GATEWAY:-10.2.0.1}"
QBITTORRENT_CONFIG="/var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf"
TRANSMISSION_CONFIG="/var/lib/transmission/.config/transmission-daemon/settings.json"
PORTFORWARD_STATE="/var/lib/protonvpn-portforward.state"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Torrent Port ${PORT} - Quick Check${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check ProtonVPN assigned port
echo -e "${CYAN}▶ ProtonVPN Port Assignment${NC}"
if command -v natpmpc &>/dev/null && sudo ip netns list | grep -q "^${NAMESPACE}"; then
    PROTONVPN_PORT=$(sudo ip netns exec "${NAMESPACE}" natpmpc -a 1 0 tcp 60 -g "${VPN_GATEWAY}" 2>&1 | \
        grep -oP 'Mapped public port \K[0-9]+' || echo "0")

    if [[ "$PROTONVPN_PORT" -gt 0 ]]; then
        if [[ "$PROTONVPN_PORT" == "$PORT" ]]; then
            echo -e "  ${GREEN}✓${NC} ProtonVPN assigned port: ${PROTONVPN_PORT} (matches!)"
        else
            echo -e "  ${YELLOW}⚠${NC} ProtonVPN assigned port: ${PROTONVPN_PORT} (target: ${PORT})"
            echo -e "    ${BLUE}ℹ${NC} ProtonVPN assigns ports dynamically"
        fi
    else
        echo -e "  ${RED}✗${NC} Failed to query ProtonVPN NAT-PMP"
    fi
else
    echo -e "  ${RED}✗${NC} Cannot check - natpmpc not found or VPN namespace missing"
fi

# Check qBittorrent
echo ""
echo -e "${CYAN}▶ qBittorrent${NC}"
if systemctl is-active --quiet qbittorrent.service; then
    QB_PORT=$(sudo grep "^Session\\\\Port=" "$QBITTORRENT_CONFIG" 2>/dev/null | cut -d'=' -f2 || echo "0")

    if [[ "$QB_PORT" -gt 0 ]]; then
        if [[ "$QB_PORT" == "$PORT" ]]; then
            echo -e "  ${GREEN}✓${NC} Configured port: ${QB_PORT} (matches!)"
        else
            echo -e "  ${YELLOW}⚠${NC} Configured port: ${QB_PORT} (target: ${PORT})"
        fi

        # Check if listening
        if sudo ip netns exec "${NAMESPACE}" ss -tuln 2>/dev/null | grep -q ":${QB_PORT} "; then
            echo -e "  ${GREEN}✓${NC} Listening on port ${QB_PORT}"
        else
            echo -e "  ${RED}✗${NC} Not listening on port ${QB_PORT}"
        fi
    else
        echo -e "  ${RED}✗${NC} Could not read port from config"
    fi
else
    echo -e "  ${RED}✗${NC} Service not running"
fi

# Check Transmission
echo ""
echo -e "${CYAN}▶ Transmission${NC}"
if systemctl is-active --quiet transmission.service; then
    TR_PORT=$(sudo grep '"peer-port"' "$TRANSMISSION_CONFIG" 2>/dev/null | grep -oP '\d+' || echo "0")

    if [[ "$TR_PORT" -gt 0 ]]; then
        if [[ "$TR_PORT" == "$PORT" ]]; then
            echo -e "  ${GREEN}✓${NC} Configured port: ${TR_PORT} (matches!)"
        else
            echo -e "  ${YELLOW}⚠${NC} Configured port: ${TR_PORT} (target: ${PORT})"
        fi

        # Check if listening
        if sudo ip netns exec "${NAMESPACE}" ss -tuln 2>/dev/null | grep -q ":${TR_PORT} "; then
            echo -e "  ${GREEN}✓${NC} Listening on port ${TR_PORT}"
        else
            echo -e "  ${RED}✗${NC} Not listening on port ${TR_PORT}"
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} Could not read port from config"
    fi
elif systemctl list-unit-files transmission.service &>/dev/null; then
    echo -e "  ${YELLOW}⚠${NC} Service not running"
else
    echo -e "  ${BLUE}ℹ${NC} Not configured (skipping)"
fi

# External IP check
echo ""
echo -e "${CYAN}▶ External Connectivity${NC}"
EXTERNAL_IP=$(sudo ip netns exec "${NAMESPACE}" curl -s --max-time 5 https://api.ipify.org 2>/dev/null || echo "")

if [[ -n "$EXTERNAL_IP" ]]; then
    echo -e "  ${GREEN}✓${NC} External IP (via VPN): ${EXTERNAL_IP}"
    echo -e "  ${YELLOW}⚠${NC} Verify this is NOT your real IP"

    echo ""
    echo -e "${CYAN}▶ External Port Test${NC}"
    echo -e "  ${BLUE}ℹ${NC} Test port ${PORT} at: https://www.yougetsignal.com/tools/open-ports/"
    echo -e "  ${BLUE}ℹ${NC} IP: ${EXTERNAL_IP}, Port: ${PROTONVPN_PORT:-$PORT}"
else
    echo -e "  ${RED}✗${NC} Cannot determine external IP"
fi

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "For detailed diagnostics, run:"
echo "  ./scripts/check-torrent-port-64243.sh  # Comprehensive check"
echo "  ./scripts/verify-qbittorrent-vpn.sh    # Full VPN verification"
echo "  ./scripts/test-vpn-port-forwarding.sh  # Quick port forwarding test"
echo ""
