#!/usr/bin/env bash
# Setup CodeArtifact for a work project
# Usage: ./setup-codeartifact-project.sh [project-directory]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$(pwd)}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up CodeArtifact for project: ${PROJECT_DIR}${NC}"
echo

# Check if we have the backup file
BACKUP_FILE="$HOME/.npmrc.codeartifact.backup"
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Backup file not found at ${BACKUP_FILE}${NC}"
    echo "Cannot proceed without the CodeArtifact configuration."
    exit 1
fi

# Extract the registry URL and token from backup
REGISTRY=$(grep "^registry=" "$BACKUP_FILE" | cut -d'=' -f2-)
AUTH_LINE=$(grep "^//" "$BACKUP_FILE")

if [ -z "$REGISTRY" ] || [ -z "$AUTH_LINE" ]; then
    echo -e "${RED}Error: Could not extract registry configuration from backup${NC}"
    exit 1
fi

# Create .npmrc in project directory
NPMRC_FILE="${PROJECT_DIR}/.npmrc"

echo -e "${YELLOW}Creating ${NPMRC_FILE}...${NC}"
cat > "$NPMRC_FILE" << EOF
# CodeArtifact configuration for this project
registry=${REGISTRY}
${AUTH_LINE}
EOF

echo -e "${GREEN}✓ Created .npmrc in ${PROJECT_DIR}${NC}"
echo

# Add to .gitignore if it exists
GITIGNORE="${PROJECT_DIR}/.gitignore"
if [ -f "$GITIGNORE" ]; then
    if ! grep -q "^\.npmrc$" "$GITIGNORE" 2>/dev/null; then
        echo -e "${YELLOW}Adding .npmrc to .gitignore...${NC}"
        echo "" >> "$GITIGNORE"
        echo "# NPM configuration with CodeArtifact token" >> "$GITIGNORE"
        echo ".npmrc" >> "$GITIGNORE"
        echo -e "${GREEN}✓ Added .npmrc to .gitignore${NC}"
    else
        echo -e "${GREEN}✓ .npmrc already in .gitignore${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No .gitignore found - remember to not commit .npmrc!${NC}"
fi

echo
echo -e "${GREEN}Setup complete!${NC}"
echo
echo -e "${YELLOW}Note: CodeArtifact tokens expire after 12 hours.${NC}"
echo "To refresh the token, run:"
echo
echo -e "${GREEN}  aws codeartifact get-authorization-token \\${NC}"
echo -e "${GREEN}    --domain lumina-artifacts \\${NC}"
echo -e "${GREEN}    --domain-owner 654654299728 \\${NC}"
echo -e "${GREEN}    --region us-east-1 \\${NC}"
echo -e "${GREEN}    --query authorizationToken \\${NC}"
echo -e "${GREEN}    --output text > /tmp/token.txt${NC}"
echo
echo -e "${GREEN}  # Then update the token in ${NPMRC_FILE}${NC}"
echo
