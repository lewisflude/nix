#!/usr/bin/env bash
# Comprehensive Build Profiling Tool
# Analyzes what takes the most time in your NixOS/nix-darwin configuration
# Usage: ./scripts/utils/profile-build.sh [config-name] [--full]

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly PURPLE='\033[0;35m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

# Detect system and configuration
detect_config() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "darwinConfigurations.$(hostname -s)"
  else
    echo "nixosConfigurations.$(hostname)"
  fi
}

# Parse arguments - handle --full flag in any position
CONFIG=""
FULL_PROFILE=""
for arg in "$@"; do
  if [[ "$arg" == "--full" ]] || [[ "$arg" == "-f" ]]; then
    FULL_PROFILE="--full"
  elif [[ "$arg" == "--help" ]] || [[ "$arg" == "-h" ]]; then
    # Help is handled later
    continue
  elif [[ -z "$CONFIG" ]] && [[ "$arg" != "--" ]]; then
    CONFIG="$arg"
  fi
done

# Default to auto-detected config if not provided
if [[ -z "$CONFIG" ]]; then
  CONFIG=$(detect_config)
fi

# Get the correct output path based on platform
get_output_path() {
  local config="$1"
  if [[ "$config" == darwinConfigurations.* ]]; then
    echo ".$config.system"
  else
    echo ".$config.config.system.build.toplevel"
  fi
}

OUTPUT_PATH=$(get_output_path "$CONFIG")
# For nix build, we need the path without the leading dot
BUILD_PATH=$(echo "$OUTPUT_PATH" | sed 's/^\.//')

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_section() { echo -e "\n${PURPLE}${BOLD}📊 $1${NC}"; }
log_subsection() { echo -e "\n${CYAN}▶ $1${NC}"; }

# Timing helper
get_time() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v gdate &> /dev/null; then
      gdate +%s%N
    else
      date +%s
    fi
  else
    date +%s%N
  fi
}

format_duration() {
  local ms="$1"
  if [[ $ms -lt 1000 ]]; then
    echo "${ms}ms"
  elif [[ $ms -lt 60000 ]]; then
    local sec=$((ms / 1000))
    local remainder=$((ms % 1000))
    echo "${sec}.${remainder}s"
  else
    local min=$((ms / 60000))
    local sec=$(((ms % 60000) / 1000))
    echo "${min}m ${sec}s"
  fi
}

# 1. Evaluation Time Analysis
profile_evaluation() {
  log_section "Evaluation Time Analysis"

  log_subsection "Measuring total evaluation time..."
  local start=$(get_time)
  nix eval --raw ".#$OUTPUT_PATH" 2>&1 > /dev/null || true
  local end=$(get_time)

  if [[ "$OSTYPE" == "darwin"* ]] && ! command -v gdate &> /dev/null; then
    local duration=$(( (end - start) * 1000 ))
  else
    local duration=$(( (end - start) / 1000000 ))
  fi

  echo -e "  ${GREEN}Total evaluation time: ${BOLD}$(format_duration $duration)${NC}"

  # Check if jq is available for parsing
  if command -v jq &> /dev/null; then
    log_subsection "Counting system packages..."
    # Use the correct path based on platform
    local pkg_path
    if [[ "$CONFIG" == darwinConfigurations.* ]]; then
      pkg_path=".#$CONFIG.environment.systemPackages"
    else
      pkg_path=".#$CONFIG.config.environment.systemPackages"
    fi
    # Suppress errors and only show if successful
    local pkg_result=$(nix eval "$pkg_path" --apply 'x: builtins.length x' 2>/dev/null)
    if [[ -n "$pkg_result" ]] && [[ "$pkg_result" =~ ^[0-9]+$ ]]; then
      echo -e "  ${CYAN}System packages: ${BOLD}$pkg_result${NC}"
    else
      # Silently skip if evaluation fails
      echo -e "  ${YELLOW}System packages: ${BOLD}(unavailable)${NC}"
    fi
  fi

  echo "$duration"
}

