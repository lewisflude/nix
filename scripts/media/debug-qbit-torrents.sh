#!/usr/bin/env bash
set -euo pipefail

QBIT_HOST="jupiter"
QBIT_PORT="8080"
QBIT_USER="lewis"
QBIT_PASS="${QBIT_PASS:-}"

if [[ -z "$QBIT_PASS" ]]; then
  echo "Error: QBIT_PASS not set"
  exit 1
fi

api_url="http://${QBIT_HOST}:${QBIT_PORT}/api/v2"

# Login
echo "Logging in..."
cookie_jar=$(mktemp)
curl -s -c "$cookie_jar" --data "username=${QBIT_USER}&password=${QBIT_PASS}" \
  "${api_url}/auth/login"
echo ""

# Get all torrents
echo "Getting all torrents..."
all_torrents=$(curl -s -b "$cookie_jar" "${api_url}/torrents/info")
echo "Total torrents: $(echo "$all_torrents" | jq '. | length')"
echo ""

# Show first torrent as example
echo "Example torrent:"
echo "$all_torrents" | jq '.[0] | {name, save_path, category}'
echo ""

# Filter by storage path
echo "Torrents in /mnt/storage:"
storage_torrents=$(echo "$all_torrents" | jq '[.[] | select(.save_path | startswith("/mnt/storage"))]')
echo "Count: $(echo "$storage_torrents" | jq '. | length')"
echo ""

# Show sample
echo "Sample of storage torrents:"
echo "$storage_torrents" | jq '.[0:3] | .[] | {name, save_path}'
echo ""

# Filter for music production
echo "Music production torrents:"
music_torrents=$(echo "$all_torrents" | jq '[.[] | 
  select(.save_path | startswith("/mnt/storage")) |
  select(.name | test("Serum|Melodyne|FabFilter|Elektron|Jungle|Toontrack|Ableton|KICK|Sample|Preset|MIDI|MiDi|Tutorial|Groove3|DX7|TX81Z|JUP-8|Goodhertz|AudioThing|Aphex"; "i"))]')
echo "Count: $(echo "$music_torrents" | jq '. | length')"
echo ""

# Show them
echo "Music production torrents found:"
echo "$music_torrents" | jq -r '.[] | "\(.name) -> \(.save_path)"' | head -20

rm -f "$cookie_jar"
