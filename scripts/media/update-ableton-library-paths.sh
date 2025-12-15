#!/usr/bin/env bash
#
# update-ableton-library-paths.sh
#
# Updates Ableton Live's library configuration to use:
#   Primary: T7 Samsung Drive
#   Secondary: NAS music-production folder
#   Tertiary: NAS root torrents folder
#
# Usage: ./update-ableton-library-paths.sh [--dry-run]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
ABLETON_PREFS="$HOME/Library/Preferences/Ableton"
LIBRARY_CFG_PATTERN="Live */Library.cfg"
T7_ABLETON="/Volumes/Samsung Drive/Ableton"
NAS_MUSIC_PROD="/Volumes/storage/torrents/music-production"
NAS_ROOT="/Volumes/storage/torrents"

# Flags
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Helper functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

if [[ "$DRY_RUN" == true ]]; then
  log_warning "DRY RUN MODE - No changes will be made"
  echo ""
fi

log_info "Updating Ableton Live Library Paths"
log_info "===================================="
echo ""

# Find all Ableton versions
library_configs=()
while IFS= read -r -d '' config; do
  library_configs+=("$config")
done < <(find "$ABLETON_PREFS" -name "Library.cfg" -print0 2>/dev/null)

if [[ ${#library_configs[@]} -eq 0 ]]; then
  log_error "No Ableton Live installations found in $ABLETON_PREFS"
  exit 1
fi

log_info "Found ${#library_configs[@]} Ableton installation(s):"
for cfg in "${library_configs[@]}"; do
  version=$(echo "$cfg" | sed 's|.*Live \([^/]*\)/.*|\1|')
  log_info "  - Live $version"
done
echo ""

# Process each config
for library_cfg in "${library_configs[@]}"; do
  version=$(echo "$library_cfg" | sed 's|.*Live \([^/]*\)/.*|\1|')
  backup="${library_cfg}.backup.$(date +%Y%m%d_%H%M%S)"

  log_info "📝 Updating Live $version"
  echo ""

  # Backup original
  if [[ "$DRY_RUN" == false ]]; then
    cp "$library_cfg" "$backup"
    log_success "  ✓ Backed up to: ${backup##*/}"
  else
    log_warning "  [DRY RUN] Would backup to: ${backup##*/}"
  fi

  # Read current config
  current_path=$(grep -o '<ProjectPath Value="[^"]*"' "$library_cfg" | sed 's/.*Value="\(.*\)"/\1/' | head -1)
  log_info "  Current library path: $current_path"

  # Update User Library path to T7
  log_info "  Updating to T7: $T7_ABLETON"

  if [[ "$DRY_RUN" == false ]]; then
    # Update the ProjectPath to T7
    sed -i '' "s|<ProjectPath Value=\"${current_path}\"|<ProjectPath Value=\"${T7_ABLETON}\"|g" "$library_cfg"
    log_success "  ✓ Updated primary library path"
  else
    log_warning "  [DRY RUN] Would update primary library path"
  fi

  echo ""
done

# Instructions for adding secondary paths
echo ""
log_info "========================================"
log_success "Library Configuration Updated!"
log_info "========================================"
echo ""

cat <<EOF
${BLUE}ℹ️  NEXT STEPS IN ABLETON:${NC}

1. ${GREEN}Launch Ableton Live${NC}

2. ${GREEN}Add NAS as Secondary Library Locations:${NC}
   Go to: ${YELLOW}Preferences → Library → Folders to Index${NC}

   Click ${YELLOW}"+ Add Folder"${NC} and add these paths:

   ${BLUE}a)${NC} ${YELLOW}$NAS_MUSIC_PROD${NC}
      (Organized music production samples)

   ${BLUE}b)${NC} ${YELLOW}$NAS_ROOT${NC}
      (Legacy samples in root)

3. ${GREEN}Verify Library Loads:${NC}
   - Check that Browser shows all your samples
   - Test loading some presets
   - Open a project from T7

4. ${YELLOW}⚠️  When NAS is offline:${NC}
   - T7 samples will work
   - Mac-local presets/MIDI will work
   - NAS samples will show as "missing" (expected)

${GREEN}✓${NC} Your library is now optimized for:
  • Portable production (T7)
  • Deep library when home (NAS)
  • Essential presets always available (Mac)

${YELLOW}NOTE:${NC} Ableton doesn't support adding secondary libraries via XML.
      You must add them manually in Preferences.
EOF

echo ""

if [[ "$DRY_RUN" == true ]]; then
  log_warning "This was a DRY RUN. Run without --dry-run to apply changes."
fi
