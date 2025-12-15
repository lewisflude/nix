#!/usr/bin/env bash
#
# test-torrent-api.sh
#
# Quick test script to verify qBittorrent and Transmission API connectivity
#

set -euo pipefail

QBIT_HOST="${QBIT_HOST:-jupiter}"
QBIT_PORT="${QBIT_PORT:-8080}"
QBIT_USER="${QBIT_USER:-lewis}"
QBIT_PASS="${QBIT_PASS:-}"

TRANS_HOST="${TRANS_HOST:-jupiter}"
TRANS_PORT="${TRANS_PORT:-9091}"
TRANS_USER="${TRANS_USER:-lewis}"
TRANS_PASS="${TRANS_PASS:-${QBIT_PASS}}"

echo "Testing torrent client API connectivity..."
echo "=========================================="
echo ""

# Test qBittorrent
echo "1. Testing qBittorrent API at http://${QBIT_HOST}:${QBIT_PORT}"
echo "   Username: ${QBIT_USER}"

if [[ -z "$QBIT_PASS" ]]; then
  echo "   ❌ QBIT_PASS not set - please export QBIT_PASS='your_password'"
else
  # Try to login
  cookie_jar=$(mktemp)
  login_response=$(curl -s -w "\n%{http_code}" -c "$cookie_jar" \
    --data "username=${QBIT_USER}&password=${QBIT_PASS}" \
    "http://${QBIT_HOST}:${QBIT_PORT}/api/v2/auth/login")
  
  http_code=$(echo "$login_response" | tail -n1)
  response_body=$(echo "$login_response" | head -n-1)
  
  if [[ "$http_code" == "200" && "$response_body" == "Ok." ]]; then
    echo "   ✅ Login successful!"
    
    # Get torrent count
    torrent_count=$(curl -s -b "$cookie_jar" \
      "http://${QBIT_HOST}:${QBIT_PORT}/api/v2/torrents/info" | jq '. | length')
    echo "   📊 Total torrents: ${torrent_count}"
    
    # Get music production torrents
    music_prod_count=$(curl -s -b "$cookie_jar" \
      "http://${QBIT_HOST}:${QBIT_PORT}/api/v2/torrents/info" | \
      jq '[.[] | select(.name | test("Serum|Melodyne|FabFilter|Elektron|Jungle|Toontrack|Ableton|KICK|Sample|Preset|MIDI|MiDi|Tutorial|Groove3|DX7|TX81Z|JUP-8|Goodhertz|AudioThing|Aphex"; "i"))] | length')
    echo "   🎵 Music production torrents: ${music_prod_count}"
    
  else
    echo "   ❌ Login failed (HTTP ${http_code}): ${response_body}"
    echo "   Check your password and try again"
  fi
  
  rm -f "$cookie_jar"
fi

echo ""

# Test Transmission RPC API
echo "2. Testing Transmission RPC at http://${TRANS_HOST}:${TRANS_PORT}"
echo "   Username: ${TRANS_USER}"

if [[ -z "$TRANS_PASS" ]]; then
  echo "   ❌ TRANS_PASS not set - using same password as qBittorrent"
  if [[ -z "$QBIT_PASS" ]]; then
    echo "   ❌ No password available"
  fi
else
  # Get session ID (required for CSRF protection)
  api_url="http://${TRANS_HOST}:${TRANS_PORT}/transmission/rpc"
  
  session_response=$(curl -s -I --anyauth -u "${TRANS_USER}:${TRANS_PASS}" "${api_url}" 2>&1)
  http_code=$(echo "$session_response" | head -1 | awk '{print $2}')
  session_id=$(echo "$session_response" | grep -i "X-Transmission-Session-Id:" | cut -d' ' -f2 | tr -d '\r\n')
  
  if [[ "$http_code" == "409" && -n "$session_id" ]]; then
    echo "   ✅ Authentication successful!"
    echo "   🔑 Session ID obtained"
    
    # Get torrent list
    response=$(curl -s --anyauth -u "${TRANS_USER}:${TRANS_PASS}" \
      -H "X-Transmission-Session-Id: ${session_id}" \
      -d '{"method":"torrent-get","arguments":{"fields":["id","name","downloadDir"]}}' \
      "${api_url}")
    
    torrent_count=$(echo "$response" | jq '.arguments.torrents | length' 2>/dev/null || echo "0")
    echo "   📊 Total torrents: ${torrent_count}"
    
    # Count music production torrents
    music_prod_count=$(echo "$response" | jq '[.arguments.torrents[] | 
      select(.name | test("Serum|Melodyne|FabFilter|Elektron|Jungle|Toontrack|Ableton|KICK|Sample|Preset|MIDI|MiDi|Tutorial|Groove3|DX7|TX81Z|JUP-8|Goodhertz|AudioThing|Aphex"; "i"))] | length' 2>/dev/null || echo "0")
    echo "   🎵 Music production torrents: ${music_prod_count}"
    
  elif [[ "$http_code" == "401" ]]; then
    echo "   ❌ Authentication failed - check username/password"
  else
    echo "   ❌ Connection failed (HTTP ${http_code})"
    echo "   Response: ${session_response}" | head -3
  fi
fi

echo ""
echo "Test complete!"
