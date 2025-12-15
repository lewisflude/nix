#!/usr/bin/env bash
#
# migrate-music-production-mac.sh
#
# Copy essential music production files from NAS to Mac internal SSD
# These are small files that prevent Ableton errors when T7 is unplugged
#
# Usage: ./migrate-music-production-mac.sh [--dry-run]

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
MAC_ABLETON="/Users/lewisflude/Music/Ableton/User Library"
MAC_INSTALLERS="/Users/lewisflude/Music/Plugin Installers"
MAC_DOCS="/Users/lewisflude/Documents/Music Production"

# Flags
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Helper functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Check NAS is mounted
if [[ ! -d "$NAS_ROOT" ]]; then
  log_error "NAS not mounted at $NAS_ROOT"
  log_info "Please mount /Volumes/storage first"
  exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
  log_warning "DRY RUN MODE - No changes will be made"
  echo ""
fi

log_info "Copying essentials from NAS → Mac Internal SSD"
log_info "================================================"
echo ""

# Track totals
total_size=0
total_files=0

copy_item() {
  local src="$1"
  local dest="$2"
  local size="${3:-unknown}"

  if [[ ! -e "$src" ]]; then
    log_warning "Source not found: $src"
    return 1
  fi

  log_info "📦 $src"
  log_info "   → $dest ($size)"

  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$(dirname "$dest")"
    if cp -R "$src" "$dest"; then
      log_success "   ✓ Copied"
      ((total_files++))
    else
      log_error "   ✗ Failed"
      return 1
    fi
  else
    log_warning "   [DRY RUN] Would copy"
  fi
  echo ""
}

# ==========================================
# PRESETS
# ==========================================

log_info "📁 PRESETS"
echo ""

# FabFilter
copy_item \
  "${NAS_ROOT}/Andi.Vax.FabFilter.PRO-Q.4.222.Presets.FABFILTER.PRO-Q.4.PRESETS" \
  "${MAC_ABLETON}/Presets/Audio Effects/FabFilter/PRO-Q 4/" \
  "3.6MB"

copy_item \
  "${NAS_ROOT}/Andi.Vax.FabFilter.PRO-R.2.141.Presets.FABFILTER.PRO-R.2.PRESETS" \
  "${MAC_ABLETON}/Presets/Audio Effects/FabFilter/PRO-R 2/" \
  "515KB"

