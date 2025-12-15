#!/usr/bin/env bash
set -euo pipefail

QBIT_HOST="jupiter"
QBIT_PORT="8080"
QBIT_USER="lewis"
QBIT_PASS="${QBIT_PASS:-}"
STORAGE_PATH="/mnt/storage/torrents"
VERBOSE=true

# Import the log functions
BLUE='\033[0;34m'
NC='\033[0m'

log_debug() {
  if [[ "$VERBOSE" == true ]]; then
    echo -e "${BLUE}[DEBUG]${NC} $*" >&2
  fi
}

log_error() {
  echo -e "\033[0;31m[ERROR]\033[0m $*" >&2
}

# The actual function from the script
qbit_get_torrents() {
  local api_url="http://${QBIT_HOST}:${QBIT_PORT}/api/v2"
  
  log_debug "Connecting to qBittorrent at ${api_url}"
  
  # Check credentials
  if [[ -z "$QBIT_PASS" ]]; then
    log_error "QBIT_PASS not set - cannot authenticate"
    return 1
  fi
  
  # Login if credentials provided
  local cookie_jar=$(mktemp)
  log_debug "Logging in as ${QBIT_USER}"
  local login_response=$(curl -s -c "$cookie_jar" --data "username=${QBIT_USER}&password=${QBIT_PASS}" \
    "${api_url}/auth/login" 2>&1)
  log_debug "Login response: ${login_response}"
  
  if [[ "$login_response" != "Ok." ]]; then
    log_error "Login failed: ${login_response}"
    rm -f "$cookie_jar"
    return 1
  fi
  
  # Get torrent list
  log_debug "Fetching torrent list from ${api_url}/torrents/info"
  local raw_response=$(curl -s -b "$cookie_jar" "${api_url}/torrents/info" 2>&1)
  local response_length=${#raw_response}
  log_debug "Raw response length: ${response_length} bytes"
  
  if [[ $response_length -lt 10 ]]; then
    log_error "API response too short, possible error: ${raw_response}"
    rm -f "$cookie_jar"
    return 1
  fi
  
  # Filter for music production torrents in storage path
  local filtered_output
  filtered_output=$(echo "$raw_response" | \
    jq -r '.[] | select(.save_path | startswith("'${STORAGE_PATH}'")) | 
           select(.name | test("Serum|Melodyne|FabFilter|Elektron|Jungle|Toontrack|Ableton|KICK|Sample|Preset|MIDI|MiDi|Tutorial|Groove3|DX7|TX81Z|JUP-8|Goodhertz|AudioThing|Aphex"; "i")) |
           "\(.hash)|\(.name)|\(.save_path)"' 2>&1)
  
  local filtered_count=$(echo "$filtered_output" | wc -l | tr -d ' ')
  log_debug "Found ${filtered_count} music production torrents"
  
  echo "$filtered_output"
  
  rm -f "$cookie_jar"
  return 0
}

echo "Testing qbit_get_torrents function..."
echo "======================================"
echo ""

result=$(qbit_get_torrents)
exit_code=$?

echo ""
echo "Exit code: $exit_code"
echo "Output lines: $(echo "$result" | wc -l | tr -d ' ')"
echo ""
echo "First 5 lines:"
echo "$result" | head -5
