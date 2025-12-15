#!/usr/bin/env bash
# Ableton Library Health Check
# Monitors library health and provides optimization recommendations

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# Paths
MACBOOK_LIB="/Users/lewisflude/Music/Ableton/User Library"
SAMSUNG_BASE="/Volumes/Samsung Drive/Ableton"

# Health check flags
HEALTH_SCORE=100
WARNINGS=()
RECOMMENDATIONS=()

echo -e "${BOLD}=== Ableton Library Health Check ===${NC}"
echo ""

# Check 1: Internal library size
echo -e "${BLUE}[1/6] Checking internal library size...${NC}"
if [ -d "$MACBOOK_LIB" ]; then
    INTERNAL_SIZE=$(du -sk "$MACBOOK_LIB" | cut -f1)
    INTERNAL_SIZE_MB=$((INTERNAL_SIZE / 1024))
    INTERNAL_SIZE_GB=$((INTERNAL_SIZE_MB / 1024))
    
    if [ $INTERNAL_SIZE_MB -lt 10240 ]; then
        # Under 10GB - excellent
        echo -e "  ${GREEN}✓ Size: ${INTERNAL_SIZE_MB}MB (Excellent)${NC}"
    elif [ $INTERNAL_SIZE_MB -lt 15360 ]; then
        # 10-15GB - good
        echo -e "  ${GREEN}✓ Size: ${INTERNAL_SIZE_GB}GB (Good)${NC}"
        HEALTH_SCORE=$((HEALTH_SCORE - 5))
    elif [ $INTERNAL_SIZE_MB -lt 20480 ]; then
        # 15-20GB - warning
        echo -e "  ${YELLOW}⚠ Size: ${INTERNAL_SIZE_GB}GB (Large)${NC}"
        HEALTH_SCORE=$((HEALTH_SCORE - 15))
        WARNINGS+=("Internal library is larger than recommended (${INTERNAL_SIZE_GB}GB)")
        RECOMMENDATIONS+=("Consider moving less-used content to Samsung Drive")
    else
        # Over 20GB - critical
        echo -e "  ${RED}✗ Size: ${INTERNAL_SIZE_GB}GB (Too Large)${NC}"
        HEALTH_SCORE=$((HEALTH_SCORE - 30))
        WARNINGS+=("Internal library is critically large (${INTERNAL_SIZE_GB}GB)")
        RECOMMENDATIONS+=("Urgently move bulk content to Samsung Drive")
    fi
else
    echo -e "  ${RED}✗ Internal library not found${NC}"
    HEALTH_SCORE=$((HEALTH_SCORE - 50))
fi
echo ""

# Check 2: Samsung Drive connectivity
echo -e "${BLUE}[2/6] Checking Samsung Drive...${NC}"
if [ -d "$SAMSUNG_BASE" ]; then
    echo -e "  ${GREEN}✓ Samsung Drive connected${NC}"
    
    # Check available space
    SAMSUNG_AVAIL=$(df -k "/Volumes/Samsung Drive" | tail -1 | awk '{print $4}')
    SAMSUNG_AVAIL_GB=$((SAMSUNG_AVAIL / 1024 / 1024))
    
    if [ $SAMSUNG_AVAIL_GB -lt 50 ]; then
        echo -e "  ${RED}✗ Low space: ${SAMSUNG_AVAIL_GB}GB available${NC}"
        HEALTH_SCORE=$((HEALTH_SCORE - 20))
        WARNINGS+=("Samsung Drive running low on space")
        RECOMMENDATIONS+=("Clean up old projects or upgrade storage")
    else
        echo -e "  ${GREEN}✓ Available space: ${SAMSUNG_AVAIL_GB}GB${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠ Samsung Drive not connected${NC}"
    HEALTH_SCORE=$((HEALTH_SCORE - 10))
    WARNINGS+=("Samsung Drive not connected - extended library unavailable")
fi
echo ""

# Check 3: Essential directories
echo -e "${BLUE}[3/6] Checking essential directories...${NC}"
ESSENTIAL_DIRS=("Defaults" "Templates" "Grooves" "MIDI Tools")
MISSING_DIRS=()

for dir in "${ESSENTIAL_DIRS[@]}"; do
    if [ -d "$MACBOOK_LIB/$dir" ]; then
        echo -e "  ${GREEN}✓ $dir${NC}"
    else
        echo -e "  ${RED}✗ $dir missing${NC}"
        MISSING_DIRS+=("$dir")
        HEALTH_SCORE=$((HEALTH_SCORE - 5))
    fi
done

