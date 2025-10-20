#!/usr/bin/env bash
# Migrate configuration files from /opt/stacks to /var/lib/containers
# This preserves your existing settings, databases, and API keys

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

OLD_BASE="/opt/stacks/media-management"
NEW_BASE="/var/lib/containers/media-management"
BACKUP_DIR="$HOME/container-config-backup-$(date +%Y%m%d-%H%M%S)"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

confirm() {
    local message=$1
    read -p "$(echo -e ${YELLOW}$message${NC}) [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return 1
    fi
    return 0
}

print_header() {
    echo ""
    echo "╔════════════════════════════════════════════╗"
    echo "║  Container Configuration Migration         ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""
}

# Services to migrate (maps old dir name to new dir name)
declare -A SERVICE_MAP=(
    ["prowlarr"]="prowlarr"
    ["radarr"]="radarr"
    ["sonarr"]="sonarr"
    ["lidarr"]="lidarr"
    ["whisparr"]="whisparr"
    ["readarr"]="readarr"
    ["qbittorrent"]="qbittorrent"
    ["sabnzbd"]="sabnzbd"
    ["jellyfin"]="jellyfin"
    ["jellyseer"]="jellyseerr"  # Note: different spelling
    ["homarr"]="homarr"
    ["wizarr"]="wizarr"
    ["janitorr"]="janitorr"
    ["flaresolverr"]="flaresolverr"
    ["kapowarr"]="kapowarr"
    ["doplarr"]="doplarr"
    ["autopulse"]="autopulse"
    ["unpackerr"]="unpackerr"
)

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if [ ! -d "$OLD_BASE" ]; then
        log_error "Old config directory not found: $OLD_BASE"
        exit 1
    fi
    
    if ! sudo test -d "$NEW_BASE"; then
        log_error "New config directory not found: $NEW_BASE"
        log_info "Make sure containers have been started at least once"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

create_backup() {
    log_info "Creating backup at $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    
    # Backup new configs (in case something goes wrong)
    sudo tar czf "$BACKUP_DIR/new-configs-backup.tar.gz" -C /var/lib/containers media-management 2>/dev/null
    
    log_success "Backup created"
}

stop_services() {
    log_info "Stopping Podman services..."
    
    for service in "${!SERVICE_MAP[@]}"; do
        local new_name="${SERVICE_MAP[$service]}"
        if systemctl is-active --quiet "podman-$new_name" 2>/dev/null; then
            log_info "Stopping podman-$new_name..."
            sudo systemctl stop "podman-$new_name"
        fi
    done
    
    # Wait a moment for containers to fully stop
    sleep 2
    log_success "Services stopped"
}

migrate_service() {
    local old_name=$1
    local new_name=$2
    
    local old_config="$OLD_BASE/$old_name/config"
    local new_config="$NEW_BASE/$new_name"
    
    # Check if old config exists
    if [ ! -d "$old_config" ]; then
        log_warning "$old_name: No config directory found at $old_config"
        return
    fi
    
    # Check if new directory exists
    if [ ! -d "$new_config" ]; then
        log_warning "$new_name: New directory doesn't exist, creating..."
        sudo mkdir -p "$new_config"
        sudo chown 1000:100 "$new_config"
    fi
    
    log_info "Migrating $old_name → $new_name..."
    
    # Copy config files
    # Use rsync to preserve timestamps and permissions
    if command -v rsync &> /dev/null; then
        sudo rsync -av --ignore-existing "$old_config/" "$new_config/"
    else
        # Fallback to cp
        sudo cp -rn "$old_config/"* "$new_config/" 2>/dev/null || true
    fi
    
    # Fix ownership
    sudo chown -R 1000:100 "$new_config"
    
    log_success "$new_name migrated"
}

migrate_all_services() {
    log_info "Migrating service configurations..."
    echo ""
    
    local count=0
    for service in "${!SERVICE_MAP[@]}"; do
        migrate_service "$service" "${SERVICE_MAP[$service]}"
        ((count++))
    done
    
    echo ""
    log_success "Migrated $count services"
}

start_services() {
    log_info "Starting Podman services..."
    
    for service in "${!SERVICE_MAP[@]}"; do
        local new_name="${SERVICE_MAP[$service]}"
        if systemctl is-enabled --quiet "podman-$new_name" 2>/dev/null; then
            log_info "Starting podman-$new_name..."
            sudo systemctl start "podman-$new_name"
        fi
    done
    
    log_success "Services started"
}

show_summary() {
    echo ""
    echo "╔════════════════════════════════════════════╗"
    echo "║  Migration Complete                        ║"
    echo "╚════════════════════════════════════════════╝"
    echo ""
    echo "Configuration files have been migrated from:"
    echo "  $OLD_BASE"
    echo ""
    echo "To:"
    echo "  $NEW_BASE"
    echo ""
    echo "Backup saved at:"
    echo "  $BACKUP_DIR"
    echo ""
    echo "Next steps:"
    echo "  1. Check services are running:"
    echo "     systemctl list-units 'podman-*' | grep running"
    echo ""
    echo "  2. Test web interfaces:"
    echo "     firefox http://localhost:9696  # Prowlarr"
    echo "     firefox http://localhost:7878  # Radarr"
    echo "     firefox http://localhost:8989  # Sonarr"
    echo ""
    echo "  3. If everything works, you can remove old configs:"
    echo "     sudo rm -rf /opt/stacks  # BE CAREFUL!"
    echo ""
    echo "  4. If something went wrong, restore from backup:"
    echo "     sudo tar xzf $BACKUP_DIR/new-configs-backup.tar.gz -C /var/lib/containers"
    echo ""
}

# Main execution
main() {
    print_header
    
    if ! confirm "This will migrate configs from Docker to Podman. Continue?"; then
        log_info "Migration cancelled"
        exit 0
    fi
    
    check_prerequisites
    create_backup
    
    if ! confirm "Stop running services to migrate configs?"; then
        log_error "Cannot migrate while services are running"
        exit 1
    fi
    
    stop_services
    migrate_all_services
    start_services
    
    show_summary
    
    log_success "Migration complete! 🎉"
}

# Run main function
main "$@"