# KICK 3
for kick_pack in "${NAS_MUSIC_PROD}"/kick-3-presets/*; do
  pack_name=$(basename "$kick_pack")
  copy_item \
    "$kick_pack" \
    "${MAC_ABLETON}/Presets/Instruments/KICK-3/${pack_name}/" \
    "varies"
done

# Serum
copy_item \
  "${NAS_MUSIC_PROD}/midi/Loopsy.RAVE.Vol.3.Serum.Presets.MiDi" \
  "${MAC_ABLETON}/Presets/Instruments/Serum/Loopsy RAVE Vol.3/" \
  "23MB"

copy_item \
  "${NAS_MUSIC_PROD}/midi/Teknovault.Serum.2.Hard.Techno.Presets.Vol.1.Serum.2.Presets.MiDi" \
  "${MAC_ABLETON}/Presets/Instruments/Serum/Teknovault Hard Techno Vol.1/" \
  "54MB"

# Extract Serum presets from XLNTSOUND (if exists)
if [[ -d "${NAS_ROOT}/XLNTSOUND.Quest.For.Bass.Vol.2.WAV.Serum.Preset.Ableton.Project.Files" ]]; then
  log_info "Extracting Serum presets from XLNTSOUND pack..."
  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "${MAC_ABLETON}/Presets/Instruments/Serum/XLNTSOUND Quest Bass/"
    find "${NAS_ROOT}/XLNTSOUND.Quest.For.Bass.Vol.2.WAV.Serum.Preset.Ableton.Project.Files" \
      -name "*.fxp" -o -name "*.fxb" -o -name "*.syx" 2>/dev/null | \
      while read -r preset; do
        cp "$preset" "${MAC_ABLETON}/Presets/Instruments/Serum/XLNTSOUND Quest Bass/" || true
      done
    log_success "   ✓ Extracted Serum presets"
  else
    log_warning "   [DRY RUN] Would extract Serum presets"
  fi
  echo ""
fi

# JUP-8000
copy_item \
  "${NAS_MUSIC_PROD}/midi/Aiyn.Zahev.Sounds.JUP-8000.Tranceform.Arturia.JUP-8000.Presets.MiDi" \
  "${MAC_ABLETON}/Presets/Instruments/JUP-8000/Tranceform/" \
  "12MB"

# ==========================================
# ABLETON RACKS
# ==========================================

log_info "📁 ABLETON RACKS"
echo ""

for rack in "${NAS_MUSIC_PROD}"/ableton-racks/*.ABLETON.RACK; do
  rack_name=$(basename "$rack")
  copy_item \
    "$rack" \
    "${MAC_ABLETON}/Presets/Audio Effects/Ableton/${rack_name}/" \
    "~50KB"
done

# ==========================================
# MIDI PACKS
# ==========================================

log_info "📁 MIDI PACKS"
echo ""

# Toontrack Drums
copy_item \
  "${NAS_ROOT}/Toontrack.Laid-Back.Grooves.MIDI" \
  "${MAC_ABLETON}/Clips/MIDI/Drums/Toontrack/Laid-Back Grooves/" \
  "2.1MB"

copy_item \
  "${NAS_ROOT}/Toontrack.Salsa.Grooves.MIDI" \
  "${MAC_ABLETON}/Clips/MIDI/Drums/Toontrack/Salsa Grooves/" \
  "2.4MB"

toontrack_drums=(
  "Toontrack.Alternative.Dance.MiDi"
  "Toontrack.Back.to.the.Roots.MiDi"
  "Toontrack.Loop.Layers.MIDI"
  "Toontrack.Modern.Gospel.Grooves.MIDI"
  "Toontrack.Progressive.Patterns.MIDI"
  "Toontrack.The.Pop.Playbook.MiDi"
)

for pack in "${toontrack_drums[@]}"; do
  if [[ -d "${NAS_MUSIC_PROD}/midi/$pack" ]]; then
    pack_name=$(echo "$pack" | sed 's/Toontrack\.//' | sed 's/\.MiDi//' | sed 's/\.MIDI//' | sed 's/\./ /g')
    copy_item \
      "${NAS_MUSIC_PROD}/midi/$pack" \
      "${MAC_ABLETON}/Clips/MIDI/Drums/Toontrack/${pack_name}/" \
      "varies"
  fi
done

# Toontrack Keys
toontrack_keys=(
  "Toontrack.Acoustic.Songwriter.2.EZkeys.MIDI.v1.0.0.WIN"
  "Toontrack.Atmospheric.EZkeys.MIDI.v1.0.0.WIN"
  "Toontrack.Folk.Rock.EZkeys.MIDI.v1.0.0.WIN"
  "Toontrack.Movie.Scores.Adventure.EZkeys.MIDI.v1.0.0.OSX"
)

for pack in "${toontrack_keys[@]}"; do
  if [[ -d "${NAS_MUSIC_PROD}/midi/$pack" ]]; then
    pack_name=$(echo "$pack" | sed 's/Toontrack\.//' | sed 's/\.EZkeys.*$//' | sed 's/\./ /g')
    copy_item \
      "${NAS_MUSIC_PROD}/midi/$pack" \
      "${MAC_ABLETON}/Clips/MIDI/Keys/Toontrack/${pack_name}/" \
      "varies"
  fi
done

# GetGood Drums
copy_item \
  "${NAS_MUSIC_PROD}/midi/GetGood.Drums.GGD.Crazy.Fills.Vol.1.Midi.Pack.MiDi" \
  "${MAC_ABLETON}/Clips/MIDI/Drums/GetGood/Crazy Fills Vol.1/" \
  "99KB"

# ==========================================
# PLUGIN INSTALLERS
# ==========================================

log_info "📁 PLUGIN INSTALLERS"
echo ""

copy_item \
  "${NAS_MUSIC_PROD}/macos/Xfer.Records.Serum.v2.0.23.macOS-V.R" \
  "${MAC_INSTALLERS}/macOS/Xfer Serum v2.0.23/" \
  "1.3GB"

copy_item \
  "${NAS_MUSIC_PROD}/macos/Goodhertz.All.Plugins.Bundle.v3.13.2.macOS" \
  "${MAC_INSTALLERS}/macOS/Goodhertz All Plugins v3.13.2/" \
  "417MB"

copy_item \
  "${NAS_ROOT}/Celemony.Melodyne.5.Studio.v5.4.2.006.U2B.Mac-MORiA" \
  "${MAC_INSTALLERS}/macOS/Celemony Melodyne 5 Studio v5.4.2/" \
  "98MB"

copy_item \
  "${NAS_MUSIC_PROD}/macos/AudioThing.Valve.Exciter.v1.5.1.MacOSX.Incl.Patched.and.Keygen-R2R" \
  "${MAC_INSTALLERS}/macOS/AudioThing Valve Exciter v1.5.1/" \
  "98MB"

copy_item \
  "${NAS_MUSIC_PROD}/macos/KORG.M1.Le.v2.0.0.macOS-R2R" \
  "${MAC_INSTALLERS}/macOS/KORG M1 Le v2.0.0/" \
  "31MB"

copy_item \
  "${NAS_ROOT}/Leapwing.Audio.LimitOne.v1.0.1.Incl.Patched.and.Keygen-R2R" \
  "${MAC_INSTALLERS}/macOS/Leapwing LimitOne v1.0.1/" \
  "7MB"

copy_item \
  "${NAS_ROOT}/Avid.Aphex.Bundle.v18.8.0-R2R" \
  "${MAC_INSTALLERS}/macOS/Avid Aphex Bundle v18.8.0/" \
  "2.4MB"

# ==========================================
# REFERENCE BOOKS
# ==========================================

log_info "📁 REFERENCE BOOKS"
echo ""

copy_item \
  "${NAS_ROOT}/Aphex.Twins.Selected.Ambient.Works.Volume.II.33.1x3.by.Marc.Weidenbaum.EPUB" \
  "${MAC_DOCS}/Books/Aphex Twin SAW Vol.II.epub" \
  "610KB"

# ==========================================
# SUMMARY
# ==========================================

echo ""
log_info "================================================"
log_success "Migration to Mac Internal Complete!"
log_info "================================================"
echo ""
log_info "Files copied: $total_files"
log_info "Estimated size: ~2.7GB"
echo ""
log_info "Next steps:"
log_info "1. Run: ./migrate-music-production-t7.sh"
log_info "2. Update Ableton library paths"
log_info "3. Delete old Mac Ableton folder"
echo ""

if [[ "$DRY_RUN" == true ]]; then
  log_warning "This was a DRY RUN. Run without --dry-run to apply changes."
fi