if [ ${#MISSING_DIRS[@]} -gt 0 ]; then
    WARNINGS+=("Missing essential directories: ${MISSING_DIRS[*]}")
    RECOMMENDATIONS+=("Run migration script or manually create missing directories")
fi
echo ""

# Check 4: Duplicate content detection
echo -e "${BLUE}[4/6] Checking for potential duplicates...${NC}"
if [ -d "$MACBOOK_LIB" ] && [ -d "$SAMSUNG_BASE" ]; then
    # Check for common duplicate indicators
    MACBOOK_PRESETS=$(find "$MACBOOK_LIB/Presets" -type f 2>/dev/null | wc -l)
    
    if [ "$MACBOOK_PRESETS" -gt 1000 ]; then
        echo -e "  ${YELLOW}⚠ Large number of presets on internal storage ($MACBOOK_PRESETS)${NC}"
        HEALTH_SCORE=$((HEALTH_SCORE - 10))
        RECOMMENDATIONS+=("Review presets - keep only essentials on internal storage")
    else
        echo -e "  ${GREEN}✓ Preset count looks reasonable ($MACBOOK_PRESETS)${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠ Cannot check - one location unavailable${NC}"
fi
echo ""

# Check 5: Large files on internal storage
echo -e "${BLUE}[5/6] Checking for large files on internal storage...${NC}"
if [ -d "$MACBOOK_LIB" ]; then
    LARGE_FILES=$(find "$MACBOOK_LIB" -type f -size +100M 2>/dev/null | wc -l)
    
    if [ "$LARGE_FILES" -gt 0 ]; then
        echo -e "  ${YELLOW}⚠ Found $LARGE_FILES files over 100MB${NC}"
        echo "  These files should be on Samsung Drive:"
        find "$MACBOOK_LIB" -type f -size +100M -exec ls -lh {} \; 2>/dev/null | awk '{print "    " $9 " (" $5 ")"}'
        HEALTH_SCORE=$((HEALTH_SCORE - 15))
        RECOMMENDATIONS+=("Move large files (>100MB) to Samsung Drive")
    else
        echo -e "  ${GREEN}✓ No large files found${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠ Cannot check - internal library unavailable${NC}"
fi
echo ""

# Check 6: README documentation
echo -e "${BLUE}[6/6] Checking documentation...${NC}"
if [ -f "$MACBOOK_LIB/README.md" ]; then
    echo -e "  ${GREEN}✓ Internal README exists${NC}"
else
    echo -e "  ${YELLOW}⚠ Internal README missing${NC}"
    HEALTH_SCORE=$((HEALTH_SCORE - 5))
fi

if [ -d "$SAMSUNG_BASE" ]; then
    if [ -f "$SAMSUNG_BASE/README.md" ]; then
        echo -e "  ${GREEN}✓ Samsung README exists${NC}"
    else
        echo -e "  ${YELLOW}⚠ Samsung README missing${NC}"
        HEALTH_SCORE=$((HEALTH_SCORE - 5))
    fi
fi
echo ""

# Generate Health Score
echo -e "${BOLD}=== Health Score: "
if [ $HEALTH_SCORE -ge 90 ]; then
    echo -e "${GREEN}$HEALTH_SCORE/100 (Excellent)${NC}${BOLD} ===${NC}"
elif [ $HEALTH_SCORE -ge 70 ]; then
    echo -e "${GREEN}$HEALTH_SCORE/100 (Good)${NC}${BOLD} ===${NC}"
elif [ $HEALTH_SCORE -ge 50 ]; then
    echo -e "${YELLOW}$HEALTH_SCORE/100 (Fair)${NC}${BOLD} ===${NC}"
else
    echo -e "${RED}$HEALTH_SCORE/100 (Needs Attention)${NC}${BOLD} ===${NC}"
fi
echo ""

# Display warnings
if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Warnings:${NC}"
    for warning in "${WARNINGS[@]}"; do
        echo "  • $warning"
    done
    echo ""
fi

# Display recommendations
if [ ${#RECOMMENDATIONS[@]} -gt 0 ]; then
    echo -e "${BLUE}💡 Recommendations:${NC}"
    for rec in "${RECOMMENDATIONS[@]}"; do
        echo "  • $rec"
    done
    echo ""
fi

# Quick stats
echo -e "${BOLD}=== Quick Stats ===${NC}"
if [ -d "$MACBOOK_LIB" ]; then
    echo "Internal Library:"
    echo "  • Total Size: $(du -sh "$MACBOOK_LIB" 2>/dev/null | cut -f1)"
    echo "  • File Count: $(find "$MACBOOK_LIB" -type f 2>/dev/null | wc -l)"
fi

if [ -d "$SAMSUNG_BASE" ]; then
    echo "Samsung Drive:"
    echo "  • Total Ableton: $(du -sh "$SAMSUNG_BASE" 2>/dev/null | cut -f1)"
    echo "  • Available Space: $(df -h "/Volumes/Samsung Drive" | tail -1 | awk '{print $4}')"
fi
echo ""

# Maintenance commands
echo -e "${BOLD}=== Maintenance Commands ===${NC}"
echo "Check internal library size:"
echo "  du -sh \"$MACBOOK_LIB\""
echo ""
echo "Find large files on internal storage:"
echo "  find \"$MACBOOK_LIB\" -type f -size +50M -exec ls -lh {} \\;"
echo ""
echo "Clean up .DS_Store files:"
echo "  find \"$MACBOOK_LIB\" -name '.DS_Store' -delete"
echo ""
