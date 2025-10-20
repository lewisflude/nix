#!/usr/bin/env bash
# Migration script: Container data → Native NixOS services
# Migrates data from /var/lib/containers/* to native service directories

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_BASE="/var/lib/containers/media-management"
BACKUP_DIR="/var/lib/container-backups-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --help)
      echo "Usage: $0 [--dry-run]"
      echo ""
      echo "Migrates container data to native NixOS service directories"
      echo ""
      echo "Options:"
      echo "  --dry-run    Show what would be done without making changes"
      echo "  --help       Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

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

check_root() {
  if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
  fi
}

create_backup() {
  local service=$1
  local source=$2
  
  if [[ ! -d "$source" ]]; then
    log_warning "Source directory $source does not exist, skipping backup"
    return 1
  fi
  
  log_info "Creating backup of $service data..."
  
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY RUN] Would create backup: $BACKUP_DIR/$service"
    return 0
  fi
  
  mkdir -p "$BACKUP_DIR"
  cp -a "$source" "$BACKUP_DIR/$service"
  log_success "Backup created at $BACKUP_DIR/$service"
}

stop_service() {
  local service=$1
  
  log_info "Stopping $service..."
  
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY RUN] Would stop: systemctl stop $service"
    return 0
  fi
  
  if systemctl is-active --quiet "$service"; then
    systemctl stop "$service"
    log_success "$service stopped"
  else
    log_info "$service is not running"
  fi
}

