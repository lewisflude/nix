#!/usr/bin/env bash
# Ableton Library Audit Script
# Analyzes current library state and generates recommendations

set -euo pipefail

echo "=== Ableton Library Audit ==="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Paths
MACBOOK_LIB="/Users/lewisflude/Music/Ableton/User Library"
SAMSUNG_LIB="/Volumes/Samsung Drive/Ableton/User Library"
SAMSUNG_BASE="/Volumes/Samsung Drive/Ableton"

# Check MacBook User Library
echo -e "${YELLOW}📱 MacBook User Library:${NC}"
if [ -d "$MACBOOK_LIB" ]; then
    SIZE=$(du -sh "$MACBOOK_LIB" 2>/dev/null | cut -f1)
    echo "   Location: $MACBOOK_LIB"
    echo "   Size: $SIZE"
    echo "   Contents:"
    ls -1 "$MACBOOK_LIB" | sed 's/^/     - /'
else
    echo -e "   ${RED}Not found${NC}"
fi
echo ""

# Check Samsung Drive
echo -e "${YELLOW}💾 Samsung Drive Status:${NC}"
if [ -d "$SAMSUNG_BASE" ]; then
    echo -e "   ${GREEN}✓ Connected${NC}"
    TOTAL_SIZE=$(df -h "/Volumes/Samsung Drive" | tail -1 | awk '{print $2}')
    USED_SIZE=$(df -h "/Volumes/Samsung Drive" | tail -1 | awk '{print $3}')
    AVAIL_SIZE=$(df -h "/Volumes/Samsung Drive" | tail -1 | awk '{print $4}')
    USE_PCT=$(df -h "/Volumes/Samsung Drive" | tail -1 | awk '{print $5}')
    
    echo "   Total: $TOTAL_SIZE | Used: $USED_SIZE | Available: $AVAIL_SIZE | Usage: $USE_PCT"
    echo ""
    
    if [ -d "$SAMSUNG_LIB" ]; then
        SAMSUNG_SIZE=$(du -sh "$SAMSUNG_LIB" 2>/dev/null | cut -f1)
        echo "   User Library Size: $SAMSUNG_SIZE"
        echo "   Contents:"
        ls -1 "$SAMSUNG_LIB" | sed 's/^/     - /'
    fi
    
    echo ""
    echo "   Folder Structure:"
    ls -1 "$SAMSUNG_BASE" | sed 's/^/     - /'
else
    echo -e "   ${RED}✗ Not connected${NC}"
fi
echo ""

# Check MacBook free space
echo -e "${YELLOW}💻 MacBook Storage:${NC}"
MACBOOK_TOTAL=$(df -h /Users | tail -1 | awk '{print $2}')
MACBOOK_USED=$(df -h /Users | tail -1 | awk '{print $3}')
MACBOOK_AVAIL=$(df -h /Users | tail -1 | awk '{print $4}')
MACBOOK_PCT=$(df -h /Users | tail -1 | awk '{print $5}')

echo "   Total: $MACBOOK_TOTAL | Used: $MACBOOK_USED | Available: $MACBOOK_AVAIL | Usage: $MACBOOK_PCT"

# Calculate recommended allocation
AVAIL_GB=$(echo $MACBOOK_AVAIL | sed 's/Gi\?//')
if [ "${AVAIL_GB%.*}" -gt 15 ]; then
    RECOMMEND="8-10GB"
    COLOR=$GREEN
elif [ "${AVAIL_GB%.*}" -gt 10 ]; then
    RECOMMEND="5-8GB"
    COLOR=$YELLOW
else
    RECOMMEND="3-5GB"
    COLOR=$RED
fi

echo -e "   ${COLOR}Recommended internal library size: $RECOMMEND${NC}"
echo ""

# Recommendations
echo -e "${GREEN}=== Recommendations ===${NC}"
echo ""
echo "1. Keep essential content on MacBook (Templates, Defaults, top presets)"
echo "2. Move bulk content to Samsung Drive organized structure"
echo "3. Use Ableton's 'Places' to add Samsung locations"
echo "4. Test workflow with Samsung Drive disconnected"
echo ""

# Generate next steps
echo -e "${YELLOW}=== Next Steps ===${NC}"
echo ""
echo "Run: ./scripts/ableton-library-migrate.sh"
echo "This will guide you through the migration process."
