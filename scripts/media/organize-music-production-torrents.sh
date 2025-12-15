#!/usr/bin/env bash
#
# organize-music-production-torrents.sh
#
# Organize music production torrents into categorized subfolders
# Works with both qBittorrent and Transmission APIs
#
# Usage: ./organize-music-production-torrents.sh [--dry-run] [--client qbittorrent|transmission|both]
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STORAGE_PATH="/mnt/storage/torrents"
MUSIC_PROD_BASE="${STORAGE_PATH}/music-production"

# API endpoints (configure these for your setup)
QBIT_HOST="${QBIT_HOST:-jupiter}"
QBIT_PORT="${QBIT_PORT:-8080}"
QBIT_USER="${QBIT_USER:-lewis}"
QBIT_PASS="${QBIT_PASS:-}"

TRANS_HOST="${TRANS_HOST:-jupiter}"
TRANS_PORT="${TRANS_PORT:-9091}"
TRANS_USER="${TRANS_USER:-lewis}"
TRANS_PASS="${TRANS_PASS:-${QBIT_PASS}}"  # Default to same as qBittorrent

# Flags
DRY_RUN=false
CLIENT="both"
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --client)
      CLIENT="$2"
      shift 2
      ;;
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --dry-run              Preview changes without moving files"
      echo "  --client <name>        Choose client: qbittorrent, transmission, or both (default: both)"
      echo "  --verbose, -v          Enable verbose output for debugging"
      echo "  --help, -h             Show this help message"
      echo ""
      echo "Environment variables:"
      echo "  QBIT_HOST              qBittorrent hostname (default: jupiter)"
      echo "  QBIT_PORT              qBittorrent WebUI port (default: 8070)"
      echo "  QBIT_USER              qBittorrent username"
      echo "  QBIT_PASS              qBittorrent password"
      echo "  TRANS_HOST             Transmission hostname (default: jupiter)"
      echo "  TRANS_PORT             Transmission RPC port (default: 9091)"
      echo "  TRANS_USER             Transmission username"
      echo "  TRANS_PASS             Transmission password"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Helper functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*"
}

log_debug() {
  if [[ "$VERBOSE" == true ]]; then
    echo -e "${BLUE}[DEBUG]${NC} $*" >&2
  fi
}

# Category detection based on torrent name
detect_category() {
  local name="$1"
  
  # DAW Software
  if [[ "$name" =~ (Ableton|Logic|FL.Studio|Cubase|Reaper|Studio.One|Pro.Tools|Bitwig) ]]; then
    echo "daw-software"
    return
  fi
  
  # Synthesizers
  if [[ "$name" =~ (Serum|Massive|Omnisphere|Diva|Pigments|Vital|JUP-8|M1|DX7|TX81Z) ]]; then
    echo "plugins/synthesizers"
    return
  fi
  
  # Effects plugins
  if [[ "$name" =~ (FabFilter|Waves|iZotope|Soundtoys|Valhalla|Goodhertz|AudioThing|Aphex|Valve.Exciter|LimitOne) ]]; then
    echo "plugins/effects"
    return
  fi
  
  # Mixing/Mastering
  if [[ "$name" =~ (Melodyne|Auto-Tune|Ozone|Neutron|RX) ]]; then
    echo "plugins/mixing-mastering"
    return
  fi
  
  # Jungle/DnB samples
  if [[ "$name" =~ (Jungle|Amen|Breakbeat|DnB|Drum.and.Bass) ]]; then
    echo "sample-packs/jungle-dnb"
    return
  fi
  
  # Elektron hardware packs
  if [[ "$name" =~ Elektron.*Analog.Rytm ]]; then
    echo "sample-packs/elektron-rytm"
    return
  fi
  
  # Drum samples
  if [[ "$name" =~ (Superior.Drummer|GetGood.Drums|GGD|Toontrack.*Drum) ]]; then
    echo "sample-packs/drums"
    return
  fi
  
  # Generic sample packs
  if [[ "$name" =~ (Sample|Samples|\.WAV|Loop|Preset|Sound.Pack) ]]; then
    echo "sample-packs/other"
    return
  fi
  
  # Serum presets
  if [[ "$name" =~ Serum.*Preset ]]; then
    echo "presets/serum"
    return
  fi
  
  # FabFilter presets
  if [[ "$name" =~ FabFilter.*Preset ]]; then
    echo "presets/fabfilter"
    return
  fi
  
  # Sonic Academy KICK presets
  if [[ "$name" =~ KICK.*Preset ]]; then
    echo "presets/kick"
    return
  fi
  
  # Vintage synth presets
  if [[ "$name" =~ (DX7|TX81Z|JUP-8000).*CARTRIDGE|BANK|NKI ]]; then
    echo "presets/vintage-synths"
    return
  fi
  
  # Generic presets
  if [[ "$name" =~ Preset|BANK ]]; then
    echo "presets/other"
    return
  fi
  
  # Ableton racks
  if [[ "$name" =~ ABLETON.RACK|iFeature ]]; then
    echo "ableton-racks"
    return
  fi
  
  # MIDI packs
  if [[ "$name" =~ \.MiDi|MIDI|Toontrack ]]; then
    echo "midi-packs"
    return
  fi
  
  # Tutorials
  if [[ "$name" =~ Groove3|TUTORIAL ]]; then
    echo "tutorials"
    return
  fi
  
  # Default: uncategorized
  echo "uncategorized"
}

