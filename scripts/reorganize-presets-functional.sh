#!/usr/bin/env bash
#
# reorganize-presets-functional.sh
#
# Transform Ableton presets from vendor-centric to workflow-centric organization
# Following industry best practices for music production libraries
#
# Usage: ./reorganize-presets-functional.sh [--dry-run]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Paths
PRESET_ROOT="/Volumes/Samsung Drive/Ableton/Presets"
BACKUP_DIR="/Volumes/Samsung Drive/Ableton/Backups/Presets-$(date +%Y%m%d-%H%M%S)"

# Flags
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Helper functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_section() { echo -e "\n${MAGENTA}${BOLD}=== $* ===${NC}\n"; }

# Check prerequisites
if [[ ! -d "$PRESET_ROOT" ]]; then
  log_error "Preset root not found: $PRESET_ROOT"
  log_info "Please ensure Samsung Drive is connected"
  exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
  log_warning "DRY RUN MODE - No changes will be made"
  echo ""
fi

log_section "Ableton Preset Reorganization - Functional Workflow"

log_info "Transforming from vendor-centric to workflow-centric organization"
log_info "This will create a dual-system:"
log_info "  • _By-Function/ (PRIMARY) - organized by sound type and genre"
log_info "  • _By-Vendor/ (SECONDARY) - original vendor organization"
echo ""

# Confirmation
if [[ "$DRY_RUN" == false ]]; then
  read -p "Continue with reorganization? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_error "Aborted by user"
    exit 1
  fi
fi

# ==========================================
# PHASE 1: BACKUP
# ==========================================

log_section "Phase 1: Backup Current Structure"

if [[ "$DRY_RUN" == false ]]; then
  log_info "Creating backup at: $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  rsync -ah --progress "$PRESET_ROOT/" "$BACKUP_DIR/"
  log_success "✓ Backup complete"
else
  log_warning "[DRY RUN] Would create backup at: $BACKUP_DIR"
fi

# ==========================================
# PHASE 2: CREATE FUNCTIONAL HIERARCHY
# ==========================================

log_section "Phase 2: Creating Functional Hierarchy"

create_dir() {
  local dir="$1"
  if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$dir"
  else
    log_info "[DRY RUN] Would create: $dir"
  fi
}

log_info "Creating functional directory structure..."

# 00 - Templates
create_dir "$PRESET_ROOT/_By-Function/00-Templates"/{Techno-Starter,House-Starter,DnB-Starter}

# 01 - Drums
create_dir "$PRESET_ROOT/_By-Function/01-Drums/Kicks/_Genre/Techno"/{Industrial,Melodic,Peak-Time}
create_dir "$PRESET_ROOT/_By-Function/01-Drums/Kicks/_Genre/House"/{Deep,Tech,Progressive}
create_dir "$PRESET_ROOT/_By-Function/01-Drums/Kicks/_Genre/DnB"/{Neurofunk,Liquid}
create_dir "$PRESET_ROOT/_By-Function/01-Drums/Kicks/_Type"/{Sub-Heavy,Punchy-Clicky,Distorted,Tonal-Melodic}
create_dir "$PRESET_ROOT/_By-Function/01-Drums/Percussion"/{Shakers,Congas,Foley}
create_dir "$PRESET_ROOT/_By-Function/01-Drums/Loops"

# 02 - Bass
create_dir "$PRESET_ROOT/_By-Function/02-Bass/Sub"/{Pure-Sine,Analog-Warmth,Distorted}
create_dir "$PRESET_ROOT/_By-Function/02-Bass/Mid-Bass"/{Growls,Reeses,FM}
create_dir "$PRESET_ROOT/_By-Function/02-Bass/Top-Bass"/{Plucks,Stabs}
create_dir "$PRESET_ROOT/_By-Function/02-Bass/_By-Genre"/{Techno,House,DnB}

# 03 - Synths
create_dir "$PRESET_ROOT/_By-Function/03-Synths/Leads"/{Mono,Poly}
create_dir "$PRESET_ROOT/_By-Function/03-Synths/Pads"/{Warm,Bright,Dark}
create_dir "$PRESET_ROOT/_By-Function/03-Synths"/{Chords,Arps,Sequences}

# 04 - FX
create_dir "$PRESET_ROOT/_By-Function/04-FX"/{Risers,Impacts,Downlifters,Atmospheres,Transitions}

# 05 - Vocals
create_dir "$PRESET_ROOT/_By-Function/05-Vocals"/{Leads,Chops,One-Shots}

# 06 - Processing
create_dir "$PRESET_ROOT/_By-Function/06-Processing/EQ/FabFilter-PRO-Q"/{Master,Bass,Drums,Vocals}
create_dir "$PRESET_ROOT/_By-Function/06-Processing/Reverb/FabFilter-PRO-R"
create_dir "$PRESET_ROOT/_By-Function/06-Processing/Creative/iFeature"

log_success "✓ Functional hierarchy created"

# ==========================================
# PHASE 3: REORGANIZE VENDOR FOLDERS
# ==========================================

log_section "Phase 3: Organizing Vendor Reference"

create_dir "$PRESET_ROOT/_By-Vendor"

# Create README for vendor directory
if [[ "$DRY_RUN" == false ]]; then
  cat > "$PRESET_ROOT/_By-Vendor/README.md" << 'EOF'
# Vendor Reference Directory

This directory contains the original vendor-organized presets for reference.

## Finding Presets

**PRIMARY:** Use `_By-Function/` for workflow-based browsing
- Organized by sound type (Kicks, Bass, Pads, etc.)
- Organized by genre (Techno, House, DnB)
- Organized by musical function

