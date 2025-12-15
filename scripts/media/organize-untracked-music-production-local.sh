#!/usr/bin/env bash
#
# organize-untracked-music-production-local.sh
#
# Organize music production files directly via SMB mount
# (No SSH required)
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
STORAGE_PATH="/mnt/storage/torrents"
MUSIC_PROD_BASE="${STORAGE_PATH}/music-production"

# Dry run flag
DRY_RUN=true

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --run)
      DRY_RUN=false
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --run              Actually move files (default is dry-run)"
      echo "  --help, -h         Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

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

# File to category mapping
declare -A FILE_MAP=(
  # FabFilter Presets
  ["Andi.Vax.FabFilter.PRO-Q.4.222.Presets.FABFILTER.PRO-Q.4.PRESETS"]="presets/fabfilter"
  ["Andi.Vax.FabFilter.PRO-R.2.141.Presets.FABFILTER.PRO-R.2.PRESETS"]="presets/fabfilter"

  # Plugins
  ["Avid.Aphex.Bundle.v18.8.0-R2R"]="plugins/effects"
  ["Celemony.Melodyne.5.Studio.v5.4.2.006.U2B.Mac-MORiA"]="plugins/mixing-mastering"
  ["Leapwing.Audio.LimitOne.v1.0.1.Incl.Patched.and.Keygen-R2R"]="plugins/mixing-mastering"

  # Jungle/DnB Sample Packs
  ["Breakbeats Collection"]="sample-packs/jungle-dnb"
  ["Deviant.Audio.Jungle.Kit.v2.0.MULTiFORMAT-DECiBEL"]="sample-packs/jungle-dnb"
  ["Deviant.Audio.OG.Jungle.Vol.1.Sample.Pack.WAV.MiDi.RX2"]="sample-packs/jungle-dnb"
  ["Element.One.Heavyweight.Jungle.WAV"]="sample-packs/jungle-dnb"
  ["LoopMasters.Original.Jungle.Breaks"]="sample-packs/jungle-dnb"
  ["Nebula.Samples.100.Amen.Breaks.By.Veak.WAV"]="sample-packs/jungle-dnb"
  ["Onezero.Samples.Modern.Jungle.Rollers.WAV.XFER.RECORDS.SERUM"]="sample-packs/jungle-dnb"
  ["THICK.Sounds.Big.Bang.Jungle.by.Veak.WAV"]="sample-packs/jungle-dnb"
  ["Zero-G.Jungle.Warfare.Vol.1.DLP.WAV.ACID-ASSiGN"]="sample-packs/jungle-dnb"
  ["Zero-G.Jungle.Warfare.Vol.2.DLP.WAV.ACID-ASSiGN"]="sample-packs/jungle-dnb"

  # Elektron
  ["Elektron.Analog.Rythm.drum.machine.Samples.WAV.SYX"]="sample-packs/elektron-rytm"

  # Vintage Synth Presets
  ["Matt.Curry.DX7.CARTRIDGE.2.ANALOG.LAB.BANK"]="presets/vintage-synths"
  ["Matt.Curry.DX7.CARTRIDGE.ANALOG.LAB.BANK"]="presets/vintage-synths"
  ["midierror.Yamaha.TX81Z.Editor.[Max4Live]"]="presets/vintage-synths"
  ["norCTrack.Yamaha.TX81Z.NKI.KONTAKT"]="presets/vintage-synths"

  # Serum/Bass Presets
  ["XLNTSOUND.Quest.For.Bass.Vol.2.WAV.Serum.Preset.Ableton.Project.Files"]="presets/serum"

  # Superior Drummer
  ["SL-Toontrack-SuperiorDrummer3_SDX_Part3"]="sample-packs/drums"
  ["SL-Toontrack-SuperiorDrummer3_SDX_Part4"]="sample-packs/drums"
  ["Toontrack.Superior.Drummer.3.Factory.Content.PART.5.WIN.MAC"]="sample-packs/drums"
  ["SL-SuperiorDrummer3_SDX_Part1.zip"]="sample-packs/drums"
  ["SL-SuperiorDrummer3_SDX_Part2.zip"]="sample-packs/drums"

  # MIDI Packs
  ["Toontrack.Laid-Back.Grooves.MIDI"]="midi-packs"
  ["Toontrack.Salsa.Grooves.MIDI"]="midi-packs"

  # Tutorials
  ["Groove3.Ableton.Live.12.Creative.Drum.Production.TUTORIAL"]="tutorials"

  # Book (uncategorized)
  ["Aphex.Twins.Selected.Ambient.Works.Volume.II.33.1x3.by.Marc.Weidenbaum.EPUB"]="uncategorized"
)

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Music Production Manual File Organization (Local)        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if mount is accessible
if [[ ! -d "$STORAGE_PATH" ]]; then
  log_error "Storage path not accessible: $STORAGE_PATH"
  log_info "Make sure /mnt/storage is mounted"
  exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
  log_warning "DRY RUN MODE - No files will be moved"
  log_info "Run with --run to actually move files"
  echo ""
