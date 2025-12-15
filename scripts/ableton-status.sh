#!/usr/bin/env bash
# Quick Ableton Library Status Check

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

MACBOOK_LIB="/Users/lewisflude/Music/Ableton/User Library"
SAMSUNG_BASE="/Volumes/Samsung Drive/Ableton"

echo -e "${BOLD}🎵 Ableton Library Status${NC}"
echo ""

# Internal Library
if [ -d "$MACBOOK_LIB" ]; then
    SIZE=$(du -sh "$MACBOOK_LIB" 2>/dev/null | cut -f1)
    FILES=$(find "$MACBOOK_LIB" -type f 2>/dev/null | wc -l | tr -d ' ')
    echo -e "${GREEN}✓${NC} Internal Library: ${BOLD}$SIZE${NC} ($FILES files)"
else
    echo -e "${RED}✗${NC} Internal Library: ${RED}Not found${NC}"
fi

# Samsung Drive
if [ -d "$SAMSUNG_BASE" ]; then
    SIZE=$(du -sh "$SAMSUNG_BASE" 2>/dev/null | cut -f1)
    AVAIL=$(df -h "/Volumes/Samsung Drive" | tail -1 | awk '{print $4}')
    echo -e "${GREEN}✓${NC} Samsung Drive: ${BOLD}$SIZE${NC} used, ${BOLD}$AVAIL${NC} available"
else
    echo -e "${YELLOW}⚠${NC} Samsung Drive: ${YELLOW}Not connected${NC}"
fi

# MacBook Storage
MACBOOK_AVAIL=$(df -h /Users | tail -1 | awk '{print $4}')
MACBOOK_PCT=$(df -h /Users | tail -1 | awk '{print $5}')
echo -e "${BLUE}ℹ${NC} MacBook Storage: ${BOLD}$MACBOOK_AVAIL${NC} free ($MACBOOK_PCT used)"

echo ""
echo "Run ${BOLD}./scripts/ableton-library-health.sh${NC} for detailed analysis"