# Create folder structure
create_folders() {
  log_info "Creating music production folder structure..."
  
  local folders=(
    "daw-software"
    "plugins/synthesizers"
    "plugins/effects"
    "plugins/mixing-mastering"
    "sample-packs/jungle-dnb"
    "sample-packs/elektron-rytm"
    "sample-packs/drums"
    "sample-packs/other"
    "presets/serum"
    "presets/fabfilter"
    "presets/kick"
    "presets/vintage-synths"
    "presets/other"
    "ableton-racks"
    "midi-packs"
    "tutorials"
    "uncategorized"
  )
  
  if [[ "$DRY_RUN" == false ]]; then
    # Check if we can SSH to create folders directly
    if ssh -q -o ConnectTimeout=2 "${QBIT_HOST}" exit 2>/dev/null; then
      log_debug "Using SSH to create folders on ${QBIT_HOST}"
      for folder in "${folders[@]}"; do
        local full_path="${MUSIC_PROD_BASE}/${folder}"
        ssh "${QBIT_HOST}" "mkdir -p '${full_path}' && chown media:media '${full_path}' && chmod 775 '${full_path}'" 2>/dev/null || \
          log_warning "Failed to create ${folder} (will be created by qBittorrent when moving)"
        log_success "Created: ${folder}"
      done
    else
      log_warning "SSH not available - folders will be created by clients when moving torrents"
    fi
  else
    # Dry run - just list what would be created
    for folder in "${folders[@]}"; do
      log_info "[DRY RUN] Would create: ${folder}"
    done
  fi
}

# qBittorrent functions
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

qbit_move_torrent() {
  local hash="$1"
  local new_location="$2"
  local api_url="http://${QBIT_HOST}:${QBIT_PORT}/api/v2"
  
  # Login
  local cookie_jar=$(mktemp)
  if [[ -n "$QBIT_USER" && -n "$QBIT_PASS" ]]; then
    curl -s -c "$cookie_jar" --data "username=${QBIT_USER}&password=${QBIT_PASS}" \
      "${api_url}/auth/login" > /dev/null
  fi
  
  # Set location
  curl -s -b "$cookie_jar" --data "hashes=${hash}&location=${new_location}" \
    "${api_url}/torrents/setLocation"
  
  rm -f "$cookie_jar"
}

# Transmission functions (use RPC API directly)
trans_get_torrents() {
  log_debug "Connecting to Transmission RPC at ${TRANS_HOST}:${TRANS_PORT}"
  
  local api_url="http://${TRANS_HOST}:${TRANS_PORT}/transmission/rpc"
  
  # Get session ID (required for CSRF protection)
  local session_id=$(curl -s -I --anyauth -u "${TRANS_USER}:${TRANS_PASS}" "${api_url}" | \
    grep -i "X-Transmission-Session-Id:" | cut -d' ' -f2 | tr -d '\r\n')
  
  log_debug "Session ID: ${session_id}"
  
  # Get all torrents
  local response=$(curl -s --anyauth -u "${TRANS_USER}:${TRANS_PASS}" \
    -H "X-Transmission-Session-Id: ${session_id}" \
    -d '{"method":"torrent-get","arguments":{"fields":["id","name","downloadDir"]}}' \
    "${api_url}")
  
  log_debug "Transmission response: ${response}"
  
  # Filter for music production torrents in storage path
  echo "$response" | jq -r '.arguments.torrents[] | 
    select(.downloadDir | startswith("'${STORAGE_PATH}'")) |
    select(.name | test("Serum|Melodyne|FabFilter|Elektron|Jungle|Toontrack|Ableton|KICK|Sample|Preset|MIDI|MiDi|Tutorial|Groove3|DX7|TX81Z|JUP-8|Goodhertz|AudioThing|Aphex"; "i")) |
    "\(.id)|\(.name)|\(.downloadDir)"'
}

