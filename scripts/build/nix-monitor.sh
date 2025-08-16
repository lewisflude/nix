#!/usr/bin/env bash
# Nix System Monitor and Optimizer
# Monitor and optimize Nix-related system performance

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_section() { echo -e "\n${PURPLE}📊 $1${NC}"; }

# System overview
system_overview() {
  log_section "System Overview"

  echo -e "${CYAN}Hostname:${NC} $(hostname)"
  echo -e "${CYAN}Uptime:${NC} $(uptime -p)"
  echo -e "${CYAN}Load Average:${NC} $(cut -d' ' -f1-3 < /proc/loadavg)"

  # Memory information
  local mem_info=$(free -h | awk 'NR==2{printf "Used: %s/%s (%.2f%%)", $3,$2,$3*100/$2}')
  echo -e "${CYAN}Memory:${NC} $mem_info"

  # Disk space for important paths
  echo -e "${CYAN}Disk Usage:${NC}"
  df -h / /home /nix 2>/dev/null | tail -n +2 | while read -r line; do
    local usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
    local mount=$(echo "$line" | awk '{print $6}')
    local used=$(echo "$line" | awk '{print $3}')
    local total=$(echo "$line" | awk '{print $2}')

    if [[ $usage -gt 90 ]]; then
      echo -e "  ${RED}$mount: $used/$total (${usage}%)${NC}"
    elif [[ $usage -gt 80 ]]; then
      echo -e "  ${YELLOW}$mount: $used/$total (${usage}%)${NC}"
    else
      echo -e "  ${GREEN}$mount: $used/$total (${usage}%)${NC}"
    fi
  done
}

# Nix store analysis
nix_store_analysis() {
  log_section "Nix Store Analysis"

  # Store size and file count
  if [[ -d "/nix/store" ]]; then
    log_info "Calculating Nix store size..."
    local store_size=$(du -sh /nix/store 2>/dev/null | cut -f1 || echo "unknown")
    local store_items=$(ls /nix/store 2>/dev/null | wc -l || echo "unknown")
    echo -e "${CYAN}Store Size:${NC} $store_size"
    echo -e "${CYAN}Store Items:${NC} $store_items"

    # Dead paths
    log_info "Checking for dead paths..."
    local dead_paths=$(nix-store --gc --print-dead 2>/dev/null | wc -l || echo "0")
    echo -e "${CYAN}Dead Paths:${NC} $dead_paths"

    if [[ "$dead_paths" -gt 100 ]]; then
      log_warning "Many dead paths found. Consider running garbage collection."
    fi

    # Recent build outputs
    log_info "Recent build outputs:"
    find /nix/store -name "*.drv" -newer /nix/store/.cleanup-marker 2>/dev/null | head -5 | while read -r path; do
      echo "  $(basename "$path")"
    done || echo "  No recent builds found"

  else
    log_warning "Nix store not found at /nix/store"
  fi
}

# Build performance tracking
build_performance() {
  log_section "Build Performance Tracking"

  local build_log="$HOME/.cache/nix-builds/build-history.log"
  local build_cache_dir="$HOME/.cache/nix-builds"

  mkdir -p "$build_cache_dir"

  if [[ -f "$build_log" ]]; then
    echo -e "${CYAN}Recent Build Times:${NC}"
    tail -10 "$build_log" | while read -r line; do
      echo "  $line"
    done

    echo -e "\n${CYAN}Average Build Time (last 10):${NC}"
    local avg_time=$(tail -10 "$build_log" | awk '{sum += $3; count++} END {if (count > 0) printf "%.1fs", sum/count}')
    echo "  $avg_time"

    # Longest builds
    echo -e "\n${CYAN}Slowest Builds Today:${NC}"
    local today=$(date +%Y-%m-%d)
    grep "^$today" "$build_log" 2>/dev/null | sort -k3 -nr | head -3 | while read -r line; do
      echo "  $line"
    done
  else
    log_info "No build history found"
    echo "Build tracking will start with next rebuild"
    echo "# Date Time Duration Host Result" > "$build_log"
  fi
}

# Process monitoring
process_monitor() {
  log_section "Process Monitoring"

  # Nix processes
  echo -e "${CYAN}Active Nix Processes:${NC}"
  local nix_procs=$(pgrep -af nix || true)
  if [[ -n "$nix_procs" ]]; then
    echo "$nix_procs" | head -5
  else
    echo "  No active Nix processes"
  fi

  # High CPU processes
  echo -e "\n${CYAN}Top CPU Processes:${NC}"
  ps aux --sort=-%cpu | head -6 | tail -5 | while read -r line; do
    local cpu=$(echo "$line" | awk '{print $3}')
    local cmd=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}')
    echo "  ${cpu}% - $cmd"
  done

  # High memory processes
  echo -e "\n${CYAN}Top Memory Processes:${NC}"
  ps aux --sort=-%mem | head -6 | tail -5 | while read -r line; do
    local mem=$(echo "$line" | awk '{print $4}')
    local cmd=$(echo "$line" | awk '{for(i=11;i<=NF;i++) printf "%s ", $i; print ""}')
    echo "  ${mem}% - $cmd"
  done
}

