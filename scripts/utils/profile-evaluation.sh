#!/usr/bin/env bash
# Profile evaluation time to identify slow modules and features
# Usage: ./scripts/utils/profile-evaluation.sh [config-name] [--compare]
#
# This script helps identify which modules or features are causing slow evaluation times.
# It can test evaluation time with different module combinations disabled.

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

CONFIG="${1:-$(detect_config)}"
COMPARE_MODE="${2:-}"

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

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }
log_section() { echo -e "\n${PURPLE}${BOLD}📊 $1${NC}"; }
log_subsection() { echo -e "\n${CYAN}▶ $1${NC}"; }

# Measure evaluation time
measure_evaluation() {
  local label="${1:-Evaluation}"
  local quiet="${2:-false}"

  if [[ "$quiet" == "true" ]]; then
    # Run quietly and capture output
    local start=$(date +%s%N 2>/dev/null || date +%s)
    nix eval --raw ".#$OUTPUT_PATH" >/dev/null 2>&1 || true
    local end=$(date +%s%N 2>/dev/null || date +%s)
  else
    log_subsection "Measuring $label..." >&2
    local start=$(date +%s%N 2>/dev/null || date +%s)
    # Capture nix output to stderr so it doesn't interfere with duration output
    nix eval --raw ".#$OUTPUT_PATH" 2>&1 | grep -v "^warning:" >&2 || true
    local end=$(date +%s%N 2>/dev/null || date +%s)
  fi

  # Calculate duration (handle both nanosecond and second precision)
  if command -v date &> /dev/null && date +%s%N >/dev/null 2>&1; then
    local duration=$(( (end - start) / 1000000 ))
  else
    # Fallback for systems without nanosecond precision
    local duration=$(( (end - start) * 1000 ))
  fi

  # Output only the duration number (no other output)
  echo "$duration"
}

# Format duration in milliseconds to human-readable
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

# Baseline evaluation
baseline_evaluation() {
  log_section "Baseline Evaluation Time"

  log_info "Running baseline evaluation (this may take 20-30 seconds)..."
  local duration=$(measure_evaluation "baseline")

  echo -e "  ${GREEN}Baseline evaluation time: ${BOLD}$(format_duration $duration)${NC}"

  # Provide context
  if [[ $duration -lt 2000 ]]; then
    log_success "Excellent! (< 2 seconds)"
  elif [[ $duration -lt 5000 ]]; then
    log_info "Good (2-5 seconds)"
  elif [[ $duration -lt 10000 ]]; then
    log_warning "Acceptable (5-10 seconds) - consider optimization"
  else
    log_error "Slow (> 10 seconds) - needs optimization"
  fi

  echo "$duration"
}

# Compare evaluation with different module combinations
compare_evaluations() {
  log_section "Comparison Mode"

  log_warning "This mode requires manual testing by temporarily disabling modules"
  log_info "To use this feature:"
  echo ""
  echo "  1. Make a backup of your configuration:"
  echo "     cp hosts/jupiter/default.nix hosts/jupiter/default.nix.backup"
  echo ""
  echo "  2. Temporarily disable a feature in hosts/jupiter/default.nix:"
  echo "     # Comment out: mediaManagement = { enable = true; ... };"
  echo ""
  echo "  3. Run this script again to compare:"
  echo "     $0 $CONFIG"
  echo ""
  echo "  4. Restore when done:"
  echo "     mv hosts/jupiter/default.nix.backup hosts/jupiter/default.nix"
  echo ""
}

