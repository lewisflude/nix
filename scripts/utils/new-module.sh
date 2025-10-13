#!/usr/bin/env bash
# Create a new module from template
# Usage: ./scripts/utils/new-module.sh <type> <name>
#
# Types: feature, service, overlay, test
# Example: ./scripts/utils/new-module.sh feature kubernetes

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Check arguments
if [ $# -ne 2 ]; then
  echo -e "${RED}Usage: $0 <type> <name>${NC}"
  echo -e "${BLUE}Types:${NC}"
  echo -e "  ${GREEN}feature${NC}  - Create a new feature module (e.g., 'kubernetes')"
  echo -e "  ${GREEN}service${NC}  - Create a new service module (e.g., 'grafana')"
  echo -e "  ${GREEN}overlay${NC}  - Create a new package overlay"
  echo -e "  ${GREEN}test${NC}     - Create a new test module"
  echo ""
  echo -e "${BLUE}Examples:${NC}"
  echo -e "  $0 feature kubernetes"
  echo -e "  $0 service grafana"
  echo -e "  $0 overlay custom-packages"
  exit 1
fi

TYPE="$1"
NAME="$2"

# Validate type
case "$TYPE" in
  feature|service|overlay|test)
    ;;
  *)
    echo -e "${RED}❌ Invalid type: $TYPE${NC}"
    echo -e "${YELLOW}Valid types: feature, service, overlay, test${NC}"
    exit 1
    ;;
esac

echo -e "${BLUE}🚀 Creating new $TYPE module: ${GREEN}$NAME${NC}"
echo ""

# Determine paths
case "$TYPE" in
  feature)
    TEMPLATE="$REPO_ROOT/templates/feature-module.nix"
    OUTPUT_DIR="$REPO_ROOT/modules/nixos/features"
    OUTPUT_FILE="$OUTPUT_DIR/$NAME.nix"
    IMPORT_FILE="$REPO_ROOT/modules/nixos/default.nix"
    ;;
  service)
    TEMPLATE="$REPO_ROOT/templates/service-module.nix"
    OUTPUT_DIR="$REPO_ROOT/modules/nixos/services"
    OUTPUT_FILE="$OUTPUT_DIR/$NAME.nix"
    IMPORT_FILE="$REPO_ROOT/modules/nixos/services/default.nix"
    ;;
  overlay)
    TEMPLATE="$REPO_ROOT/templates/overlay-template.nix"
    OUTPUT_DIR="$REPO_ROOT/overlays"
    OUTPUT_FILE="$OUTPUT_DIR/$NAME.nix"
    IMPORT_FILE="$REPO_ROOT/overlays/default.nix"
    ;;
  test)
    TEMPLATE="$REPO_ROOT/templates/test-module.nix"
    OUTPUT_DIR="$REPO_ROOT/tests"
    OUTPUT_FILE="$OUTPUT_DIR/$NAME.nix"
    IMPORT_FILE="$REPO_ROOT/tests/default.nix"
    ;;
esac

# Check if file already exists
if [ -f "$OUTPUT_FILE" ]; then
  echo -e "${RED}❌ File already exists: $OUTPUT_FILE${NC}"
  exit 1
fi

# Create module from template
echo -e "${YELLOW}📝 Creating module from template...${NC}"

# Convert name to different formats
NAME_UPPER=$(echo "$NAME" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
NAME_CAMEL=$(echo "$NAME" | sed -r 's/(^|-)([a-z])/\U\2/g')
NAME_SNAKE=$(echo "$NAME" | tr '-' '_')

# Replace placeholders in template
sed -e "s/FEATURE_NAME/$NAME_SNAKE/g" \
    -e "s/SERVICE_NAME/$NAME_SNAKE/g" \
    -e "s/SERVICE_PACKAGE/$NAME/g" \
    -e "s/DESCRIPTION/Description for $NAME/g" \
    "$TEMPLATE" > "$OUTPUT_FILE"

echo -e "${GREEN}✓ Created: $OUTPUT_FILE${NC}"

# Add to imports if needed
if [ "$TYPE" = "feature" ]; then
  echo ""
  echo -e "${YELLOW}📋 Adding feature options to host-options.nix...${NC}"
  
  OPTIONS_FILE="$REPO_ROOT/modules/shared/host-options.nix"
  
  # Create a backup
  cp "$OPTIONS_FILE" "$OPTIONS_FILE.backup"
  
  # Add the new feature option (simplified - manual edit recommended)
  echo -e "${BLUE}ℹ️  Please manually add the following to $OPTIONS_FILE:${NC}"
  echo ""
  echo -e "${GREEN}    $NAME_SNAKE = {"
  echo -e "      enable = mkEnableOption \"$NAME feature\";"
  echo -e "      # Add additional options here"
  echo -e "    };${NC}"
  echo ""
fi

# Provide next steps
echo -e "${GREEN}✓ Module created successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Next steps:${NC}"

case "$TYPE" in
  feature)
    echo -e "  1. Add feature options to ${CYAN}modules/shared/host-options.nix${NC}"
    echo -e "  2. Implement the feature in ${CYAN}$OUTPUT_FILE${NC}"
    echo -e "  3. Enable in a host: ${CYAN}host.features.$NAME_SNAKE.enable = true;${NC}"
    echo -e "  4. Test the configuration"
    ;;
  service)
    echo -e "  1. Customize the service in ${CYAN}$OUTPUT_FILE${NC}"
    echo -e "  2. Add to host configuration: ${CYAN}services.$NAME_SNAKE.enable = true;${NC}"
    echo -e "  3. Test the service"
    ;;
  overlay)
    echo -e "  1. Implement package overrides in ${CYAN}$OUTPUT_FILE${NC}"
    echo -e "  2. Import in ${CYAN}overlays/default.nix${NC}"
    echo -e "  3. Rebuild to apply changes"
    ;;
  test)
    echo -e "  1. Implement tests in ${CYAN}$OUTPUT_FILE${NC}"
    echo -e "  2. Run with: ${CYAN}nix build .#checks.x86_64-linux.$NAME${NC}"
    ;;
esac

echo ""
echo -e "${BLUE}📖 Template reference: ${CYAN}$TEMPLATE${NC}"
echo -e "${GREEN}🎉 Happy hacking!${NC}"