**SECONDARY:** Use this directory only when you know the exact vendor preset name

## Folder Organization

### Instruments
- **KICK-3/**: All kick presets (180+ kicks across 10 volumes)
- **Serum/**: Bass, synth, and lead presets
- **DX7/**: Classic FM presets
- **JUP-8000/**: Trance and dance presets

### Audio Effects
- **FabFilter/**: PRO-Q 4 and PRO-R 2 presets
- **Ableton/iFeature/**: Creative processing racks

## Cross-Reference

Most presets in `_By-Vendor/` are also organized functionally in `_By-Function/`.

Use `_By-Function/` for faster, workflow-oriented browsing.

---

*Last Updated: 2025-12-17*
EOF
  log_success "✓ Created vendor README"
fi

# Move existing vendor folders to _By-Vendor
if [[ "$DRY_RUN" == false ]]; then
  if [ -d "$PRESET_ROOT/Instruments" ]; then
    log_info "Moving Instruments/ to _By-Vendor/"
    mv "$PRESET_ROOT/Instruments" "$PRESET_ROOT/_By-Vendor/"
  fi
  
  if [ -d "$PRESET_ROOT/Audio Effects" ]; then
    log_info "Moving Audio Effects/ to _By-Vendor/"
    mv "$PRESET_ROOT/Audio Effects" "$PRESET_ROOT/_By-Vendor/"
  fi
  
  log_success "✓ Vendor folders organized"
else
  log_warning "[DRY RUN] Would move vendor folders to _By-Vendor/"
fi

# ==========================================
# PHASE 4: CREATE CURATION README
# ==========================================

log_section "Phase 4: Creating Curation Guide"

if [[ "$DRY_RUN" == false ]]; then
  cat > "$PRESET_ROOT/_By-Function/README-CURATION.md" << 'EOF'
# Preset Curation Guide

This directory uses **functional organization** - presets are organized by sound type and genre, not by vendor.

## Curation Process

### Priority Order (Start Here)

1. **Kicks** (01-Drums/Kicks/) - Highest impact
2. **Bass** (02-Bass/) - Second highest
3. **Synths** (03-Synths/) - Third
4. **FX** (04-FX/)
5. **Processing** (06-Processing/)

### How to Curate Kicks

1. Browse vendor presets: `_By-Vendor/Instruments/KICK-3/`
2. Listen to each preset
3. Ask yourself:
   - What genre does this fit? (Techno/House/DnB)
   - What's the character? (Sub-Heavy/Punchy/Distorted/Tonal)
4. Copy to appropriate functional folder:
   - `01-Drums/Kicks/_Genre/Techno/Peak-Time/`
   - `01-Drums/Kicks/_Type/Punchy-Clicky/`

### Dual Tagging

You can copy the same preset to multiple locations:
- A "punchy techno kick" goes in:
  - `_Genre/Techno/Peak-Time/`
  - `_Type/Punchy-Clicky/`

This creates a **multi-dimensional organization**.

### Naming Convention

Preserve original preset names, but optionally prefix with tags:

- Original: `Big_Room_Kick_07.adg`
- Tagged: `[Techno-Industrial] Big_Room_Kick_07.adg`

### Tools

```bash
# Find all KICK-3 presets
find "_By-Vendor/Instruments/KICK-3" -name "*.adg"

# Copy preset to multiple categories
cp "source.adg" "_Genre/Techno/"
cp "source.adg" "_Type/Punchy/"
```

## Time Investment

- **Initial curation**: 4-6 hours
- **Weekly maintenance**: 5 minutes
- **Monthly review**: 30 minutes

## Benefits

- ✅ Find sounds **5-10x faster** during production
- ✅ Discover presets you forgot you had
- ✅ Stop interrupting creative flow to search
- ✅ Work in "genre mode" for consistent sound

## Examples

### Good Organization
```
01-Drums/Kicks/_Genre/Techno/Industrial/
├── [Heavy] KICK-3 Vol.5 Techno 01.adg
├── [Heavy] KICK-3 Vol.5 Techno 03.adg
└── [Distorted] Andi-Vax Industrial 12.adg
```

### Bad Organization
```
KICK-3/Vol.5/
├── preset_001.adg
├── preset_002.adg
└── preset_003.adg
```

## Getting Started

**Step 1:** Start with kicks (20-30 presets)
**Step 2:** Test in a production session
**Step 3:** Curate bass next
**Step 4:** Expand to other categories

---

*You don't need to curate everything at once. Start small, expand over time.*
EOF
  log_success "✓ Created curation guide"
fi

# ==========================================
# SUMMARY
# ==========================================

log_section "Reorganization Complete!"

echo ""
log_success "✅ Functional hierarchy created"
log_success "✅ Vendor folders organized"
log_success "✅ Documentation generated"
echo ""

if [[ "$DRY_RUN" == false ]]; then
  log_info "Backup location: $BACKUP_DIR"
  log_info "New structure: $PRESET_ROOT/_By-Function/"
  echo ""
  log_warning "NEXT STEPS:"
  log_info "1. Browse the new structure: open \"$PRESET_ROOT/_By-Function/\""
  log_info "2. Read curation guide: $PRESET_ROOT/_By-Function/README-CURATION.md"
  log_info "3. Start curating kicks (highest impact first)"
  log_info "4. Update Ableton's 'Places' to point to _By-Function/ folders"
  echo ""
  log_info "Estimated curation time: 4-6 hours (spread over 1-2 weeks)"
  log_info "Benefit: 5-10x faster preset discovery in production"
else
  log_warning "This was a DRY RUN. Run without --dry-run to apply changes."
fi

echo ""