# Configuration health check
config_health() {
  log_section "Configuration Health Check"

  # Git status
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    echo -e "${CYAN}Git Status:${NC}"
    if git diff-index --quiet HEAD --; then
      log_success "Working tree clean"
    else
      log_warning "Uncommitted changes found"
      git status --short | head -5
    fi

    # Recent commits
    echo -e "\n${CYAN}Recent Commits:${NC}"
    git log --oneline -5 | while read -r line; do
      echo "  $line"
    done
  fi

  # Flake lock status
  if [[ -f "flake.lock" ]]; then
    echo -e "\n${CYAN}Flake Status:${NC}"
    local lock_age=$(find flake.lock -mtime +7 2>/dev/null || true)
    if [[ -n "$lock_age" ]]; then
      log_warning "Flake lock is older than 7 days"
      echo "  Consider running: nix flake update"
    else
      log_success "Flake lock is recent"
    fi

    # Show locked inputs
    echo -e "\n${CYAN}Locked Inputs:${NC}"
    jq -r '.nodes.root.inputs | keys[]' flake.lock 2>/dev/null | head -5 | while read -r input; do
      local rev=$(jq -r ".nodes.\"$input\".locked.rev // \"N/A\"" flake.lock 2>/dev/null | cut -c1-7)
      echo "  $input: $rev"
    done
  fi
}

# Optimization suggestions
optimization_suggestions() {
  log_section "Optimization Suggestions"

  local suggestions=()

  # Check store size
  local store_size_gb=$(du -s /nix/store 2>/dev/null | awk '{print int($1/1024/1024)}' || echo "0")
  if [[ $store_size_gb -gt 50 ]]; then
    suggestions+=("🗑️  Nix store is large (${store_size_gb}GB). Consider: nix-collect-garbage -d")
  fi

  # Check dead paths
  local dead_count=$(nix-store --gc --print-dead 2>/dev/null | wc -l || echo "0")
  if [[ $dead_count -gt 500 ]]; then
    suggestions+=("🧹 Many dead paths ($dead_count). Run: nix-collect-garbage")
  fi

  # Check memory usage
  local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
  if [[ $mem_usage -gt 90 ]]; then
    suggestions+=("💾 High memory usage (${mem_usage}%). Consider closing applications during builds")
  fi

  # Check build cache
  if [[ ! -f "$HOME/.cache/nix-builds/build-history.log" ]]; then
    suggestions+=("📊 Enable build tracking by running rebuilds through dev-utils.sh")
  fi

  # Display suggestions
  if [[ ${#suggestions[@]} -gt 0 ]]; then
    for suggestion in "${suggestions[@]}"; do
      echo "  $suggestion"
    done
  else
    log_success "No optimization suggestions at this time"
  fi
}

# Interactive cleanup
interactive_cleanup() {
  log_section "Interactive Cleanup"

  echo "Available cleanup options:"
  echo "1. Garbage collect old generations"
  echo "2. Optimize Nix store (deduplicate)"
  echo "3. Clean build caches"
  echo "4. Remove old result symlinks"
  echo "5. All of the above"
  echo

  read -p "Select option (1-5, or Enter to skip): " choice

  case "$choice" in
    1)
      log_info "Running garbage collection..."
      nix-collect-garbage -d
      log_success "Garbage collection complete"
      ;;
    2)
      log_info "Optimizing Nix store..."
      nix store optimise
      log_success "Store optimization complete"
      ;;
    3)
      log_info "Cleaning build caches..."
      rm -rf ~/.cache/nix-shells/temp-* ~/.cache/nix-builds/temp-*
      log_success "Build caches cleaned"
      ;;
    4)
      log_info "Removing old result symlinks..."
      find . -name "result*" -type l -delete 2>/dev/null || true
      log_success "Result symlinks removed"
      ;;
    5)
      log_info "Running full cleanup..."
      nix-collect-garbage -d
      nix store optimise
      rm -rf ~/.cache/nix-shells/temp-* ~/.cache/nix-builds/temp-*
      find . -name "result*" -type l -delete 2>/dev/null || true
      log_success "Full cleanup complete"
      ;;
    "")
      log_info "Skipping cleanup"
      ;;
    *)
      log_warning "Invalid option"
      ;;
  esac
}

# Main function
main() {
  echo -e "${PURPLE}🔍 Nix System Monitor${NC}"
  echo "Generated at: $(date)"

  case "${1:-overview}" in
    "overview"|"o")
      system_overview
      nix_store_analysis
      ;;
    "store"|"s")
      nix_store_analysis
      ;;
    "performance"|"perf"|"p")
      build_performance
      process_monitor
      ;;
    "health"|"h")
      config_health
      optimization_suggestions
      ;;
    "cleanup"|"c")
      interactive_cleanup
      ;;
    "full"|"f")
      system_overview
      nix_store_analysis
      build_performance
      process_monitor
      config_health
      optimization_suggestions
      ;;
    "help"|*)
      echo
      echo "Usage: $0 <command>"
      echo
      echo "Commands:"
      echo "  overview, o   - System and store overview (default)"
      echo "  store, s      - Detailed Nix store analysis"
      echo "  performance, p - Build performance and process monitoring"
      echo "  health, h     - Configuration health and suggestions"
      echo "  cleanup, c    - Interactive cleanup options"
      echo "  full, f       - Complete system analysis"
      echo "  help          - Show this help"
      ;;
  esac
}

main "$@"
