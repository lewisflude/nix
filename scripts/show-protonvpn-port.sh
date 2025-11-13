#!/usr/bin/env bash
# Show current ProtonVPN forwarded port
set -euo pipefail

STATE_FILE="/var/lib/protonvpn-portforward.state"

if [[ ! -f "$STATE_FILE" ]]; then
    echo "No port forwarding state found. Run: sudo systemctl start protonvpn-natpmp.service"
    exit 1
fi

# Source the state file
source "$STATE_FILE"

echo "ProtonVPN Port Forwarding Status"
echo "================================"
echo "Last Updated: $TIMESTAMP"
echo "Private Port (qBittorrent):  $PRIVATE_PORT"
echo "Public Port (ProtonVPN):     $PUBLIC_PORT"
echo ""
echo "Configure your tracker/router to use port: $PUBLIC_PORT"
echo "qBittorrent internally uses port: $PRIVATE_PORT"
