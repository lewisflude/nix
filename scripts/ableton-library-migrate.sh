#!/usr/bin/env bash
# Ableton Library Migration Script
# Implements tiered library architecture

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Paths
MACBOOK_BASE="/Users/lewisflude/Music/Ableton"
MACBOOK_LIB="$MACBOOK_BASE/User Library"
SAMSUNG_BASE="/Volumes/Samsung Drive/Ableton"
SAMSUNG_LIB="$SAMSUNG_BASE/User Library"
BACKUP_DIR="$MACBOOK_BASE/Backup-$(date +%Y%m%d-%H%M%S)"

echo -e "${BOLD}=== Ableton Library Migration Tool ===${NC}"
echo ""
echo "This script will set up a professional tiered library architecture:"
echo "  • Tier 1 (Internal): Essential, frequently-used content"
echo "  • Tier 2 (Samsung): Bulk storage, extended libraries"
echo ""

# Safety check
if [ ! -d "$SAMSUNG_BASE" ]; then
    echo -e "${RED}ERROR: Samsung Drive not found at $SAMSUNG_BASE${NC}"
    echo "Please connect the drive and try again."
    exit 1
fi

# Confirmation
echo -e "${YELLOW}⚠️  This script will:${NC}"
echo "  1. Backup your current MacBook User Library"
echo "  2. Create a new organized structure on Samsung Drive"
echo "  3. Create a curated internal User Library"
echo "  4. Clean up duplicates and archives"
echo ""
read -p "Continue? (yes/no): " -r
echo ""
if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
    echo "Aborted."
    exit 0
fi

# Phase 1: Backup current state
echo -e "${BLUE}Phase 1: Backing up current configuration...${NC}"
if [ -d "$MACBOOK_LIB" ]; then
    echo "  Creating backup at: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    cp -R "$MACBOOK_LIB" "$BACKUP_DIR/"
    echo -e "  ${GREEN}✓ Backup complete${NC}"
else
    echo "  No existing MacBook User Library found (this is OK)"
fi
echo ""

# Phase 2: Organize Samsung Drive
echo -e "${BLUE}Phase 2: Organizing Samsung Drive structure...${NC}"

# Rename current Samsung User Library to avoid confusion
if [ -d "$SAMSUNG_LIB" ]; then
    echo "  Renaming existing Samsung User Library..."
    mv "$SAMSUNG_LIB" "$SAMSUNG_BASE/User Library-Full"
    echo -e "  ${GREEN}✓ Renamed to 'User Library-Full'${NC}"
fi

# Create organized structure
echo "  Creating organized folder structure..."
mkdir -p "$SAMSUNG_BASE/Sample Libraries"
mkdir -p "$SAMSUNG_BASE/Presets-Extended"
mkdir -p "$SAMSUNG_BASE/Projects-Active"
mkdir -p "$SAMSUNG_BASE/Projects-Archive"
mkdir -p "$SAMSUNG_BASE/Sound Design Sources"

# Move existing folders to new structure
if [ -d "$SAMSUNG_BASE/User Library-Full/Sample Library" ]; then
    echo "  Moving Sample Library..."
    mv "$SAMSUNG_BASE/User Library-Full/Sample Library/"* "$SAMSUNG_BASE/Sample Libraries/" 2>/dev/null || true
fi

if [ -d "$SAMSUNG_BASE/User Library-Full/Tutorials" ]; then
    echo "  Moving Tutorials..."
    mv "$SAMSUNG_BASE/User Library-Full/Tutorials" "$SAMSUNG_BASE/" 2>/dev/null || true
fi

echo -e "  ${GREEN}✓ Samsung Drive organized${NC}"
echo ""

# Phase 3: Create curated internal library
echo -e "${BLUE}Phase 3: Creating curated internal User Library...${NC}"

# Remove old MacBook library if it exists (after backup)
if [ -d "$MACBOOK_LIB" ]; then
    echo "  Removing old MacBook User Library (backed up)..."
    rm -rf "$MACBOOK_LIB"
fi

# Create fresh structure
echo "  Creating new User Library structure..."
mkdir -p "$MACBOOK_LIB"

# Essential directories that should be internal
ESSENTIAL_DIRS=(
    "Defaults"
    "Templates"
    "Grooves"
    "MIDI Tools"
    "Ableton Project Info"
    "Ableton Folder Info"
)

# Copy essential directories from Samsung
for dir in "${ESSENTIAL_DIRS[@]}"; do
    if [ -d "$SAMSUNG_BASE/User Library-Full/$dir" ]; then
        echo "  Copying $dir..."
        cp -R "$SAMSUNG_BASE/User Library-Full/$dir" "$MACBOOK_LIB/"
    else
        # Create empty structure if doesn't exist
        mkdir -p "$MACBOOK_LIB/$dir"
    fi
done

# Create lightweight Presets and Clips directories
mkdir -p "$MACBOOK_LIB/Presets"
mkdir -p "$MACBOOK_LIB/Clips"
mkdir -p "$MACBOOK_LIB/Samples"

echo "  NOTE: Presets, Clips, and Samples directories created but empty."
echo "        Manually copy your most-used presets to internal storage."
echo -e "  ${GREEN}✓ Internal User Library created${NC}"
echo ""

