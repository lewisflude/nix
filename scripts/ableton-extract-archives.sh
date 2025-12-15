#!/usr/bin/env bash
# Ableton Archive Extraction Script
# Extracts and organizes preset archives from Samsung Drive

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

ARCHIVES_DIR="/Volumes/Samsung Drive/Ableton/Archives-ToExtract"
PRESETS_DIR="/Volumes/Samsung Drive/Ableton/Presets-Extended"
CLIPS_DIR="/Volumes/Samsung Drive/Ableton/Clips"
EXTRACTED_DIR="${ARCHIVES_DIR}/EXTRACTED"

# Check if Samsung Drive is mounted
if [[ ! -d "/Volumes/Samsung Drive" ]]; then
    echo -e "${RED}✗ Samsung Drive not connected${NC}"
    exit 1
fi

# Create necessary directories
mkdir -p "${EXTRACTED_DIR}"
mkdir -p "${PRESETS_DIR}/Audio Effects/FabFilter/PRO-Q 4"
mkdir -p "${PRESETS_DIR}/Audio Effects/FabFilter/PRO-R 2"
mkdir -p "${PRESETS_DIR}/Audio Effects/Ableton/iFeature"
mkdir -p "${PRESETS_DIR}/Instruments/DX7"
mkdir -p "${PRESETS_DIR}/Instruments/JUP-8000"
mkdir -p "${PRESETS_DIR}/Instruments/KICK-3"
mkdir -p "${PRESETS_DIR}/Instruments/Serum"
mkdir -p "${PRESETS_DIR}/MIDI Effects/Max MIDI Effect"
mkdir -p "${CLIPS_DIR}/MIDI/Keys/Toontrack"
mkdir -p "${CLIPS_DIR}/MIDI/Drums/GetGood"

echo -e "${BOLD}=== Ableton Archive Extraction ===${NC}\n"

# Ensure we're using nix-shell with unrar
if ! command -v unrar &> /dev/null; then
    echo -e "${YELLOW}⚠ unrar not found, launching with nix-shell...${NC}"
    export NIXPKGS_ALLOW_UNFREE=1
    exec nix-shell --impure -p unrar --run "bash $0 --with-unrar"
fi

# Function to extract archive
extract_archive() {
    local archive="$1"
    local dest="$2"
    local name=$(basename "${archive}")
    
    echo -e "${BLUE}Extracting: ${name}${NC}"
    
    # Extract directly to destination (silently)
    if unrar x -o+ -inul "${archive}" "${dest}/" > /dev/null 2>&1; then
        # Move archive to extracted folder
        mv "${archive}" "${EXTRACTED_DIR}/"
        echo -e "${GREEN}  ✓ Extracted successfully${NC}"
        return 0
    else
        echo -e "${RED}  ✗ Failed to extract${NC}"
        return 1
    fi
}

# Track statistics
total=0
success=0
failed=0

# Extract FabFilter PRO-Q 4 presets
if [[ -f "${ARCHIVES_DIR}/AV_PRO-Q4_PRESETS.rar" ]]; then
    ((total++))
    if extract_archive "${ARCHIVES_DIR}/AV_PRO-Q4_PRESETS.rar" "${PRESETS_DIR}/Audio Effects/FabFilter/PRO-Q 4"; then
        ((success++))
    else
        ((failed++))
    fi
fi

# Extract FabFilter PRO-R 2 presets
if [[ -f "${ARCHIVES_DIR}/AV_FF_PRO_R2_PRESETS.rar" ]]; then
    ((total++))
    if extract_archive "${ARCHIVES_DIR}/AV_FF_PRO_R2_PRESETS.rar" "${PRESETS_DIR}/Audio Effects/FabFilter/PRO-R 2"; then
        ((success++))
    else
        ((failed++))
    fi
fi

# Extract iFeature Ableton racks
for ifea_file in "${ARCHIVES_DIR}"/IFEA_*.rar; do
    if [[ -f "${ifea_file}" ]]; then
        ((total++))
        if extract_archive "${ifea_file}" "${PRESETS_DIR}/Audio Effects/Ableton/iFeature"; then
            ((success++))
        else
            ((failed++))
        fi
    fi
done

