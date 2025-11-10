#!/usr/bin/env bash
# Check for speed throttling in qBittorrent setup

set -euo pipefail

echo "=== qBittorrent Speed Throttling Check ==="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

CONFIG_FILE="/var/lib/qbittorrent/config/qBittorrent.conf"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root (use sudo)${NC}"
    exit 1
fi

# 1. Check qBittorrent speed limits
echo "1. qBittorrent Speed Limits:"
if [ -f "$CONFIG_FILE" ]; then
    DL_LIMIT=$(grep "^Session\\\\GlobalDLSpeedLimit=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2 || echo "")
    UP_LIMIT=$(grep "^Session\\\\GlobalUPSpeedLimit=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2 || echo "")

    if [ -n "$DL_LIMIT" ] && [ "$DL_LIMIT" != "0" ]; then
        DL_MB=$(awk "BEGIN {printf \"%.2f\", $DL_LIMIT/1024}")
        DL_MBPS=$(awk "BEGIN {printf \"%.2f\", $DL_LIMIT*8/1024}")
        echo -e "   ${YELLOW}?${NC} Download limit: ${DL_LIMIT} KB/s (${DL_MB} MB/s, ~${DL_MBPS} Mbps)"
        echo "     To remove: Set to 0 in qBittorrent WebUI (Options ? Speed) or config"
    else
        echo -e "   ${GREEN}?${NC} Download: Unlimited"
    fi

    if [ -n "$UP_LIMIT" ] && [ "$UP_LIMIT" != "0" ]; then
        UP_MB=$(awk "BEGIN {printf \"%.2f\", $UP_LIMIT/1024}")
        UP_MBPS=$(awk "BEGIN {printf \"%.2f\", $UP_LIMIT*8/1024}")
        echo -e "   ${YELLOW}?${NC} Upload limit: ${UP_LIMIT} KB/s (${UP_MB} MB/s, ~${UP_MBPS} Mbps)"
        echo "     To remove: Set to 0 in qBittorrent WebUI (Options ? Speed) or config"
    else
        echo -e "   ${GREEN}?${NC} Upload: Unlimited"
    fi
else
    echo -e "   ${RED}?${NC} Config file not found: $CONFIG_FILE"
fi

# 2. Check connection limits
echo ""
echo "2. Connection Limits:"
if [ -f "$CONFIG_FILE" ]; then
    MAX_CONN=$(grep "^Session\\\\MaxConnections=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2 || echo "")
    MAX_CONN_PER=$(grep "^Session\\\\MaxConnectionsPerTorrent=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2 || echo "")
    MAX_UP=$(grep "^Session\\\\MaxUploads=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2 || echo "")
    MAX_UP_PER=$(grep "^Session\\\\MaxUploadsPerTorrent=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2 || echo "")

    if [ -n "$MAX_CONN" ]; then
        echo "   Max connections: $MAX_CONN"
    fi
    if [ -n "$MAX_CONN_PER" ]; then
        echo "   Max connections per torrent: $MAX_CONN_PER"
    fi
    if [ -n "$MAX_UP" ]; then
        echo "   Max upload slots: $MAX_UP"
    fi
    if [ -n "$MAX_UP_PER" ]; then
        echo "   Max upload slots per torrent: $MAX_UP_PER"
    fi
fi

# 3. Check for traffic control (tc) rules
echo ""
echo "3. System Traffic Control (tc) Rules:"
TC_RULES=$(sudo ip netns exec qbittor tc qdisc show 2>/dev/null | grep -v "noqueue" || true)
if [ -z "$TC_RULES" ]; then
    echo -e "   ${GREEN}?${NC} No traffic shaping rules found"
else
    echo -e "   ${YELLOW}?${NC} Traffic control rules found:"
    echo "$TC_RULES" | sed 's/^/     /'
fi

# 4. Check systemd service limits
echo ""
echo "4. Systemd Service Resource Limits:"
SERVICE_FILE="/etc/systemd/system/qbittorrent.service"
if [ -f "$SERVICE_FILE" ]; then
    if grep -q "LimitCPU\|LimitIOPS\|IOWeight\|CPUWeight" "$SERVICE_FILE" 2>/dev/null; then
        echo -e "   ${YELLOW}?${NC} Resource limits found in service file:"
        grep -E "LimitCPU|LimitIOPS|IOWeight|CPUWeight" "$SERVICE_FILE" | sed 's/^/     /'
    else
        echo -e "   ${GREEN}?${NC} No resource limits in service file"
    fi
else
    echo "   Service file not found (may be using NixOS service)"
fi

# 5. Check VPN interface speed (if available)
echo ""
echo "5. VPN Interface:"
VPN_IP=$(sudo ip netns exec qbittor ip addr show qbittor0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d/ -f1 || echo "")
if [ -n "$VPN_IP" ]; then
    echo "   VPN IP: $VPN_IP"
    # Test VPN speed (basic connectivity)
    if sudo ip netns exec qbittor ping -c 1 -W 2 10.2.0.1 >/dev/null 2>&1; then
        echo -e "   ${GREEN}?${NC} VPN gateway reachable"
    else
        echo -e "   ${YELLOW}?${NC} VPN gateway not reachable (may affect speed)"
    fi
fi

# 6. Check for uTP rate limiting
echo ""
echo "6. uTP Rate Limiting:"
if [ -f "$CONFIG_FILE" ]; then
    UTP_RATE_LIMIT=$(grep "^Connection\\\\uTP_rate_limit_enabled=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2 || echo "")
    if [ "$UTP_RATE_LIMIT" = "true" ]; then
        echo -e "   ${BLUE}?${NC} uTP rate limiting enabled (may affect speeds)"
    else
        echo -e "   ${GREEN}?${NC} uTP rate limiting disabled"
    fi
fi

# 7. Summary
echo ""
echo "=== Summary ==="
if [ -n "$DL_LIMIT" ] && [ "$DL_LIMIT" != "0" ] || [ -n "$UP_LIMIT" ] && [ "$UP_LIMIT" != "0" ]; then
    echo -e "${YELLOW}? Speed limits are configured in qBittorrent${NC}"
    echo ""
    echo "To remove speed limits:"
    echo "  1. Open qBittorrent WebUI: http://localhost:8080"
    echo "  2. Go to Options ? Speed"
    echo "  3. Set 'Global download rate limit' to 0 (unlimited)"
    echo "  4. Set 'Global upload rate limit' to 0 (unlimited)"
    echo "  5. Click 'Apply' and restart qBittorrent"
    echo ""
    echo "Or edit config directly:"
    echo "  sudo nano $CONFIG_FILE"
    echo "  Change: Session\\GlobalDLSpeedLimit=0"
    echo "  Change: Session\\GlobalUPSpeedLimit=0"
    echo "  sudo systemctl restart qbittorrent"
else
    echo -e "${GREEN}? No speed limits found in qBittorrent configuration${NC}"
    echo ""
    echo "If speeds are still slow, check:"
    echo "  - VPN provider speed limits"
    echo "  - Network connection speed"
    echo "  - Torrent swarm health (number of peers/seeds)"
    echo "  - Disk I/O performance"
fi