migrate_service_data() {
  local service=$1
  local container_path=$2
  local native_path=$3
  local user=$4
  local group=$5
  
  log_info "Migrating $service data..."
  log_info "  From: $container_path"
  log_info "  To: $native_path"
  
  if [[ ! -d "$container_path" ]]; then
    log_warning "Container data not found at $container_path, skipping"
    return 0
  fi
  
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY RUN] Would copy: $container_path/* → $native_path/"
    log_info "[DRY RUN] Would chown: $user:$group $native_path"
    return 0
  fi
  
  # Ensure destination exists
  mkdir -p "$native_path"
  
  # Copy data
  cp -a "$container_path"/* "$native_path/" 2>/dev/null || {
    # If directory is empty or only has hidden files
    if [[ -n "$(ls -A "$container_path" 2>/dev/null)" ]]; then
      cp -a "$container_path"/.[!.]* "$native_path/" 2>/dev/null || true
    fi
  }
  
  # Fix permissions
  chown -R "$user:$group" "$native_path"
  
  log_success "$service data migrated"
}

start_service() {
  local service=$1
  
  log_info "Starting $service..."
  
  if [[ "$DRY_RUN" == "true" ]]; then
    log_info "[DRY RUN] Would start: systemctl start $service"
    return 0
  fi
  
  systemctl start "$service"
  
  # Wait a moment and check status
  sleep 2
  if systemctl is-active --quiet "$service"; then
    log_success "$service started successfully"
  else
    log_error "$service failed to start - check logs: journalctl -u $service"
  fi
}

migrate_media_service() {
  local service=$1
  local container_name=$2
  local user=${3:-media}
  local group=${4:-media}
  
  echo ""
  log_info "=== Migrating $service ==="
  
  # Stop both old container and new service
  stop_service "podman-$container_name" || true
  stop_service "$service"
  
  # Create backup
  create_backup "$service" "$CONTAINER_BASE/$container_name" || return 0
  
  # Migrate data
  migrate_service_data "$service" \
    "$CONTAINER_BASE/$container_name" \
    "/var/lib/$service" \
    "$user" "$group"
  
  # Start new service
  start_service "$service"
}

# Main migration
main() {
  check_root
  
  echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║  Container to Native NixOS Services Data Migration        ║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  
  if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "DRY RUN MODE - No changes will be made"
    echo ""
  fi
  
  log_info "Container base: $CONTAINER_BASE"
  log_info "Backup location: $BACKUP_DIR"
  echo ""
  
  # Check if container data exists
  if [[ ! -d "$CONTAINER_BASE" ]]; then
    log_error "Container data directory not found: $CONTAINER_BASE"
    log_info "If you've already migrated or don't have container data, this is normal."
    exit 1
  fi
  
  # Confirm before proceeding
  if [[ "$DRY_RUN" == "false" ]]; then
    echo -e "${YELLOW}This will:${NC}"
    echo "  1. Stop all container and native services"
    echo "  2. Backup container data to $BACKUP_DIR"
    echo "  3. Copy data to native service directories"
    echo "  4. Fix permissions for media user/group"
    echo "  5. Start native services"
    echo ""
    read -p "Continue? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
      log_info "Migration cancelled"
      exit 0
    fi
    echo ""
  fi
  
  # Migrate media management services
  log_info "=== Starting Media Management Migration ==="
  
  migrate_media_service "prowlarr" "prowlarr"
  migrate_media_service "radarr" "radarr"
  migrate_media_service "sonarr" "sonarr"
  migrate_media_service "lidarr" "lidarr"
  migrate_media_service "readarr" "readarr"
  
  # Whisparr (if exists)
  if [[ -d "$CONTAINER_BASE/whisparr" ]]; then
    migrate_media_service "whisparr" "whisparr"
  fi
  
  # qBittorrent (note: different user in container)
  migrate_media_service "qbittorrent" "qbittorrent"
  
  # SABnzbd
  migrate_media_service "sabnzbd" "sabnzbd"
  
  # Jellyfin
  echo ""
  log_info "=== Migrating jellyfin ==="
  stop_service "podman-jellyfin" || true
  stop_service "jellyfin"
  
  if [[ -d "$CONTAINER_BASE/jellyfin/config" ]]; then
    create_backup "jellyfin-config" "$CONTAINER_BASE/jellyfin/config"
    migrate_service_data "jellyfin-config" \
      "$CONTAINER_BASE/jellyfin/config" \
      "/var/lib/jellyfin" \
      "media" "media"
  fi
  
  if [[ -d "$CONTAINER_BASE/jellyfin/cache" ]]; then
    create_backup "jellyfin-cache" "$CONTAINER_BASE/jellyfin/cache"
    # Cache can be regenerated, but migrate it anyway
    mkdir -p /var/cache/jellyfin
    if [[ "$DRY_RUN" == "false" ]]; then
      cp -a "$CONTAINER_BASE/jellyfin/cache"/* /var/cache/jellyfin/ 2>/dev/null || true
      chown -R media:media /var/cache/jellyfin
    fi
  fi
  
  start_service "jellyfin"
  
  # Jellyseerr
  migrate_media_service "jellyseerr" "jellyseerr"
  
  # Unpackerr (custom service, not standard systemd)
  if [[ -d "$CONTAINER_BASE/unpackerr" ]]; then
    echo ""
    log_info "=== Migrating unpackerr ==="
    stop_service "unpackerr" || true
    
    create_backup "unpackerr" "$CONTAINER_BASE/unpackerr"
    
    # Unpackerr mainly uses config file, less state
    log_info "Unpackerr uses minimal state - config is in NixOS now"
    log_info "Old container config backed up to $BACKUP_DIR/unpackerr"
  fi
  
  # Productivity stack (Ollama, OpenWebUI)
  local PROD_BASE="/var/lib/containers/productivity"
  
  if [[ -d "$PROD_BASE/ollama" ]]; then
    echo ""
    log_info "=== Migrating ollama ==="
    stop_service "podman-ollama" || true
    stop_service "ollama"
    
    create_backup "ollama" "$PROD_BASE/ollama"
    migrate_service_data "ollama" \
      "$PROD_BASE/ollama" \
      "/var/lib/ollama" \
      "aitools" "aitools"
    
    start_service "ollama"
  fi
  
  if [[ -d "$PROD_BASE/openwebui" ]]; then
    echo ""
    log_info "=== Migrating open-webui ==="
    stop_service "podman-openwebui" || true
    stop_service "open-webui"
    
    create_backup "open-webui" "$PROD_BASE/openwebui"
    migrate_service_data "open-webui" \
      "$PROD_BASE/openwebui" \
      "/var/lib/open-webui" \
      "aitools" "aitools"
    
    start_service "open-webui"
  fi
  
  echo ""
  echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║  Migration Complete!                                       ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  
  if [[ "$DRY_RUN" == "false" ]]; then
    log_success "All data has been migrated"
    log_success "Backups saved to: $BACKUP_DIR"
    echo ""
    log_info "Next steps:"
    echo "  1. Check service status: systemctl status prowlarr radarr sonarr jellyfin"
    echo "  2. Verify data in web UIs"
    echo "  3. Check logs if any issues: journalctl -u <service-name>"
    echo "  4. Once confirmed working, you can remove old container directories"
    echo "  5. Keep backups in $BACKUP_DIR"
  else
    log_info "This was a dry run - no changes were made"
    log_info "Run without --dry-run to perform actual migration"
  fi
}

main "$@"