# Extract KICK-3 presets
if [[ -f "${ARCHIVES_DIR}/AV_SONIC_ACA_KICK_3_PRESETS.rar" ]]; then
    ((total++))
    if extract_archive "${ARCHIVES_DIR}/AV_SONIC_ACA_KICK_3_PRESETS.rar" "${PRESETS_DIR}/Instruments/KICK-3"; then
        ((success++))
    else
        ((failed++))
    fi
fi

for kick_file in "${ARCHIVES_DIR}"/KICK_VOL_*.rar; do
    if [[ -f "${kick_file}" ]]; then
        ((total++))
        if extract_archive "${kick_file}" "${PRESETS_DIR}/Instruments/KICK-3"; then
            ((success++))
        else
            ((failed++))
        fi
    fi
done

# Extract DX7 cartridges
for cartridge_file in "${ARCHIVES_DIR}"/CARTRIDGE*.rar; do
    if [[ -f "${cartridge_file}" ]]; then
        ((total++))
        if extract_archive "${cartridge_file}" "${PRESETS_DIR}/Instruments/DX7"; then
            ((success++))
        else
            ((failed++))
        fi
    fi
done

# Extract JUP-8000 presets (numbered archives)
for jup_file in "${ARCHIVES_DIR}"/{7368P,7376P,7377P}.rar; do
    if [[ -f "${jup_file}" ]]; then
        ((total++))
        if extract_archive "${jup_file}" "${PRESETS_DIR}/Instruments/JUP-8000"; then
            ((success++))
        else
            ((failed++))
        fi
    fi
done

# Extract Serum presets (numbered archives)
for serum_file in "${ARCHIVES_DIR}"/{893MD,894MD,895MD,896MD}.rar; do
    if [[ -f "${serum_file}" ]]; then
        ((total++))
        if extract_archive "${serum_file}" "${PRESETS_DIR}/Instruments/Serum"; then
            ((success++))
        else
            ((failed++))
        fi
    fi
done

# Extract Yamaha TX81Z Editor
if [[ -f "${ARCHIVES_DIR}/Yamaha.TX81Z.Editor.rar" ]]; then
    ((total++))
    if extract_archive "${ARCHIVES_DIR}/Yamaha.TX81Z.Editor.rar" "${PRESETS_DIR}/MIDI Effects/Max MIDI Effect"; then
        ((success++))
    else
        ((failed++))
    fi
fi

# Extract Toontrack MIDI packs
for toontrack_file in "${ARCHIVES_DIR}"/Toontrack.*.rar; do
    if [[ -f "${toontrack_file}" ]]; then
        ((total++))
        if extract_archive "${toontrack_file}" "${CLIPS_DIR}/MIDI/Keys/Toontrack"; then
            ((success++))
        else
            ((failed++))
        fi
    fi
done

# Remove .DS_Store and other metadata files
echo -e "\n${BLUE}Cleaning up metadata files...${NC}"
find "${PRESETS_DIR}" -name '.DS_Store' -delete 2>/dev/null || true
find "${PRESETS_DIR}" -name '*.nfo' -delete 2>/dev/null || true
find "${PRESETS_DIR}" -name 'audionews.nfo' -delete 2>/dev/null || true
find "${CLIPS_DIR}" -name '.DS_Store' -delete 2>/dev/null || true
find "${CLIPS_DIR}" -name '*.nfo' -delete 2>/dev/null || true
find "${CLIPS_DIR}" -name 'audionews.nfo' -delete 2>/dev/null || true

echo -e "\n${BOLD}=== Extraction Complete ===${NC}"
echo -e "${GREEN}✓ Successful: ${success}/${total}${NC}"
if [[ ${failed} -gt 0 ]]; then
    echo -e "${RED}✗ Failed: ${failed}/${total}${NC}"
fi

echo -e "\n${BOLD}=== Directory Sizes ===${NC}"
if [[ -d "${PRESETS_DIR}" ]]; then
    du -sh "${PRESETS_DIR}"/* 2>/dev/null | sort -h || true
fi
echo ""
if [[ -d "${CLIPS_DIR}" ]]; then
    du -sh "${CLIPS_DIR}"/* 2>/dev/null | sort -h || true
fi

echo -e "\n${BOLD}=== Next Steps ===${NC}"
echo "1. Open Ableton Live"
echo "2. Go to Preferences → Library → Places"
echo "3. Add this folder: ${PRESETS_DIR}"
echo "4. Add this folder: ${CLIPS_DIR}"
echo ""
echo "Extracted archives moved to: ${EXTRACTED_DIR}"