# Analyze module complexity
analyze_modules() {
  log_section "Module Complexity Analysis"

  log_subsection "Finding most complex modules..."

  local analysis_file=$(mktemp)

  # Find all .nix files and analyze complexity
  for module_file in $(find modules -name "*.nix" -type f 2>/dev/null | sort); do
    # Count imports and complexity
    local direct_imports=$(grep -cE '^[[:space:]]*import[[:space:]]+[^a-zA-Z]' "$module_file" 2>/dev/null || echo "0")
    direct_imports=$(echo "$direct_imports" | tr -d '[:space:]')
    direct_imports=${direct_imports:-0}

    local imports_statements=$(grep -cE '^[[:space:]]*imports[[:space:]]*=' "$module_file" 2>/dev/null || echo "0")
    imports_statements=$(echo "$imports_statements" | tr -d '[:space:]')
    imports_statements=${imports_statements:-0}

    local imports_in_lists=$(awk '
      BEGIN { in_imports = 0; count = 0 }
      /^[[:space:]]*imports[[:space:]]*=[[:space:]]*\[/ { in_imports = 1; next }
      in_imports && /\]/ { in_imports = 0; next }
      in_imports && /\.\/|\.\.\// { count++ }
      END { print count+0 }
    ' "$module_file" 2>/dev/null || echo "0")
    imports_in_lists=$(echo "$imports_in_lists" | tr -d '[:space:]')
    imports_in_lists=${imports_in_lists:-0}

    local callpackages=$(grep -cE 'callPackage|mkCallPackage' "$module_file" 2>/dev/null || echo "0")
    callpackages=$(echo "$callpackages" | tr -d '[:space:]')
    callpackages=${callpackages:-0}

    local import_count=$((direct_imports + imports_statements * 2 + imports_in_lists + callpackages))
    local file_size=$(wc -l < "$module_file" 2>/dev/null || echo "0")
    file_size=$(echo "$file_size" | tr -d '[:space:]')
    file_size=${file_size:-0}

    # Calculate complexity score (imports × file size)
    local complexity_score=$((import_count * file_size))

    if [[ $complexity_score -gt 0 ]]; then
      echo "$complexity_score $import_count $file_size $module_file" >> "$analysis_file"
    fi
  done

  if [[ -s "$analysis_file" ]]; then
    echo ""
    log_info "Top 10 most complex modules (complexity = imports × lines):"
    sort -rn "$analysis_file" | head -10 | \
      awk '{printf "  %8d complexity (%3d imports, %4d lines): %s\n", $1, $2, $3, $4}'

    echo ""
    log_info "Largest modules (by line count):"
    sort -k3 -rn "$analysis_file" | head -10 | \
      awk '{printf "  %4d lines, %3d imports, %8d complexity: %s\n", $3, $2, $1, $4}'
  fi

  rm -f "$analysis_file"
}

# Check for expensive operations
check_expensive_ops() {
  log_section "Checking for Expensive Operations"

  log_subsection "Searching for fetchGit, builtins.fetch, etc..."

  local found_any=false

  # Check for builtins.fetch* usage
  if grep -r "builtins\.fetch" modules/ hosts/ 2>/dev/null | grep -v "\.nix:" | head -5; then
    log_warning "Found builtins.fetch* usage - these run during evaluation!"
    found_any=true
  fi

  # Check for fetchGit
  if grep -r "fetchGit\|builtins\.fetchGit" modules/ hosts/ 2>/dev/null | grep -v "\.nix:" | head -5; then
    log_warning "Found fetchGit usage - these run during evaluation!"
    found_any=true
  fi

  # Check for fetchTarball
  if grep -r "fetchTarball\|builtins\.fetchTarball" modules/ hosts/ 2>/dev/null | grep -v "\.nix:" | head -5; then
    log_warning "Found fetchTarball usage - these run during evaluation!"
    found_any=true
  fi

  if [[ "$found_any" == "false" ]]; then
    log_success "No expensive fetch operations found in modules"
  fi

  # Check for large option files
  log_subsection "Checking for large option definition files..."
  local large_files=$(find modules -name "*.nix" -type f -exec sh -c 'lines=$(wc -l < "$1" 2>/dev/null || echo 0); if [ "$lines" -gt 300 ]; then echo "$lines $1"; fi' _ {} \; | sort -rn)

  if [[ -n "$large_files" ]]; then
    log_warning "Found large module files (>300 lines):"
    echo "$large_files" | head -5 | while read -r lines file; do
      echo "  ${lines} lines: $file"
    done
  else
    log_success "No unusually large module files found"
  fi
}

# Provide recommendations
show_recommendations() {
  log_section "Recommendations"

  local baseline=$(baseline_evaluation 2>/dev/null | tail -1)
  baseline=${baseline:-0}

  local recommendations=()

  if [[ $baseline -gt 10000 ]]; then
    recommendations+=("Evaluation time is very slow (>10s). Focus on:")
    recommendations+=("  1. Split large option definition files (host-options.nix is 720 lines)")
    recommendations+=("  2. Disable unused features to reduce module imports")
    recommendations+=("  3. Use build-time input fetching for platform-specific inputs")
  elif [[ $baseline -gt 5000 ]]; then
    recommendations+=("Evaluation time is slow (5-10s). Consider:")
    recommendations+=("  1. Review large option definition files")
    recommendations+=("  2. Optimize module import structure")
  fi

  # Check for large host-options files (if not already split)
  if [[ -f "modules/shared/host-options.nix" ]]; then
    local lines=$(wc -l < "modules/shared/host-options.nix" 2>/dev/null || echo "0")
    if [[ $lines -gt 500 ]]; then
      recommendations+=("host-options.nix is very large ($lines lines). Consider splitting into:")
      recommendations+=("  - modules/shared/host-options/core.nix")
      recommendations+=("  - modules/shared/host-options/features.nix")
      recommendations+=("  - modules/shared/host-options/services.nix")
    fi
  elif [[ -d "modules/shared/host-options" ]]; then
    # Check if split files are large
    local total_lines=0
    for file in modules/shared/host-options/*.nix; do
      if [[ -f "$file" ]]; then
        local file_lines=$(wc -l < "$file" 2>/dev/null || echo "0")
        total_lines=$((total_lines + file_lines))
      fi
    done
    if [[ $total_lines -gt 1000 ]]; then
      recommendations+=("host-options files are large (${total_lines} total lines). Consider further splitting feature-specific options.")
    fi
  fi

  # Count total modules
  local total_modules=$(find modules -name "*.nix" -type f 2>/dev/null | wc -l)
  if [[ $total_modules -gt 100 ]]; then
    recommendations+=("Large number of modules ($total_modules). Consider:")
    recommendations+=("  - Review if all modules are necessary")
    recommendations+=("  - Consolidate similar modules")
    recommendations+=("  - Use conditional imports where possible")
  fi

  if [[ ${#recommendations[@]} -eq 0 ]]; then
    log_success "Configuration looks good! No major optimizations needed."
  else
    for rec in "${recommendations[@]}"; do
      echo -e "  ${YELLOW}•${NC} $rec"
    done
  fi
}

# Main execution
main() {
  echo -e "${PURPLE}${BOLD}⏱️  Evaluation Time Profiler${NC}"
  echo -e "${BLUE}Profiling: ${GREEN}$CONFIG${NC}"
  echo ""

  # Run baseline
  local baseline=$(baseline_evaluation)

  echo ""

  # Analyze modules
  analyze_modules

  echo ""

  # Check for expensive operations
  check_expensive_ops

  echo ""

  # Show recommendations
  show_recommendations

  echo ""

  if [[ "$COMPARE_MODE" == "--compare" ]]; then
    compare_evaluations
  else
    log_info "Tip: Temporarily disable features in hosts/jupiter/default.nix and re-run"
    log_info "     to see which features impact evaluation time the most"
  fi

  echo ""
  log_success "Profiling complete!"
  echo ""
  log_info "Next steps:"
  echo "  1. Review the complexity analysis above"
  echo "  2. Test disabling features one by one to measure impact"
  echo "  3. Consider splitting large option definition files"
  echo "  4. Run with --compare flag to see comparison instructions"
}

# Handle help
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
  echo "Usage: $0 [config-name] [--compare]"
  echo ""
  echo "Profiles evaluation time to identify slow modules and features."
  echo ""
  echo "Arguments:"
  echo "  config-name    Configuration to profile (default: auto-detect)"
  echo "  --compare      Show instructions for comparing evaluation times"
  echo ""
  echo "Examples:"
  echo "  $0                                    # Profile current system"
  echo "  $0 nixosConfigurations.jupiter       # Profile specific config"
  echo "  $0 --compare                          # Show comparison instructions"
  echo ""
  echo "This script helps identify:"
  echo "  • Baseline evaluation time"
  echo "  • Most complex modules (by import count and size)"
  echo "  • Expensive operations (fetchGit, builtins.fetch, etc.)"
  echo "  • Large option definition files"
  echo "  • Optimization recommendations"
  exit 0
fi

main "$@"
