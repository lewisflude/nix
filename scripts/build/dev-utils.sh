#!/usr/bin/env bash
# Development Utilities Toolkit
# Collection of productivity commands for Nix configuration development

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Helper functions
log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_section() { echo -e "\n${PURPLE}🔧 $1${NC}"; }

# Quick system rebuild with timing
quick_rebuild() {
  local hostname="${1:-jupiter}"
  log_section "Quick rebuild for $hostname"

  local start_time=$(date +%s)
  if nixos-rebuild build --flake ".#$hostname"; then
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log_success "Build completed in ${duration}s"

    # Ask if user wants to switch
    read -p "$(echo -e ${CYAN}Switch to new configuration? [y/N]: ${NC})" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      log_info "Switching to new configuration..."
      sudo nixos-rebuild switch --flake ".#$hostname"
      log_success "System updated!"
    fi
  else
    log_error "Build failed"
    return 1
  fi
}

# Show configuration diff
show_diff() {
  local hostname="${1:-jupiter}"
  log_section "Configuration diff for $hostname"

  if command -v nvd &> /dev/null; then
    sudo nvd diff /run/current-system "$(nixos-rebuild build --flake ".#$hostname" --print-out-paths)"
  else
    log_warning "nvd not found. Install it for better diffs: nix profile install nixpkgs#nvd"
    log_info "Showing basic diff..."
    nixos-rebuild build --flake ".#$hostname" 2>&1 | grep -E "(ADDED|REMOVED|CHANGED|SIZE)"
  fi
}

# Check configuration health
health_check() {
  log_section "System configuration health check"

  # Check flake syntax
  log_info "Checking flake syntax..."
  if nix flake check --no-build 2>/dev/null; then
    log_success "Flake syntax OK"
  else
    log_error "Flake syntax errors found"
    return 1
  fi

  # Check for common issues
  log_info "Checking for common issues..."

  # Check for uncommitted changes
  if ! git diff-index --quiet HEAD --; then
    log_warning "Uncommitted changes found"
    git status --short
  else
    log_success "Git working tree clean"
  fi

  # Check for large builds
  local store_size=$(du -sh /nix/store 2>/dev/null | cut -f1 || echo "unknown")
  log_info "Nix store size: $store_size"

  # Check for broken symlinks in home
  local broken_links=$(find ~ -xtype l 2>/dev/null | head -5)
  if [[ -n "$broken_links" ]]; then
    log_warning "Found broken symlinks in home:"
    echo "$broken_links"
  fi
}

# Development shell launcher with history
dev_shell() {
  local shell_type="$1"
  local project_dir="${2:-.}"

  log_section "Launching $shell_type development shell"

  # Create shell history
  local history_dir="$HOME/.cache/nix-shells"
  mkdir -p "$history_dir"
  echo "$(date): $shell_type in $project_dir" >> "$history_dir/history"

  # Launch shell
  cd "$project_dir"
  log_info "Entering development shell in $(pwd)"
  nix develop ~/.config/nix#"$shell_type"
}

# Performance monitoring
perf_monitor() {
  log_section "System performance monitoring"

  log_info "System load:"
  uptime

  log_info "Memory usage:"
  free -h | head -2

  log_info "Disk usage (important paths):"
  df -h / /home /nix 2>/dev/null | grep -v "tmpfs"

  log_info "Recent build times:"
  if [[ -f "$HOME/.cache/nix-shells/build-times" ]]; then
    tail -5 "$HOME/.cache/nix-shells/build-times"
  else
    log_warning "No build time history found"
  fi

  log_info "Active nix processes:"
  pgrep -af nix | head -5 || log_info "No active nix processes"
}

# Clean up development environment
cleanup() {
  log_section "Development environment cleanup"

  log_info "Collecting garbage..."
  nix-collect-garbage -d

  log_info "Optimizing store..."
  nix store optimise

  log_info "Cleaning shell caches..."
  rm -rf "$HOME/.cache/nix-shells/temp-*"

  # Clean old build artifacts
  find . -name "result*" -type l -delete 2>/dev/null || true

  log_success "Cleanup complete"
}

# Show available development environments
list_environments() {
  log_section "Available development environments"

  echo -e "${CYAN}Project-specific shells:${NC}"
  echo "  nextjs        - Next.js React framework"
  echo "  react-native  - React Native mobile apps"
  echo "  api-backend   - Backend API services"

  echo -e "\n${CYAN}Language shells:${NC}"
  echo "  node          - Node.js/TypeScript"
  echo "  python        - Python development"
  echo "  rust          - Rust development"
  echo "  go            - Go development"

  echo -e "\n${CYAN}Specialized shells:${NC}"
  echo "  web           - Full-stack web development"
  echo "  solana        - Blockchain/Solana development"
  echo "  devops        - DevOps/Infrastructure"

  echo -e "\n${CYAN}Utility shells:${NC}"
  echo "  shell-selector - Interactive shell selection"
}

# Main command dispatcher
main() {
  case "${1:-help}" in
    "rebuild"|"r")
      quick_rebuild "${2:-}"
      ;;
    "diff"|"d")
      show_diff "${2:-}"
      ;;
    "health"|"h")
      health_check
      ;;
    "shell"|"s")
      if [[ $# -lt 2 ]]; then
        log_error "Usage: $0 shell <shell-type> [directory]"
        list_environments
        exit 1
      fi
      dev_shell "${2}" "${3:-}"
      ;;
    "perf"|"p")
      perf_monitor
      ;;
    "clean"|"c")
      cleanup
      ;;
    "list"|"l")
      list_environments
      ;;
    "help"|*)
      echo -e "${PURPLE}🚀 Nix Development Utilities${NC}"
      echo
      echo "Usage: $0 <command> [args...]"
      echo
      echo "Commands:"
      echo "  rebuild, r [host]     - Quick rebuild with timing and switch option"
      echo "  diff, d [host]        - Show configuration differences"
      echo "  health, h             - Check configuration health"
      echo "  shell, s <type> [dir] - Launch development shell"
      echo "  perf, p               - Monitor system performance"
      echo "  clean, c              - Clean up development environment"
      echo "  list, l               - List available development environments"
      echo "  help                  - Show this help message"
      echo
      echo "Examples:"
      echo "  $0 rebuild jupiter    - Rebuild jupiter configuration"
      echo "  $0 shell nextjs       - Launch Next.js development shell"
      echo "  $0 health             - Check system health"
      ;;
  esac
}

# Run main function with all arguments
main "$@"
