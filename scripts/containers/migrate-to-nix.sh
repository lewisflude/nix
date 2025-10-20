#!/usr/bin/env bash
# Migration helper script for Docker Compose to NixOS containers
# This script helps backup and prepare for migration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="/home/lewis/.config/nix"
BACKUP_DIR="$HOME/container-migration-backup-$(date +%Y%m%d-%H%M%S)"
STACKS_DIR="/opt/stacks"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo "============================================"
    echo "  Docker Compose to NixOS Container Migration"
    echo "============================================"
    echo ""
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        log_warning "Docker not found (that's OK if you've already removed it)"
    fi
    
    if ! command -v podman &> /dev/null; then
        log_info "Podman not installed yet (will be installed with NixOS rebuild)"
    fi
    
    if [ ! -d "$STACKS_DIR" ]; then
        log_warning "Stacks directory not found at $STACKS_DIR"
    fi
    
    log_success "Prerequisites check complete"
}

backup_current_setup() {
    log_info "Creating backup at $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    
    # Backup stacks directory
    if [ -d "$STACKS_DIR" ]; then
        log_info "Backing up $STACKS_DIR..."
        sudo tar czf "$BACKUP_DIR/stacks-backup.tar.gz" "$STACKS_DIR" 2>/dev/null || \
            log_warning "Could not backup stacks directory (may need sudo)"
    fi
    
    # Backup Docker state
    if command -v docker &> /dev/null; then
        log_info "Saving Docker container list..."
        docker ps -a > "$BACKUP_DIR/docker-containers.txt" 2>/dev/null || true
        docker images > "$BACKUP_DIR/docker-images.txt" 2>/dev/null || true
        docker network ls > "$BACKUP_DIR/docker-networks.txt" 2>/dev/null || true
        docker volume ls > "$BACKUP_DIR/docker-volumes.txt" 2>/dev/null || true
    fi
    
    # Backup environment files
    if [ -f "$STACKS_DIR/media-management/.env" ]; then
        log_info "Backing up environment files..."
        cp "$STACKS_DIR/media-management/.env" "$BACKUP_DIR/media-management.env" 2>/dev/null || true
    fi
    
    if [ -f "$STACKS_DIR/productivity/.env" ]; then
        cp "$STACKS_DIR/productivity/.env" "$BACKUP_DIR/productivity.env" 2>/dev/null || true
    fi
    
    log_success "Backup created at $BACKUP_DIR"
}

stop_docker_compose() {
    log_info "Stopping Docker Compose stacks..."
    
    if [ -d "$STACKS_DIR/media-management" ] && [ -f "$STACKS_DIR/media-management/compose.yaml" ]; then
        log_info "Stopping media-management stack..."
        (cd "$STACKS_DIR/media-management" && docker compose down 2>/dev/null) || \
            log_warning "Could not stop media-management stack"
    fi
    
    if [ -d "$STACKS_DIR/productivity" ] && [ -f "$STACKS_DIR/productivity/compose.yaml" ]; then
        log_info "Stopping productivity stack..."
        (cd "$STACKS_DIR/productivity" && docker compose down 2>/dev/null) || \
            log_warning "Could not stop productivity stack"
    fi
    
    log_success "Docker Compose stacks stopped"
}

show_next_steps() {
    echo ""
    echo "============================================"
    echo "  Backup Complete - Next Steps"
    echo "============================================"
    echo ""
    echo "1. Enable containers in your host configuration:"
    echo "   Edit: $CONFIG_DIR/hosts/jupiter/default.nix"
    echo ""
    echo "   Add to features section:"
    echo "   containers = {"
    echo "     enable = true;"
    echo "     mediaManagement.enable = true;"
    echo "     productivity.enable = true;"
    echo "   };"
    echo ""
    echo "2. Rebuild NixOS:"
    echo "   cd $CONFIG_DIR"
    echo "   sudo nixos-rebuild switch --flake .#jupiter"
    echo ""
    echo "3. Verify services are running:"
    echo "   systemctl list-units 'podman-*'"
    echo "   podman ps"
    echo ""
    echo "4. Check logs if needed:"
    echo "   journalctl -u podman-<service-name> -f"
    echo ""
    echo "Backup location: $BACKUP_DIR"
    echo ""
    echo "For detailed instructions, see:"
    echo "  $CONFIG_DIR/modules/nixos/services/containers/MIGRATION.md"
    echo ""
}

confirm_action() {
    local message=$1
    read -p "$(echo -e ${YELLOW}$message${NC}) [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    fi
    return 0
}

main() {
    print_header
    
    if ! confirm_action "This will backup and prepare for migration. Continue?"; then
        log_info "Migration cancelled"
        exit 0
    fi
    
    check_prerequisites
    backup_current_setup
    
    if confirm_action "Stop Docker Compose stacks now?"; then
        stop_docker_compose
    else
        log_info "Skipping Docker Compose shutdown (you can do this manually later)"
    fi
    
    show_next_steps
    
    log_success "Migration preparation complete!"
}

# Run main function
main "$@"
