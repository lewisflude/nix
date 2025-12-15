#!/usr/bin/env bash
# Interactive Preset Curation Helper
# Helps identify and copy essential presets to internal storage

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

INTERNAL_LIB="/Users/lewisflude/Music/Ableton/User Library"
ARCHIVED_LIB="/Volumes/Samsung Drive/Ableton/User Library-Full"

echo -e "${BOLD}=== Ableton Preset Curation Helper ===${NC}"
echo ""
echo "This tool helps you identify your most essential presets to keep on internal storage."
echo ""

# Check prerequisites
if [ ! -d "$ARCHIVED_LIB" ]; then
    echo -e "${YELLOW}Warning: Archived library not found at $ARCHIVED_LIB${NC}"
    echo "Make sure Samsung Drive is connected."
    exit 1
fi

# Show what's available
echo -e "${BLUE}Your archived library contains:${NC}"
echo ""

if [ -d "$ARCHIVED_LIB/Presets" ]; then
    echo "Presets by category:"
    du -sh "$ARCHIVED_LIB/Presets/"*/ 2>/dev/null | sort -hr | head -20 | while read size path; do
        category=$(basename "$path")
        echo "  $size - $category"
    done
fi
echo ""

if [ -d "$ARCHIVED_LIB/Clips" ]; then
    echo "Clips:"
    du -sh "$ARCHIVED_LIB/Clips" 2>/dev/null
    echo ""
fi

if [ -d "$ARCHIVED_LIB/Samples" ]; then
    echo "Samples:"
    du -sh "$ARCHIVED_LIB/Samples" 2>/dev/null
    echo ""
fi

# Interactive curation
echo -e "${YELLOW}=== Curation Strategy ===${NC}"
echo ""
echo "Think about your last 5-10 projects. What presets/sounds did you use?"
echo ""
echo "Categories to prioritize for internal storage:"
echo "  • Your signature sounds (the presets that define YOUR sound)"
echo "  • Go-to starting points (your workflow essentials)"
echo "  • Small utility presets (<1MB each)"
echo "  • Frequently-used MIDI clips and patterns"
echo ""
echo -e "${BOLD}Target: Keep internal library under 5-10GB${NC}"
echo ""

# Guided copying
echo -e "${BLUE}=== Quick Copy Commands ===${NC}"
echo ""
echo "To copy specific preset categories, use these commands:"
echo ""
echo "# Example: Copy essential instrument presets"
echo "mkdir -p \"$INTERNAL_LIB/Presets/Instruments\""
echo "cp -R \"$ARCHIVED_LIB/Presets/Instruments/YourFavorite\" \\"
echo "      \"$INTERNAL_LIB/Presets/Instruments/\""
echo ""
echo "# Example: Copy essential audio effect racks"
echo "mkdir -p \"$INTERNAL_LIB/Presets/Audio Effects\""
echo "cp -R \"$ARCHIVED_LIB/Presets/Audio Effects/YourGoToChain\" \\"
echo "      \"$INTERNAL_LIB/Presets/Audio Effects/\""
echo ""
echo "# Example: Copy essential MIDI clips"
echo "cp -R \"$ARCHIVED_LIB/Clips/MIDI/YourPatterns\" \\"
echo "      \"$INTERNAL_LIB/Clips/MIDI/\""
echo ""

# Open folders for browsing
echo -e "${YELLOW}=== Browse and Copy ===${NC}"
echo ""
read -p "Open folders for manual browsing? (yes/no): " -r
if [[ $REPLY =~ ^[Yy]es$ ]]; then
    echo "Opening archived library..."
    open "$ARCHIVED_LIB/Presets"
    sleep 1
    echo "Opening internal library..."
    open "$INTERNAL_LIB/Presets"
    echo ""
    echo "Now you can drag-and-drop your essential presets between windows."
    echo ""
fi

# Monitor progress
echo -e "${BLUE}=== Monitor Your Progress ===${NC}"
echo ""
echo "Check internal library size anytime:"
echo "  du -sh \"$INTERNAL_LIB\""
echo ""
echo "Current size:"
du -sh "$INTERNAL_LIB" 2>/dev/null || echo "  0B"
echo ""
echo "Recommended: Stay under 5-10GB for optimal performance"