fi

# Create categories list
declare -A categories
for category in "${FILE_MAP[@]}"; do
  categories["$category"]=1
done

# Create folder structure
log_info "Ensuring folder structure exists..."
if [[ "$DRY_RUN" == false ]]; then
  for category in "${!categories[@]}"; do
    mkdir -p "${MUSIC_PROD_BASE}/${category}" 2>/dev/null || true
  done
  log_success "Folder structure created"
else
  log_info "Would create folder structure for ${#categories[@]} categories"
fi
echo ""

# Move files
log_info "Processing ${#FILE_MAP[@]} files..."
echo ""

moved_count=0
skipped_count=0
error_count=0

for file in "${!FILE_MAP[@]}"; do
  category="${FILE_MAP[$file]}"
  source_path="${STORAGE_PATH}/${file}"
  dest_path="${MUSIC_PROD_BASE}/${category}/${file}"

  echo -e "${BLUE}→${NC} ${file}"
  echo "  Category: ${category}"
  echo "  Source: ${source_path}"
  echo "  Dest: ${dest_path}"

  if [[ "$DRY_RUN" == false ]]; then
    # Check if source exists
    if [[ ! -e "$source_path" ]]; then
      log_warning "  ⚠ Source doesn't exist (already moved or deleted?)"
      skipped_count=$((skipped_count + 1))
      echo ""
      continue
    fi

    # Check if destination already exists
    if [[ -e "$dest_path" ]]; then
      log_warning "  ⚠ Destination already exists (skipping)"
      skipped_count=$((skipped_count + 1))
      echo ""
      continue
    fi

    # Move the file
    if mv "$source_path" "$dest_path" 2>/dev/null; then
      log_success "  ✓ Moved"
      moved_count=$((moved_count + 1))
    else
      log_error "  ✗ Failed to move"
      error_count=$((error_count + 1))
    fi
  else
    # Dry run - check if file exists
    if [[ -e "$source_path" ]]; then
      log_info "  [DRY RUN] Would move"
    else
      log_warning "  [DRY RUN] Source doesn't exist"
      skipped_count=$((skipped_count + 1))
    fi
  fi

  echo ""
done

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Summary                                                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
log_info "Total files: ${#FILE_MAP[@]}"

if [[ "$DRY_RUN" == false ]]; then
  log_success "Moved: ${moved_count}"
  [[ $skipped_count -gt 0 ]] && log_warning "Skipped: ${skipped_count}"
  [[ $error_count -gt 0 ]] && log_error "Errors: ${error_count}"
else
  log_info "Run with --run to actually move files"
fi

echo ""

if [[ "$DRY_RUN" == false && $moved_count -gt 0 ]]; then
  log_success "Organization complete! 🎵"
fi