# Phase 4: Clean up MacBook backup archives
echo -e "${BLUE}Phase 4: Analyzing compressed archives...${NC}"
if [ -d "$BACKUP_DIR/User Library" ]; then
    ARCHIVE_COUNT=$(find "$BACKUP_DIR/User Library" -name "*.rar" 2>/dev/null | wc -l)
    echo "  Found $ARCHIVE_COUNT .rar archives in backup"
    
    if [ "$ARCHIVE_COUNT" -gt 0 ]; then
        echo ""
        echo "  These are compressed files that haven't been extracted."
        read -p "  Move these to Samsung Drive for later extraction? (yes/no): " -r
        if [[ $REPLY =~ ^[Yy]es$ ]]; then
            mkdir -p "$SAMSUNG_BASE/Archives-ToExtract"
            find "$BACKUP_DIR/User Library" -name "*.rar" -exec mv {} "$SAMSUNG_BASE/Archives-ToExtract/" \;
            echo -e "  ${GREEN}✓ Archives moved to Samsung Drive/Archives-ToExtract/${NC}"
        fi
    fi
fi
echo ""

# Phase 5: Generate documentation
echo -e "${BLUE}Phase 5: Creating documentation...${NC}"

cat > "$MACBOOK_LIB/README.md" << 'EOF'
# Ableton User Library - Internal (Tier 1)

This is your **performance layer** - essential content that's always available.

## What belongs here:
- ✅ Defaults and preferences
- ✅ Project templates
- ✅ Your top 20% most-used presets
- ✅ Essential MIDI clips and patterns
- ✅ Grooves and MIDI tools

## What belongs on Samsung Drive:
- ❌ Large sample libraries
- ❌ Full preset collections
- ❌ Tutorials and learning materials
- ❌ Archived projects

## Storage Guidelines:
- Keep this folder under 5-10GB
- Regularly audit and remove unused content
- Use Ableton's "Places" to access Samsung Drive content

## Samsung Drive Structure:
- `/Volumes/Samsung Drive/Ableton/Sample Libraries/` - Large sample packs
- `/Volumes/Samsung Drive/Ableton/Presets-Extended/` - Full preset collections
- `/Volumes/Samsung Drive/Ableton/Projects-Active/` - Current projects
- `/Volumes/Samsung Drive/Ableton/Projects-Archive/` - Completed projects

Last updated: $(date +"%Y-%m-%d")
EOF

cat > "$SAMSUNG_BASE/README.md" << 'EOF'
# Ableton Storage - Samsung Drive (Tier 2)

This is your **expansion layer** - bulk storage for extended content.

## Directory Structure:

### `/Sample Libraries/`
Large multi-GB sample collections. Add to Ableton as a "Place".

### `/Presets-Extended/`
Full preset collections for all your plugins. Add to Ableton as a "Place".

### `/Projects-Active/`
Current projects you're working on. Can work directly from here or copy to internal during active development.

### `/Projects-Archive/`
Completed or old projects for long-term storage.

### `/Factory Packs/`
Official Ableton packs and Core Library content.

### `/Sound Design Sources/`
Raw audio for sound design and sampling.

### `/User Library-Full/`
Your previous full User Library (archived reference).

## Usage:
1. Open Ableton Live
2. Go to Preferences → Library → Places
3. Add relevant folders from this drive
4. Content will appear in Ableton's browser when drive is connected

## Important:
Your essential working library is on your MacBook's internal storage at:
`/Users/lewisflude/Music/Ableton/User Library/`

This ensures Ableton works even when this drive is disconnected.

Last updated: $(date +"%Y-%m-%d")
EOF

echo -e "  ${GREEN}✓ Documentation created${NC}"
echo ""

# Phase 6: Summary and next steps
echo -e "${GREEN}${BOLD}=== Migration Complete! ===${NC}"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "  • Backup created at: $BACKUP_DIR"
echo "  • Internal User Library: $MACBOOK_LIB"
echo "  • Samsung Drive organized: $SAMSUNG_BASE"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo -e "${BOLD}1. Configure Ableton Live:${NC}"
echo "   a. Open Ableton Live"
echo "   b. Go to Preferences → Library"
echo "   c. Set User Library to:"
echo "      $MACBOOK_LIB"
echo "   d. In the 'Places' section, add these folders:"
echo "      • $SAMSUNG_BASE/Sample Libraries"
echo "      • $SAMSUNG_BASE/Presets-Extended"
echo "      • $SAMSUNG_BASE/Factory Packs"
echo ""
echo -e "${BOLD}2. Curate Your Internal Library:${NC}"
echo "   a. Browse $SAMSUNG_BASE/User Library-Full/Presets"
echo "   b. Copy your most-used presets to $MACBOOK_LIB/Presets"
echo "   c. Do the same for Clips and essential Samples"
echo "   d. Aim to keep internal library under 5-10GB"
echo ""
echo -e "${BOLD}3. Test the Setup:${NC}"
echo "   a. Test with Samsung Drive connected"
echo "   b. Eject Samsung Drive and test again (should still work)"
echo "   c. Verify essential presets/templates load without drive"
echo ""
echo -e "${BOLD}4. Monitor Library Size:${NC}"
echo "   Run: du -sh $MACBOOK_LIB"
echo "   Keep it lean - move unused content to Samsung Drive"
echo ""
echo -e "${GREEN}Done! Your library is now organized for professional workflow.${NC}"
