#!/usr/bin/env bash
#
# reorganize-midi-functional.sh
#
# Transform MIDI clips from vendor-centric to genre/function-centric organization
#
# Usage: ./reorganize-midi-functional.sh [--dry-run]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Paths
MIDI_ROOT="/Volumes/Samsung Drive/Ableton/Clips/MIDI"
BACKUP_DIR="/Volumes/Samsung Drive/Ableton/Backups/MIDI-$(date +%Y%m%d-%H%M%S)"

# Flags
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Helper functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_section() { echo -e "\n${MAGENTA}=== $* ===${NC}\n"; }

# Check prerequisites
if [[ ! -d "$MIDI_ROOT" ]]; then
  log_error "MIDI root not found: $MIDI_ROOT"
  log_info "Please ensure Samsung Drive is connected"
  exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
  log_warning "DRY RUN MODE - No changes will be made"
  echo ""
fi

log_section "MIDI Clips Reorganization - Functional Workflow"

log_info "Transforming from vendor-centric to genre/function organization"
echo ""

# Confirmation
if [[ "$DRY_RUN" == false ]]; then
  read -p "Continue with MIDI reorganization? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_error "Aborted by user"
    exit 1
  fi
fi

# ==========================================
# PHASE 1: BACKUP
# ==========================================

log_section "Phase 1: Backup"

if [[ "$DRY_RUN" == false ]]; then
  log_info "Creating backup at: $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  rsync -ah --progress "$MIDI_ROOT/" "$BACKUP_DIR/"
  log_success "✓ Backup complete"
else
  log_warning "[DRY RUN] Would create backup"
fi

# ==========================================
# PHASE 2: CREATE FUNCTIONAL STRUCTURE
# ==========================================

log_section "Phase 2: Creating Functional Structure"

create_dir() {
  local dir="$1"
  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$dir"
  else
    log_info "[DRY RUN] Would create: $dir"
  fi
}

log_info "Creating genre/function directory structure..."

# 01 - Drums
create_dir "$MIDI_ROOT/01-Drums/_By-Genre/Techno"/{Grooves,Fills,Transitions}
create_dir "$MIDI_ROOT/01-Drums/_By-Genre/House"/{4x4-Grooves,Breakbeats,Percussion-Layers}
create_dir "$MIDI_ROOT/01-Drums/_By-Genre/DnB"/{Two-Step,Full-Breaks}
create_dir "$MIDI_ROOT/01-Drums/_By-Style"/{Minimal,Complex,Syncopated}
create_dir "$MIDI_ROOT/01-Drums/_By-Tempo"/{120-125bpm,126-130bpm,174bpm}

# 02 - Keys
create_dir "$MIDI_ROOT/02-Keys/Chord-Progressions"/{Major,Minor,Modal}
create_dir "$MIDI_ROOT/02-Keys/Melodies"/{Lead-Lines,Hook-Ideas}
create_dir "$MIDI_ROOT/02-Keys/Arpeggios"

# 03 - Bass
create_dir "$MIDI_ROOT/03-Bass/Patterns"/{Rolling,Stepped}
create_dir "$MIDI_ROOT/03-Bass/One-Shots"

# Vendor reference
create_dir "$MIDI_ROOT/_By-Vendor"

log_success "✓ Functional structure created"

# ==========================================
# PHASE 3: MOVE VENDOR FOLDERS
# ==========================================

log_section "Phase 3: Organizing Vendor Reference"

if [[ "$DRY_RUN" == false ]]; then
  if [ -d "$MIDI_ROOT/Drums" ]; then
    log_info "Moving Drums/ to _By-Vendor/"
    mv "$MIDI_ROOT/Drums" "$MIDI_ROOT/_By-Vendor/"
  fi
  
  if [ -d "$MIDI_ROOT/Keys" ]; then
    log_info "Moving Keys/ to _By-Vendor/"
    mv "$MIDI_ROOT/Keys" "$MIDI_ROOT/_By-Vendor/"
  fi
  
  log_success "✓ Vendor folders organized"
else
  log_warning "[DRY RUN] Would move vendor folders"
fi

# Create vendor README
if [[ "$DRY_RUN" == false ]]; then
  cat > "$MIDI_ROOT/_By-Vendor/README.md" << 'EOF'
# MIDI Vendor Reference

Original vendor-organized MIDI clips preserved for reference.

## Primary Organization

Use the functional directories for workflow-based browsing:

