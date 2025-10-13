#!/usr/bin/env bash
# Automated flake update script with validation
# Updates all inputs and tests the configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
FLAKE_DIR="${FLAKE_DIR:-$HOME/.config/nix}"
DRY_RUN="${DRY_RUN:-false}"
SKIP_BUILD="${SKIP_BUILD:-false}"

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect current system
detect_system() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "darwin"
    else
        echo "nixos"
    fi
}

# Get hostname
get_hostname() {
    if [[ -f /etc/hostname ]]; then
        cat /etc/hostname
    else
        hostname -s
    fi
}

# Update flake inputs
update_inputs() {
    log_info "Updating flake inputs..."
    cd "$FLAKE_DIR"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would update inputs"
        nix flake metadata
        return 0
    fi
    
    # Update all inputs
    nix flake update
    
    # Show what changed
    log_info "Changes in flake.lock:"
    git diff flake.lock || true
}

# Validate flake
validate_flake() {
    log_info "Validating flake..."
    cd "$FLAKE_DIR"
    
    # Check flake
    nix flake check --no-build 2>&1 | tee /tmp/flake-check.log || {
        log_error "Flake validation failed"
        return 1
    }
    
    # Check for evaluation errors
    if grep -q "error:" /tmp/flake-check.log; then
        log_error "Evaluation errors found"
        return 1
    fi
    
    log_info "Flake validation passed"
    return 0
}

# Build configuration (test)
build_config() {
    if [[ "$SKIP_BUILD" == "true" ]]; then
        log_info "Skipping build test"
        return 0
    fi
    
    log_info "Testing build..."
    cd "$FLAKE_DIR"
    
    local system_type
    system_type=$(detect_system)
    local hostname
    hostname=$(get_hostname)
    
    if [[ "$system_type" == "darwin" ]]; then
        nix build ".#darwinConfigurations.${hostname}.system" --dry-run
    else
        nix build ".#nixosConfigurations.${hostname}.config.system.build.toplevel" --dry-run
    fi
    
    log_info "Build test passed"
    return 0
}

# Main update process
main() {
    log_info "Starting flake update process"
    log_info "Flake directory: $FLAKE_DIR"
    
    # Verify we're in a git repo
    if [[ ! -d "$FLAKE_DIR/.git" ]]; then
        log_error "Not a git repository: $FLAKE_DIR"
        exit 1
    fi
    
    # Check for uncommitted changes
    cd "$FLAKE_DIR"
    if ! git diff-index --quiet HEAD --; then
        log_warn "Uncommitted changes detected"
        log_warn "Continuing anyway..."
    fi
    
    # Update inputs
    update_inputs || {
        log_error "Failed to update inputs"
        exit 1
    }
    
    # Validate
    validate_flake || {
        log_error "Validation failed"
        log_warn "You may want to revert: git checkout flake.lock"
        exit 1
    }
    
    # Build test
    build_config || {
        log_error "Build test failed"
        log_warn "You may want to revert: git checkout flake.lock"
        exit 1
    }
    
    log_info "Update completed successfully!"
    log_info "Review changes with: git diff flake.lock"
    log_info "Commit with: git add flake.lock && git commit -m 'chore: update flake inputs'"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dry-run      Show what would be updated without making changes"
            echo "  --skip-build   Skip the build test"
            echo "  --help         Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  FLAKE_DIR      Path to flake directory (default: $HOME/.config/nix)"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

main
