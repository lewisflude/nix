#!/usr/bin/env bash
# Extract Kick3 Preset Archives

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

ARCHIVES_DIR="/Volumes/Samsung Drive/Ableton/Archives-ToExtract"
OUTPUT_DIR="/Volumes/Samsung Drive/Ableton/Presets-Extended/Instruments/KICK-3"

echo -e "${BOLD}=== Kick3 Preset Extraction ===${NC}"
echo ""

# Check for Samsung Drive
if [ ! -d "$ARCHIVES_DIR" ]; then
    echo -e "${RED}Error: Samsung Drive not connected or Archives directory not found${NC}"
    exit 1
fi

# Count Kick archives
KICK_COUNT=$(ls "$ARCHIVES_DIR" | grep -i "KICK" | grep ".rar" | wc -l | tr -d ' ')
echo "Found $KICK_COUNT Kick preset archives (344MB total)"
echo ""

# Check for extraction tool
if command -v unar &> /dev/null; then
    EXTRACTOR="unar"
    echo -e "${GREEN}✓ Found unar for extraction${NC}"
elif command -v unrar &> /dev/null; then
    EXTRACTOR="unrar x"
    echo -e "${GREEN}✓ Found unrar for extraction${NC}"
else
    echo -e "${RED}Error: No extraction tool found${NC}"
    echo ""
    echo "Install unar with:"
    echo "  brew install unar"
    echo ""
    echo "Or download The Unarchiver app from the Mac App Store"
    exit 1
fi
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"
echo "Extracting to: $OUTPUT_DIR"
echo ""

# Extract each archive
cd "$ARCHIVES_DIR"
for archive in KICK*.rar AV_SONIC_ACA_KICK*.rar; do
    if [ -f "$archive" ]; then
        echo -e "${BLUE}Extracting: $archive${NC}"
        
        if [ "$EXTRACTOR" = "unar" ]; then
            unar -o "$OUTPUT_DIR" "$archive" 2>&1 | grep -v "^  " || true
        else
            unrar x -o+ "$archive" "$OUTPUT_DIR/" 2>&1 | grep -v "^Extracting" || true
        fi
        
        echo -e "${GREEN}  ✓ Complete${NC}"
    fi
done

echo ""
echo -e "${GREEN}${BOLD}=== Extraction Complete ===${NC}"
echo ""
echo "Kick3 presets extracted to:"
echo "  $OUTPUT_DIR"
echo ""
echo "Total size:"
du -sh "$OUTPUT_DIR"
echo ""

# Show structure
echo "Preset structure:"
ls -la "$OUTPUT_DIR" | tail -n +4 | head -10

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. In Ableton Live, go to Preferences → Library → Places"
echo "2. Add folder: /Volumes/Samsung Drive/Ableton/Presets-Extended"
echo "3. Your Kick3 presets will appear in Ableton's browser"
echo ""
echo "Alternatively, copy your favorites to internal storage:"
echo "  cp -R \"$OUTPUT_DIR/YourFavorites\" \\"
echo "        \"/Users/lewisflude/Music/Ableton/User Library/Presets/Instruments/\""