- **01-Drums/_By-Genre/**: Drum patterns organized by genre (Techno, House, DnB)
- **02-Keys/**: Chord progressions, melodies, arpeggios
- **03-Bass/**: Bass patterns and one-shots

## Vendors

- **Toontrack/**: Drum grooves, keys MIDI packs
- **GetGood/**: Drum fills and patterns

Use functional folders for faster discovery during production.
EOF
  log_success "✓ Created vendor README"
fi

# ==========================================
# PHASE 4: CREATE CURATION GUIDE
# ==========================================

log_section "Phase 4: Creating Curation Guide"

if [[ "$DRY_RUN" == false ]]; then
  cat > "$MIDI_ROOT/README-CURATION.md" << 'EOF'
# MIDI Clips Curation Guide

Organize MIDI clips by **genre, tempo, and musical function** for faster discovery.

## Organization Strategy

### 01-Drums/

**By Genre:**
- Techno: Straight grooves, minimal hi-hat patterns
- House: 4x4 grooves, breakbeats, percussion layers
- DnB: Two-step, full breaks (174bpm)

**By Style:**
- Minimal: Simple, sparse patterns
- Complex: Polyrhythmic, layered
- Syncopated: Off-beat, swing

**By Tempo:**
- 120-125bpm: Deep house, minimal techno
- 126-130bpm: Peak-time techno, progressive house
- 174bpm: Drum & Bass

### 02-Keys/

**Chord Progressions:**
- Major: Uplifting, bright
- Minor: Dark, melancholic
- Modal: Dorian, Phrygian, etc.

**Melodies:**
- Lead-Lines: Single-note melodic sequences
- Hook-Ideas: Catchy melodic phrases

**Arpeggios:**
- Synth arps, pluck patterns

### 03-Bass/

**Patterns:**
- Rolling: Continuous basslines (DnB style)
- Stepped: Rhythmic, staccato patterns

**One-Shots:**
- Single bass notes for building patterns

## Curation Process

1. **Listen** to each MIDI clip
2. **Identify**:
   - Genre (Techno/House/DnB)
   - Tempo (120-130bpm/174bpm)
   - Style (Minimal/Complex)
   - Function (Groove/Fill/Transition)
3. **Copy** to appropriate functional folder
4. **Rename** with metadata: `[Techno-130bpm-Fill] Original-Name.mid`

## Example Workflow

```bash
# Find all Toontrack drum MIDI
find "_By-Vendor/Drums/Toontrack" -name "*.mid"

# Listen and categorize
# If it's a techno groove at 128bpm:
cp "groove.mid" "01-Drums/_By-Genre/Techno/Grooves/[128bpm] groove.mid"

# Also copy by tempo
cp "groove.mid" "01-Drums/_By-Tempo/126-130bpm/[Techno] groove.mid"
```

## Metadata Tagging

Use bracket prefixes for quick filtering:

- `[Techno-128bpm-Groove] pattern.mid`
- `[House-124bpm-Fill] fill.mid`
- `[DnB-174bpm-Break] break.mid`

## Time Investment

- **Initial**: 1-2 hours
- **Weekly**: 5 minutes for new clips
- **Benefits**: Find MIDI 10x faster, less flow interruption

## Quick Start

1. Start with Toontrack drum grooves (most useful)
2. Categorize by genre first
3. Add tempo tags second
4. Expand to keys/bass when ready

---

*Organize by how you search, not by who made it.*
EOF
  log_success "✓ Created curation guide"
fi

# ==========================================
# SUMMARY
# ==========================================

log_section "MIDI Reorganization Complete!"

echo ""
log_success "✅ Functional hierarchy created"
log_success "✅ Vendor folders preserved"
log_success "✅ Documentation generated"
echo ""

if [[ "$DRY_RUN" == false ]]; then
  log_info "Backup: $BACKUP_DIR"
  log_info "New structure: $MIDI_ROOT/"
  echo ""
  log_warning "NEXT STEPS:"
  log_info "1. Read curation guide: $MIDI_ROOT/README-CURATION.md"
  log_info "2. Start with Toontrack drum MIDI (highest value)"
  log_info "3. Listen, tag by genre/tempo, copy to functional folders"
  log_info "4. Update Ableton 'Places' to include functional MIDI folders"
  echo ""
  log_info "Estimated time: 1-2 hours"
  log_info "Benefit: 10x faster MIDI discovery"
else
  log_warning "This was a DRY RUN. Run without --dry-run to apply changes."
fi

echo ""