# 2. Build Planning Analysis
profile_build_planning() {
  log_section "Build Planning Analysis"

  log_subsection "Analyzing what would be built (dry-run)..."
  local start=$(get_time)
  local build_json=$(mktemp)
  nix build ".#$BUILD_PATH" --dry-run --json 2>&1 > "$build_json" || true
  local end=$(get_time)

  if [[ "$OSTYPE" == "darwin"* ]] && ! command -v gdate &> /dev/null; then
    local duration=$(( (end - start) * 1000 ))
  else
    local duration=$(( (end - start) / 1000000 ))
  fi

  echo -e "  ${GREEN}Build planning time: ${BOLD}$(format_duration $duration)${NC}"

  if command -v jq &> /dev/null && [[ -s "$build_json" ]]; then
    local drv_count=$(jq '[.[] | .drvPath] | length' "$build_json" 2>/dev/null || echo "0")
    echo -e "  ${CYAN}Total derivations: ${BOLD}$drv_count${NC}"

    if [[ "$FULL_PROFILE" == "--full" ]]; then
      log_subsection "Derivation breakdown:"
      echo "  Analyzing derivation sizes..."

      # Get closure sizes for each derivation
      local sizes_file=$(mktemp)
      jq -r '.[] | .outputs.out // .drvPath' "$build_json" 2>/dev/null | \
        while read -r path; do
          if [[ -n "$path" ]]; then
            local size=$(nix path-info -S "$path" 2>/dev/null | awk '{print $2}' || echo "0")
            echo "$size $path" >> "$sizes_file"
          fi
        done

      if [[ -s "$sizes_file" ]]; then
        echo -e "\n  ${YELLOW}Top 10 largest derivations by closure size:${NC}"
        sort -rn "$sizes_file" | head -10 | \
          awk '{size=$1; $1=""; printf "  %8s  %s\n", size, $0}' | \
          sed 's/^  \([0-9]*\)/  \1 bytes/'
      fi

      rm -f "$sizes_file"
    fi

    rm -f "$build_json"
  else
    log_warning "jq not available or build analysis failed - install jq for detailed analysis"
  fi

  echo "$duration"
}

# 3. Module Import Analysis
profile_module_imports() {
  log_section "Module Import Analysis"

  if ! command -v jq &> /dev/null; then
    log_warning "jq not available - skipping module analysis"
    return
  fi

  log_subsection "Counting modules..."

  # Count NixOS modules
  local nixos_modules=0
  if [[ -d "modules/nixos" ]]; then
    nixos_modules=$(find modules/nixos -name "*.nix" -type f | wc -l)
  fi

  # Count darwin modules
  local darwin_modules=0
  if [[ -d "modules/darwin" ]]; then
    darwin_modules=$(find modules/darwin -name "*.nix" -type f | wc -l)
  fi

  # Count shared modules
  local shared_modules=0
  if [[ -d "modules/shared" ]]; then
    shared_modules=$(find modules/shared -name "*.nix" -type f | wc -l)
  fi

  echo -e "  ${CYAN}NixOS modules: ${BOLD}$nixos_modules${NC}"
  echo -e "  ${CYAN}Darwin modules: ${BOLD}$darwin_modules${NC}"
  echo -e "  ${CYAN}Shared modules: ${BOLD}$shared_modules${NC}"
  echo -e "  ${CYAN}Total modules: ${BOLD}$((nixos_modules + darwin_modules + shared_modules))${NC}"
}

# 4. Dependency Analysis
profile_dependencies() {
  log_section "Dependency Analysis"

  log_subsection "Analyzing build dependencies..."

  if command -v jq &> /dev/null; then
    local build_json=$(mktemp)
    # Use BUILD_PATH instead of CONFIG to avoid the type error
    nix build ".#$BUILD_PATH" --dry-run --json 2>&1 > "$build_json" || true

    if [[ -s "$build_json" ]]; then
      # Count unique derivation paths
      local unique_drvs=$(jq '[.[] | .drvPath] | unique | length' "$build_json" 2>/dev/null || echo "0")
      echo -e "  ${CYAN}Unique derivations: ${BOLD}$unique_drvs${NC}"

      # Try to identify common packages
      log_subsection "Common package patterns:"
      jq -r '.[] | .drvPath' "$build_json" 2>/dev/null | \
        sed 's|.*/||' | \
        sed 's|-.*||' | \
        sort | uniq -c | sort -rn | head -10 | \
        awk '{printf "  %3d× %s\n", $1, $2}'

      rm -f "$build_json"
    else
      log_warning "Could not analyze dependencies - build dry-run failed"
    fi
  else
    log_warning "jq not available - skipping dependency analysis"
  fi
}

# 5. Store Analysis
profile_store() {
  log_section "Nix Store Analysis"

  if [[ ! -d "/nix/store" ]]; then
    log_warning "Nix store not found at /nix/store"
    return
  fi

  log_subsection "Store statistics..."

  local store_size=$(du -sh /nix/store 2>/dev/null | cut -f1 || echo "unknown")
  local store_items=$(ls /nix/store 2>/dev/null | wc -l || echo "unknown")

  echo -e "  ${CYAN}Store size: ${BOLD}$store_size${NC}"
  echo -e "  ${CYAN}Store items: ${BOLD}$store_items${NC}"

  # Check for dead paths
  local dead_paths=$(nix-store --gc --print-dead 2>/dev/null | wc -l || echo "0")
  echo -e "  ${CYAN}Dead paths: ${BOLD}$dead_paths${NC}"

  if [[ "$dead_paths" -gt 100 ]]; then
    log_warning "Many dead paths found - consider running: nix-collect-garbage -d"
  fi
}

