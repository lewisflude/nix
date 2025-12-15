#!/usr/bin/env bash
set -euo pipefail

QBIT_HOST="jupiter"
QBIT_PORT="8080"
QBIT_USER="lewis"
QBIT_PASS="${QBIT_PASS:-}"
STORAGE_PATH="/mnt/storage/torrents"

if [[ -z "$QBIT_PASS" ]]; then
  echo "Error: QBIT_PASS not set"
  exit 1
fi

api_url="http://${QBIT_HOST}:${QBIT_PORT}/api/v2"

# Login
echo "Logging in..."
cookie_jar=$(mktemp)
curl -s -c "$cookie_jar" --data "username=${QBIT_USER}&password=${QBIT_PASS}" \
  "${api_url}/auth/login" > /dev/null

# Get torrent list
echo "Fetching torrents..."
raw_response=$(curl -s -b "$cookie_jar" "${api_url}/torrents/info")

echo "Total torrents: $(echo "$raw_response" | jq '. | length')"
echo ""

# Try the filter from the script
echo "Testing filter (should output hash|name|path format):"
echo "$raw_response" | \
  jq -r '.[] | select(.save_path | startswith("'${STORAGE_PATH}'")) | 
         select(.name | test("Serum|Melodyne|FabFilter|Elektron|Jungle|Toontrack|Ableton|KICK|Sample|Preset|MIDI|MiDi|Tutorial|Groove3|DX7|TX81Z|JUP-8|Goodhertz|AudioThing|Aphex"; "i")) |
         "\(.hash)|\(.name)|\(.save_path)"' | head -10

echo ""
echo "Count of filtered torrents:"
echo "$raw_response" | \
  jq -r '.[] | select(.save_path | startswith("'${STORAGE_PATH}'")) | 
         select(.name | test("Serum|Melodyne|FabFilter|Elektron|Jungle|Toontrack|Ableton|KICK|Sample|Preset|MIDI|MiDi|Tutorial|Groove3|DX7|TX81Z|JUP-8|Goodhertz|AudioThing|Aphex"; "i")) |
         "\(.hash)|\(.name)|\(.save_path)"' | wc -l

rm -f "$cookie_jar"
