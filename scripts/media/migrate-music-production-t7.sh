#!/usr/bin/env bash
#
# migrate-music-production-t7.sh
#
# Move Mac Ableton library to T7 + copy substantial working content from NAS
# This creates your portable working library
#
# Usage: ./migrate-music-production-t7.sh [--dry-run]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Paths
NAS_ROOT="/Volumes/storage/torrents"
NAS_MUSIC_PROD="${NAS_ROOT}/music-production"
MAC_ABLETON="/Users/lewisflude/Music/Ableton"
T7_ROOT="/Volumes/Samsung Drive"
T7_ABLETON="${T7_ROOT}/Ableton"

# Flags
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Helper functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Checks
if [[ ! -d "$T7_ROOT" ]]; then
  log_error "T7 not mounted at $T7_ROOT"
  log_info "Please connect your Samsung T7 drive"
  exit 1
fi

if [[ ! -d "$NAS_ROOT" ]]; then
  log_error "NAS not mounted at $NAS_ROOT"
  log_info "Please mount /Volumes/storage first"
  exit 1
fi

if [[ ! -d "$MAC_ABLETON" ]]; then
  log_error "Mac Ableton folder not found at $MAC_ABLETON"
  exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
  log_warning "DRY RUN MODE - No changes will be made"
  echo ""
fi

log_info "Migrating Mac → T7 + NAS → T7"
log_info "==============================="
echo ""

# ==========================================
# PHASE 1: MOVE MAC ABLETON → T7
# ==========================================

log_info "📁 PHASE 1: Moving Mac Ableton Library to T7"
echo ""

mac_size=$(du -sh "$MAC_ABLETON" | awk '{print $1}')
log_info "Source: $MAC_ABLETON ($mac_size)"
log_info "Destination: $T7_ABLETON"
echo ""

if [[ -d "$T7_ABLETON" ]]; then
  log_warning "T7 Ableton folder already exists!"
  log_info "Found at: $T7_ABLETON"
  read -p "Delete existing and replace? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_error "Aborted by user"
    exit 1
  fi
  if [[ "$DRY_RUN" == false ]]; then
    log_info "Removing old T7 Ableton folder..."
    rm -rf "$T7_ABLETON"
    log_success "Removed"
  else
    log_warning "[DRY RUN] Would remove $T7_ABLETON"
  fi
fi

log_info "Moving Mac Ableton → T7 (this may take 5-10 minutes)..."
if [[ "$DRY_RUN" == false ]]; then
  # Use rsync for progress and reliability
  rsync -ah --progress "$MAC_ABLETON/" "$T7_ABLETON/" && \
    log_success "✓ Moved 44GB to T7" || {
      log_error "Move failed!"
      exit 1
    }
else
  log_warning "[DRY RUN] Would move $MAC_ABLETON → $T7_ABLETON"
fi

echo ""

# ==========================================
# PHASE 2: COPY NAS → T7 (NEW CONTENT)
# ==========================================

log_info "📁 PHASE 2: Copying New Content from NAS to T7"
echo ""

copy_to_t7() {
  local src="$1"
  local dest="$2"
  local size="${3:-unknown}"

  if [[ ! -e "$src" ]]; then
    log_warning "Source not found: $src"
    return 1
  fi

  log_info "📦 $(basename "$src") ($size)"
  log_info "   $src"
  log_info "   → $dest"

  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$(dirname "$dest")"
    if rsync -ah --progress "$src/" "$dest/"; then
      log_success "   ✓ Copied"
    else
      log_error "   ✗ Failed"
      return 1
    fi
  else
    log_warning "   [DRY RUN] Would copy"
  fi
  echo ""
}

# XLNTSOUND Bass Pack
log_info "🎵 Bass & Projects"
echo ""

copy_to_t7 \
  "${NAS_ROOT}/XLNTSOUND.Quest.For.Bass.Vol.2.WAV.Serum.Preset.Ableton.Project.Files" \
  "${T7_ABLETON}/User Library/Sample Library/Bass/XLNTSOUND Quest For Bass Vol.2" \
  "1.5GB"

# Analog Rytm Samples
log_info "🥁 Analog Rytm Sound Packs"
echo ""

if [[ -d "${NAS_MUSIC_PROD}/analog-rytm" ]]; then
  for pack in "${NAS_MUSIC_PROD}"/analog-rytm/*; do
    pack_name=$(basename "$pack")
    copy_to_t7 \
      "$pack" \
      "${T7_ABLETON}/User Library/Sample Library/Analog-Rytm/${pack_name}" \
      "varies"
  done
fi

# Root Elektron pack
if [[ -d "${NAS_ROOT}/Elektron.Analog.Rythm.drum.machine.Samples.WAV.SYX" ]]; then
  copy_to_t7 \
    "${NAS_ROOT}/Elektron.Analog.Rythm.drum.machine.Samples.WAV.SYX" \
    "${T7_ABLETON}/User Library/Sample Library/Analog-Rytm/Elektron Analog Rytm Samples" \
    "20MB"
fi

# Tutorials
log_info "🎓 Video Tutorials"
echo ""

copy_to_t7 \
  "${NAS_ROOT}/Groove3.Ableton.Live.12.Creative.Drum.Production.TUTORIAL" \
  "${T7_ABLETON}/User Library/Tutorials/Groove3 Creative Drum Production" \
  "265MB"

if [[ -d "${NAS_MUSIC_PROD}/midi/Groove3.Ableton.Live.12.Using.MIDI.Effects.for.Song.Ideas.TUTORIAL" ]]; then
  copy_to_t7 \
    "${NAS_MUSIC_PROD}/midi/Groove3.Ableton.Live.12.Using.MIDI.Effects.for.Song.Ideas.TUTORIAL" \
    "${T7_ABLETON}/User Library/Tutorials/Groove3 MIDI Effects for Song Ideas" \
    "193MB"
fi

# ==========================================
# PHASE 3: CREATE PROJECTS FOLDER
# ==========================================

log_info "📁 PHASE 3: Setting up Projects folder"
echo ""

if [[ "$DRY_RUN" == false ]]; then
  mkdir -p "${T7_ROOT}/Projects/Active"
  mkdir -p "${T7_ROOT}/Projects/Archive"
  mkdir -p "${T7_ROOT}/Projects/Samples"
  log_success "✓ Created Projects folders on T7"
else
  log_warning "[DRY RUN] Would create Projects folders"
fi

echo ""

# ==========================================
# SUMMARY
# ==========================================

echo ""
log_info "========================================"
log_success "Migration to T7 Complete!"
log_info "========================================"
echo ""

if [[ "$DRY_RUN" == false ]]; then
  t7_used=$(du -sh "$T7_ABLETON" 2>/dev/null | awk '{print $1}' || echo "~46GB")
  log_info "T7 Ableton Library: $t7_used"
  log_info "T7 Projects folder created: ${T7_ROOT}/Projects/"
  echo ""
  log_info "Next steps:"
  log_info "1. Update Ableton library paths (see update-ableton-library-paths.sh)"
  log_info "2. Verify T7 library loads in Ableton"
  log_info "3. Delete Mac Ableton folder to free 43GB: rm -rf \"$MAC_ABLETON\""
  log_warning "   ⚠️  ONLY delete Mac folder AFTER verifying T7 library works!"
else
  log_warning "This was a DRY RUN. Run without --dry-run to apply changes."
fi

echo ""