trans_move_torrent() {
  local id="$1"
  local new_location="$2"
  
  log_debug "Moving Transmission torrent ${id} to ${new_location}"
  
  local api_url="http://${TRANS_HOST}:${TRANS_PORT}/transmission/rpc"
  
  # Get session ID
  local session_id=$(curl -s -I --anyauth -u "${TRANS_USER}:${TRANS_PASS}" "${api_url}" | \
    grep -i "X-Transmission-Session-Id:" | cut -d' ' -f2 | tr -d '\r\n')
  
  # Move torrent
  curl -s --anyauth -u "${TRANS_USER}:${TRANS_PASS}" \
    -H "X-Transmission-Session-Id: ${session_id}" \
    -d '{"method":"torrent-set-location","arguments":{"ids":['${id}'],"location":"'${new_location}'","move":true}}' \
    "${api_url}" > /dev/null
}

# Process torrents for a client
process_client() {
  local client="$1"
  log_info "Processing ${client} torrents..."
  
  local count=0
  local moved=0
  
  if [[ "$client" == "qbittorrent" ]]; then
    log_debug "Calling qbit_get_torrents..."
    local torrents_output
    # Don't capture stderr - let debug messages go to terminal
    torrents_output=$(qbit_get_torrents)
    local get_result=$?
    
    log_debug "Get result: ${get_result}"
    log_debug "Output length: ${#torrents_output} bytes"
    log_debug "Output lines: $(echo "$torrents_output" | wc -l | tr -d ' ')"
    
    if [[ $get_result -ne 0 ]]; then
      log_error "Failed to get torrents from qBittorrent"
      return 1
    fi
    
    if [[ -z "$torrents_output" ]]; then
      log_warning "No torrents found"
      return 0
    fi
    
    log_debug "Processing torrent list..."
    
    # Write to temp file and read from it (more reliable than heredoc)
    local temp_file=$(mktemp)
    echo "$torrents_output" > "$temp_file"
    log_debug "Wrote output to temp file: $temp_file"
    log_debug "Temp file line count: $(wc -l < "$temp_file")"
    
    log_debug "Starting while loop..."
    while IFS='|' read -r hash name path; do
      log_debug "Read line: hash='$hash' name='$name'"
      
      # Skip empty lines
      if [[ -z "$hash" ]]; then
        log_debug "Skipping empty hash"
        continue
      fi
      
      count=$((count + 1))
      category=$(detect_category "$name")
      new_path="${MUSIC_PROD_BASE}/${category}"
      
      log_info "[${count}] ${name}"
      log_info "    Category: ${category}"
      log_info "    Current: ${path}"
      log_info "    New: ${new_path}"
      
      if [[ "$DRY_RUN" == false ]]; then
        qbit_move_torrent "$hash" "$new_path"
        log_success "    ✓ Moved"
        moved=$((moved + 1))
      else
        log_warning "    [DRY RUN] Would move"
      fi
      echo ""
    done < "$temp_file"
    
    rm -f "$temp_file"
  elif [[ "$client" == "transmission" ]]; then
    while IFS='|' read -r id name path; do
      count=$((count + 1))
      category=$(detect_category "$name")
      new_path="${MUSIC_PROD_BASE}/${category}"
      
      log_info "[${count}] ${name}"
      log_info "    Category: ${category}"
      log_info "    Current: ${path}"
      log_info "    New: ${new_path}"
      
      if [[ "$DRY_RUN" == false ]]; then
        trans_move_torrent "$id" "$new_path"
        log_success "    ✓ Moved"
        moved=$((moved + 1))
      else
        log_warning "    [DRY RUN] Would move"
      fi
      echo ""
    done < <(trans_get_torrents)
  fi
  
  log_info "${client}: Processed ${count} torrents, moved ${moved}"
}

# Main execution
main() {
  log_info "Music Production Torrent Organizer"
  log_info "===================================="
  echo ""
  
  if [[ "$DRY_RUN" == true ]]; then
    log_warning "DRY RUN MODE - No changes will be made"
    echo ""
  fi
  
  # Create folder structure
  create_folders
  echo ""
  
  # Process clients
  case "$CLIENT" in
    qbittorrent)
      process_client "qbittorrent"
      ;;
    transmission)
      process_client "transmission"
      ;;
    both)
      process_client "qbittorrent"
      echo ""
      process_client "transmission"
      ;;
    *)
      log_error "Invalid client: $CLIENT (must be qbittorrent, transmission, or both)"
      exit 1
      ;;
  esac
  
  echo ""
  log_success "Organization complete!"
  
  if [[ "$DRY_RUN" == true ]]; then
    log_info "Run without --dry-run to apply changes"
  fi
}

main
