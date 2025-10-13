#!/usr/bin/env bash
# Setup Cachix binary cache for faster builds
# This script configures Cachix for both personal and CI use

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CACHE_NAME="${CACHIX_CACHE_NAME:-nix-config}"
CACHIX_BIN="${CACHIX_BIN:-cachix}"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🗄️  Cachix Binary Cache Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if cachix is installed
if ! command -v "$CACHIX_BIN" &> /dev/null; then
    echo -e "${YELLOW}⚠️  Cachix not found. Installing...${NC}"
    nix-env -iA cachix -f https://cachix.org/api/v1/install
fi

echo -e "${GREEN}✓${NC} Cachix version: $(cachix --version)"
echo ""

# Function to setup as user (read-only access)
setup_user() {
    echo -e "${BLUE}📥 Setting up Cachix for read access...${NC}"
    
    # Add common public caches
    echo -e "${YELLOW}→${NC} Adding nix-community cache..."
    cachix use nix-community || true
    
    echo -e "${YELLOW}→${NC} Adding nixpkgs-wayland cache..."
    cachix use nixpkgs-wayland || true
    
    # Add custom cache if exists
    if [ -n "$CACHE_NAME" ]; then
        echo -e "${YELLOW}→${NC} Adding custom cache: $CACHE_NAME..."
        cachix use "$CACHE_NAME" || {
            echo -e "${YELLOW}⚠️  Cache '$CACHE_NAME' not found. You can create it at https://cachix.org${NC}"
        }
    fi
    
    echo ""
    echo -e "${GREEN}✓${NC} Cachix configured for read access"
    echo -e "${GREEN}✓${NC} Binary caches will now be used for faster builds"
}

# Function to setup as CI/maintainer (write access)
setup_ci() {
    echo -e "${BLUE}📤 Setting up Cachix for write access (CI/maintainer)...${NC}"
    
    # Check for auth token
    if [ -z "${CACHIX_AUTH_TOKEN:-}" ]; then
        echo -e "${RED}✗${NC} CACHIX_AUTH_TOKEN not set"
        echo -e "${YELLOW}→${NC} Get your token from: https://app.cachix.org/personal-auth-tokens"
        echo -e "${YELLOW}→${NC} Then run: export CACHIX_AUTH_TOKEN='your-token'"
        exit 1
    fi
    
    echo -e "${YELLOW}→${NC} Authenticating with Cachix..."
    echo "$CACHIX_AUTH_TOKEN" | cachix authtoken
    
    echo -e "${YELLOW}→${NC} Setting up cache: $CACHE_NAME..."
    cachix use "$CACHE_NAME"
    
    echo ""
    echo -e "${GREEN}✓${NC} Cachix configured for write access"
    echo -e "${GREEN}✓${NC} You can now push to cache: $CACHE_NAME"
}

# Function to push current system to cache
push_system() {
    local system="${1:-}"
    
    if [ -z "$system" ]; then
        echo -e "${RED}✗${NC} No system specified"
        echo -e "${YELLOW}Usage:${NC} $0 push <system-name>"
        echo -e "${YELLOW}Example:${NC} $0 push nixosConfigurations.jupiter"
        exit 1
    fi
    
    echo -e "${BLUE}📤 Pushing system to Cachix: $system${NC}"
    echo ""
    
    # Build the system
    echo -e "${YELLOW}→${NC} Building system..."
    nix build ".#$system" --json \
        | jq -r '.[].outputs | to_entries[].value' \
        | cachix push "$CACHE_NAME"
    
    echo ""
    echo -e "${GREEN}✓${NC} System pushed to cache: $CACHE_NAME"
}

# Function to push development shells
push_shells() {
    echo -e "${BLUE}📤 Pushing development shells to Cachix${NC}"
    echo ""
    
    # Get list of all dev shells
    local shells
    shells=$(nix flake show --json 2>/dev/null | jq -r '.devShells."x86_64-linux" | keys[]' || echo "default")
    
    for shell in $shells; do
        echo -e "${YELLOW}→${NC} Pushing shell: $shell..."
        nix build ".#devShells.x86_64-linux.$shell" --json \
            | jq -r '.[].outputs | to_entries[].value' \
            | cachix push "$CACHE_NAME" || true
    done
    
    echo ""
    echo -e "${GREEN}✓${NC} Development shells pushed to cache"
}

# Function to watch and auto-push
watch_and_push() {
    echo -e "${BLUE}👀 Watching for builds and auto-pushing to Cachix${NC}"
    echo -e "${YELLOW}→${NC} This will push all new builds to: $CACHE_NAME"
    echo -e "${YELLOW}→${NC} Press Ctrl+C to stop"
    echo ""
    
    cachix watch-exec "$CACHE_NAME" -- \
        nix build "$@"
}

# Function to show cache statistics
show_stats() {
    echo -e "${BLUE}📊 Cache Statistics${NC}"
    echo ""
    
    echo -e "${YELLOW}Configured caches:${NC}"
    cachix list || echo "No caches configured"
    
    echo ""
    echo -e "${YELLOW}Cache usage:${NC}"
    if [ -n "$CACHE_NAME" ]; then
        echo "  Cache: $CACHE_NAME"
        echo "  URL: https://$CACHE_NAME.cachix.org"
    fi
    
    echo ""
    echo -e "${YELLOW}Local Nix store size:${NC}"
    du -sh /nix/store 2>/dev/null || echo "  Unable to determine"
}

# Main menu
case "${1:-user}" in
    user)
        setup_user
        ;;
    ci|maintainer)
        setup_ci
        ;;
    push)
        push_system "${2:-}"
        ;;
    push-shells)
        push_shells
        ;;
    watch)
        shift
        watch_and_push "$@"
        ;;
    stats)
        show_stats
        ;;
    help|--help|-h)
        echo "Usage: $0 <command> [options]"
        echo ""
        echo "Commands:"
        echo "  user              Setup Cachix for read-only access (default)"
        echo "  ci                Setup Cachix for write access (requires CACHIX_AUTH_TOKEN)"
        echo "  push <system>     Push a system configuration to cache"
        echo "  push-shells       Push all development shells to cache"
        echo "  watch <cmd>       Watch and auto-push build results"
        echo "  stats             Show cache statistics"
        echo "  help              Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  CACHIX_CACHE_NAME     Name of your Cachix cache (default: nix-config)"
        echo "  CACHIX_AUTH_TOKEN     Authentication token for write access"
        echo "  CACHIX_BIN            Path to cachix binary (default: cachix)"
        echo ""
        echo "Examples:"
        echo "  # Setup for users (read-only)"
        echo "  $0 user"
        echo ""
        echo "  # Setup for CI (write access)"
        echo "  export CACHIX_AUTH_TOKEN='your-token'"
        echo "  $0 ci"
        echo ""
        echo "  # Push a system to cache"
        echo "  $0 push nixosConfigurations.jupiter"
        echo ""
        echo "  # Auto-push all builds"
        echo "  $0 watch nix build .#nixosConfigurations.jupiter"
        ;;
    *)
        echo -e "${RED}✗${NC} Unknown command: $1"
        echo -e "${YELLOW}→${NC} Run '$0 help' for usage information"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