# 6. Performance Recommendations
show_recommendations() {
  log_section "Performance Recommendations"

  local recommendations=()

  # Check evaluation time - capture duration separately
  local eval_output=$(profile_evaluation 2>&1)
  local eval_time=$(echo "$eval_output" | grep -E "^[0-9]+$" | tail -1)

  if [[ -n "$eval_time" ]] && [[ $eval_time -gt 5000 ]]; then
    recommendations+=("Evaluation time is high ($(format_duration $eval_time)) - consider optimizing module imports")
  fi

  # Check derivation count
  if command -v jq &> /dev/null; then
    local build_json=$(mktemp)
    nix build ".#$BUILD_PATH" --dry-run --json 2>&1 > "$build_json" || true
    if [[ -s "$build_json" ]]; then
      local drv_count=$(jq '[.[] | .drvPath] | length' "$build_json" 2>/dev/null || echo "0")
      if [[ $drv_count -gt 1000 ]]; then
        recommendations+=("High derivation count ($drv_count) - many packages to build")
      fi
    fi
    rm -f "$build_json"
  fi

  # Check Cachix
  if ! grep -q "cachix" /etc/nix/nix.conf 2>/dev/null && ! grep -q "cachix" ~/.config/nix/nix.conf 2>/dev/null; then
    recommendations+=("Consider setting up Cachix for faster builds: nix run .#setup-cachix")
  fi

  # Check store optimization
  local dead_paths=$(nix-store --gc --print-dead 2>/dev/null | wc -l || echo "0")
  if [[ $dead_paths -gt 500 ]]; then
    recommendations+=("Many dead paths ($dead_paths) - run: nix-collect-garbage -d")
  fi

  if [[ ${#recommendations[@]} -eq 0 ]]; then
    log_success "No major optimizations needed!"
  else
    for rec in "${recommendations[@]}"; do
      echo -e "  ${YELLOW}•${NC} $rec"
    done
  fi
}

# 7. Quick Summary
show_summary() {
  log_section "Summary"

  echo -e "${BOLD}Configuration:${NC} $CONFIG"
  echo -e "${BOLD}Output path:${NC} $OUTPUT_PATH"
  echo ""

  # Measure evaluation time silently
  log_subsection "Measuring evaluation time..."
  local start=$(get_time)
  nix eval --raw ".#$OUTPUT_PATH" 2>&1 > /dev/null || true
  local end=$(get_time)

  if [[ "$OSTYPE" == "darwin"* ]] && ! command -v gdate &> /dev/null; then
    local eval_time=$(( (end - start) * 1000 ))
  else
    local eval_time=$(( (end - start) / 1000000 ))
  fi

  echo -e "  ${GREEN}Evaluation time: ${BOLD}$(format_duration $eval_time)${NC}"

  # Count system packages if available
  if command -v jq &> /dev/null; then
    local pkg_path
    if [[ "$CONFIG" == darwinConfigurations.* ]]; then
      pkg_path=".#$CONFIG.environment.systemPackages"
    else
      pkg_path=".#$CONFIG.config.environment.systemPackages"
    fi
    local pkg_result=$(nix eval "$pkg_path" --apply 'x: builtins.length x' 2>/dev/null)
    if [[ -n "$pkg_result" ]] && [[ "$pkg_result" =~ ^[0-9]+$ ]]; then
      echo -e "  ${CYAN}System packages: ${BOLD}$pkg_result${NC}"
    fi
  fi

  # Count derivations - use the output path for building
  if command -v jq &> /dev/null; then
    local build_json=$(mktemp)
    # Use the build path (without leading dot)
    nix build ".#$BUILD_PATH" --dry-run --json 2>&1 > "$build_json" || true
    if [[ -s "$build_json" ]]; then
      local drv_count=$(jq '[.[] | .drvPath] | length' "$build_json" 2>/dev/null || echo "0")
      echo -e "  ${CYAN}Derivations to build: ${BOLD}$drv_count${NC}"
    fi
    rm -f "$build_json"
  fi
}

# Main execution
main() {
  echo -e "${PURPLE}${BOLD}🔍 Nix Build Profiler${NC}"
  echo -e "${BLUE}Analyzing: ${GREEN}$CONFIG${NC}"
  echo ""

  if [[ "$FULL_PROFILE" == "--full" ]]; then
    log_info "Running full profile analysis..."
    profile_evaluation
    profile_build_planning
    profile_module_imports
    profile_dependencies
    profile_store
    show_recommendations
  else
    show_summary
    echo ""
    log_info "Run with --full flag for detailed analysis:"
    echo "  $0 $CONFIG --full"
  fi

  echo ""
  log_success "Profile complete!"
}

# Handle arguments
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
  echo "Usage: $0 [config-name] [--full]"
  echo ""
  echo "Analyzes build performance for your Nix configuration."
  echo ""
  echo "Arguments:"
  echo "  config-name    Configuration to profile (default: auto-detect)"
  echo "  --full         Run detailed analysis including dependency breakdown"
  echo ""
  echo "Examples:"
  echo "  $0                                    # Quick profile of current system"
  echo "  $0 --full                            # Full profile of current system"
  echo "  $0 nixosConfigurations.jupiter       # Profile specific config"
  echo "  $0 nixosConfigurations.jupiter --full # Full profile of specific config"
  exit 0
fi

main "$@"
