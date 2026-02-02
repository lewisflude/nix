#!/usr/bin/env bash
# List all Home Assistant light entities and their room assignments
# Run this after rebuilding to get entity IDs for updating the configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Home Assistant Light Entity Discovery ===${NC}\n"

# Check for required tools
if ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: curl is required but not installed${NC}"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is required but not installed${NC}"
    exit 1
fi

# Get credentials from SOPS secrets
TOKEN_FILE="/run/secrets/HOME_ASSISTANT_TOKEN"
URL_FILE="/run/secrets/HOME_ASSISTANT_BASE_URL"

if [ ! -f "$TOKEN_FILE" ]; then
    echo -e "${RED}Error: HOME_ASSISTANT_TOKEN not found at $TOKEN_FILE${NC}"
    exit 1
fi

TOKEN=$(cat "$TOKEN_FILE")
URL=$(cat "$URL_FILE" 2>/dev/null || echo "http://localhost:8123")

echo -e "${YELLOW}Connecting to: $URL${NC}\n"

# Query Home Assistant API
echo -e "${GREEN}=== All Light Entities ===${NC}"
curl -s -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    "$URL/api/states" | \
    jq -r '.[] | select(.entity_id | startswith("light.")) |
        "\(.entity_id)\t\(.attributes.friendly_name // "N/A")\t\(.state)"' | \
    column -t -s $'\t' -N "Entity ID,Friendly Name,State" || \
    echo -e "${RED}Failed to query lights. Check if Home Assistant is running and the token is valid.${NC}"

echo -e "\n${GREEN}=== Areas (Rooms) ===${NC}"
curl -s -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    "$URL/api/config/area_registry/list" | \
    jq -r '.[] | "\(.area_id)\t\(.name)"' | \
    column -t -s $'\t' -N "Area ID,Name" || \
    echo -e "${RED}Failed to query areas${NC}"

echo -e "\n${GREEN}=== Lights Grouped by Area ===${NC}"
# Get area registry
AREAS=$(curl -s -H "Authorization: Bearer $TOKEN" "$URL/api/config/area_registry/list")

# Get device registry (links devices to areas)
DEVICES=$(curl -s -H "Authorization: Bearer $TOKEN" "$URL/api/config/device_registry/list")

# Get entity registry (links entities to devices)
ENTITIES=$(curl -s -H "Authorization: Bearer $TOKEN" "$URL/api/config/entity_registry/list")

# Get current states
STATES=$(curl -s -H "Authorization: Bearer $TOKEN" "$URL/api/states")

# Combine and display
echo "$ENTITIES" | jq -r --arg states "$STATES" --arg devices "$DEVICES" \
    '.[] | select(.entity_id | startswith("light.")) |
    .device_id as $dev | .entity_id as $eid |
    ($devices | fromjson | .[] | select(.id == $dev) | .area_id) as $area |
    ($states | fromjson | .[] | select(.entity_id == $eid) | .attributes.friendly_name) as $name |
    "\($area // "no_area")\t\($eid)\t\($name // "N/A")"' | \
    sort | column -t -s $'\t' -N "Area,Entity ID,Friendly Name" || \
    echo -e "${YELLOW}Note: Detailed area mapping may not be available${NC}"

echo -e "\n${BLUE}=== Configuration Template ===${NC}"
echo "Copy and paste these into your jupiter configuration:"
echo ""

for area in "office" "living_room" "kitchen" "bedroom" "hallway"; do
    echo -e "${YELLOW}# ${area^} lights:${NC}"
    curl -s -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        "$URL/api/states" | \
        jq -r --arg area "$area" '.[] |
            select(.entity_id | startswith("light.")) |
            select(.entity_id | contains($area)) |
            "  # \"\(.entity_id)\"  # \(.attributes.friendly_name // "Unknown")"'
    echo ""
done

echo -e "${GREEN}Done!${NC}"
echo -e "\n${BLUE}Next steps:${NC}"
echo "1. Copy the relevant entity IDs from above"
echo "2. Replace the TODO comments in hosts/jupiter/default.nix"
echo "3. Rebuild your system: nh os switch"
echo "4. Configure Adaptive Lighting in Home Assistant UI"
