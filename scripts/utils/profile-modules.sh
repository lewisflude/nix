#!/usr/bin/env bash
# Profile module evaluation times in NixOS/nix-darwin configuration
# Usage: ./scripts/utils/profile-modules.sh [config-name]

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

# Method 1: Use function call tracing to identify modules being evaluated
profile_function_calls() {
  log_section "Function Call Tracing"
  log_subsection "Identifying modules being evaluated..."

  log_info "Running evaluation with function call tracing..."
  log_warning "This may produce a lot of output..."

  local trace_file=$(mktemp)

  # Use nix-instantiate with trace-function-calls
  # Note: This traces function calls, not module imports directly
  if command -v nix-instantiate &> /dev/null; then
    log_info "Capturing function call trace..."
    nix-instantiate --trace-function-calls - <<EOF 2>&1 | head -500 > "$trace_file" || true
with import <nixpkgs> {};
let
  flake = import $REPO_ROOT/flake.nix;
in
  flake.$OUTPUT_PATH
EOF

    if [[ -s "$trace_file" ]]; then
      echo ""
      log_info "Top functions/modules being called:"
      grep -E "trace:|call" "$trace_file" | head -20 || true
      echo ""
      log_info "Full trace saved to: $trace_file"
      log_info "Analyze it with: less $trace_file"
    fi
  else
    log_warning "nix-instantiate not found, skipping function call tracing"
  fi
}

# Method 2: Profile evaluation time per module directory
profile_module_directories() {
  log_section "Module Directory Profiling"
  log_subsection "Measuring evaluation time with/without module directories..."

  # This is a simplified approach - temporarily disable modules and measure impact
  log_warning "This method requires manual testing by commenting out module imports"
  log_info "To use this method:"
  echo ""
  echo "  1. Backup your configuration"
  echo "  2. Comment out module imports in hosts/*/configuration.nix"
  echo "  3. Measure evaluation time:"
  echo "     time nix eval --raw .#$OUTPUT_PATH"
  echo "  4. Re-enable modules one by one to identify slow ones"
  echo ""
}

# Method 3: Use Nix's built-in profiler (if available)
profile_with_nix_profiler() {
  log_section "Nix Evaluation Profiling"

  log_subsection "Method 1: Using NIX_PROFILE"

  local profile_file=$(mktemp).prof

  log_info "Setting NIX_PROFILE environment variable..."
  log_info "Running evaluation with profiling..."

  # Note: Nix doesn't have built-in evaluation profiling in the same way
  # But we can use time(1) and strace/dtrace for deeper analysis
  log_warning "Nix doesn't have built-in per-module profiling"
  log_info "Alternative: Use timing wrapper around module imports"

  echo ""
  log_info "To profile specific modules manually:"
  echo ""
  echo "  1. Create a test file that imports just one module:"
  echo "     test-module.nix:"
  echo "       { config, lib, ... }:"
  echo "       import ./modules/nixos/services/your-module.nix"
  echo ""
  echo "  2. Time its evaluation:"
  echo "     time nix-instantiate --eval -E 'import ./test-module.nix'"
  echo ""
}

# Method 4: Analyze which modules import the most dependencies
analyze_module_dependencies() {
  log_section "Module Dependency Analysis"

  log_subsection "Finding modules with most imports..."

  # Count imports in each module file
  local modules_dir="modules"
  if [[ ! -d "$modules_dir" ]]; then
    log_warning "Modules directory not found"
    return
  fi

  log_info "Analyzing module files for import patterns..."
  log_info "Complexity score = direct imports + (imports statements × 2) + items in import lists + callPackage calls"

  # Find all .nix files in modules directories
  local analysis_file=$(mktemp)

  for module_file in $(find modules -name "*.nix" -type f 2>/dev/null | sort); do
    # Count various import patterns
    # 1. Direct imports: import ./path
    local direct_imports=$(grep -cE '^[[:space:]]*import[[:space:]]+[^a-zA-Z]' "$module_file" 2>/dev/null || echo "0")
    direct_imports=$(echo "$direct_imports" | tr -d '[:space:]')
    direct_imports=${direct_imports:-0}

    # 2. imports = statements (count occurrences, each represents an import list)
    local imports_statements=$(grep -cE '^[[:space:]]*imports[[:space:]]*=' "$module_file" 2>/dev/null || echo "0")
    imports_statements=$(echo "$imports_statements" | tr -d '[:space:]')
    imports_statements=${imports_statements:-0}

    # 3. Count items in imports lists (count all ./path or ../path patterns)
    # This is a heuristic - counts import-like paths which are likely module imports
    local imports_in_lists=$(grep -E '^[[:space:]]*imports[[:space:]]*=' "$module_file" 2>/dev/null | \
      grep -oE './[^[:space:]]+|../[^[:space:]]+' 2>/dev/null | wc -l)
    imports_in_lists=$(echo "$imports_in_lists" | tr -d '[:space:]')
    imports_in_lists=${imports_in_lists:-0}

    # Also count import paths on separate lines within imports lists
    # Use awk to count lines between imports = [ and ] that contain ./ or ../
    local imports_in_lists_multiline=$(awk '
      BEGIN { in_imports = 0; count = 0 }
      /^[[:space:]]*imports[[:space:]]*=[[:space:]]*\[/ { in_imports = 1; next }
      in_imports && /\]/ { in_imports = 0; next }
      in_imports && /\.\/|\.\.\// { count++ }
      END { print count+0 }
    ' "$module_file" 2>/dev/null || echo "0")
    imports_in_lists_multiline=$(echo "$imports_in_lists_multiline" | tr -d '[:space:]')
    imports_in_lists_multiline=${imports_in_lists_multiline:-0}

    # Use the larger count (some imports are on same line, some on separate lines)
    if [[ "$imports_in_lists_multiline" -gt "$imports_in_lists" ]]; then
      imports_in_lists="$imports_in_lists_multiline"
    fi

    # 4. callPackage patterns (often indicate package imports)
    local callpackages=$(grep -cE 'callPackage|mkCallPackage' "$module_file" 2>/dev/null || echo "0")
    callpackages=$(echo "$callpackages" | tr -d '[:space:]')
    callpackages=${callpackages:-0}

    # Total import complexity score (weight imports lists more heavily)
    # Ensure all values are numeric before arithmetic
    local import_count=$((direct_imports + imports_statements * 2 + imports_in_lists + callpackages))

    local file_size=$(wc -l < "$module_file" 2>/dev/null || echo "0")
    file_size=$(echo "$file_size" | tr -d '[:space:]')
    file_size=${file_size:-0}

    echo "$import_count $file_size $module_file" >> "$analysis_file"
  done

  if [[ -s "$analysis_file" ]]; then
    echo ""
    log_info "Modules with most imports (likely slower to evaluate):"
    sort -rn "$analysis_file" | head -15 | \
      awk '{printf "  %3d complexity, %4d lines: %s\n", $1, $2, $3}'

    echo ""
    log_info "Largest modules (by line count - may indicate complexity):"
    sort -k2 -rn "$analysis_file" | head -15 | \
      awk '{printf "  %4d lines, %3d complexity: %s\n", $2, $1, $3}'

    # Identify potentially slow modules (high complexity AND large size)
    echo ""
    log_info "Potentially slow modules (high complexity + large size):"
    awk '$1 >= 5 && $2 >= 100 {print $1*$2, $1, $2, $3}' "$analysis_file" | \
      sort -rn | head -10 | \
      awk '{printf "  Score: %6d (%3d complexity × %4d lines): %s\n", $1, $2, $3, $4}' || \
      log_info "  (No modules with both high complexity and large size found)"
  fi

  rm -f "$analysis_file"
}

# Method 5: Compare evaluation times before/after module changes
compare_evaluation_times() {
  log_section "Evaluation Time Comparison"

  log_subsection "Measuring current evaluation time..."

  # Use time command for more accurate measurement
  local time_output=$( (time -p nix eval --raw ".$OUTPUT_PATH" > /dev/null 2>&1) 2>&1 || echo "real 0.00")
  local duration=$(echo "$time_output" | grep -E "^real" | awk '{print $2}' | head -1 || echo "0.00")
  duration=$(echo "$duration" | tr -d '[:space:]')

  # Format duration nicely
  if command -v bc &> /dev/null && [[ -n "$duration" ]]; then
    local duration_formatted=$(echo "scale=2; $duration" | bc 2>/dev/null || echo "$duration")
  else
    local duration_formatted="${duration:-0.00}"
  fi

  echo -e "  ${GREEN}Current evaluation time: ${BOLD}${duration_formatted}s${NC}"
  echo ""
  log_info "To identify slow modules:"
  echo ""
  echo "  1. Measure baseline:"
  echo "     time nix eval --raw .#$OUTPUT_PATH"
  echo ""
  echo "  2. Temporarily disable modules in hosts/*/configuration.nix"
  echo ""
  echo "  3. Measure again and compare"
  echo ""
  echo "  4. Re-enable modules one group at a time to isolate slow ones"
}

# Method 6: Use nix-tree to visualize what modules pull in
visualize_module_impact() {
  log_section "Module Impact Visualization"

  log_subsection "Using nix-tree to visualize dependencies..."

  if command -v nix-tree &> /dev/null || nix profile list 2>/dev/null | grep -q nix-tree; then
    log_info "Found nix-tree, you can visualize module impact:"
    echo ""
    echo "  nix-tree .#$OUTPUT_PATH"
    echo ""
    log_info "This shows the full dependency tree and sizes"
  else
    log_info "Install nix-tree for visualization:"
    echo ""
    echo "  nix profile install nixpkgs#nix-tree"
    echo "  nix-tree .#$OUTPUT_PATH"
    echo ""
  fi
}

# Main execution
main() {
  echo -e "${PURPLE}${BOLD}🔍 Nix Module Profiler${NC}"
  echo -e "${BLUE}Analyzing modules for: ${GREEN}$CONFIG${NC}"
  echo ""

  compare_evaluation_times
  analyze_module_dependencies
  visualize_module_impact

  echo ""
  log_section "Advanced Profiling Methods"

  log_subsection "Option 1: Manual Module Timing"
  echo "  Create a wrapper script that imports modules individually and times them:"
  echo ""
  echo "  #!/usr/bin/env nix-instantiate --eval"
  echo "  let"
  echo "    pkgs = import <nixpkgs> {};"
  echo "    module = import ./modules/nixos/services/your-module.nix;"
  echo "  in"
  echo "    builtins.trace \"Module evaluated\" module"
  echo ""
  echo "  Then run: time nix-instantiate --eval wrapper.nix"

  log_subsection "Option 2: Use strace/dtrace (Linux/macOS)"
  echo "  Profile system calls during evaluation:"
  echo ""
  echo "  # Linux:"
  echo "  strace -c -e trace=open,openat nix eval --raw .#$OUTPUT_PATH"
  echo ""
  echo "  # macOS:"
  echo "  sudo dtruss -c nix eval --raw .#$OUTPUT_PATH"

  log_subsection "Option 3: Use Nix evaluation with --show-trace"
  echo "  See what's being evaluated:"
  echo ""
  echo "  nix eval --show-trace .#$OUTPUT_PATH 2>&1 | less"

  profile_function_calls

  echo ""
  log_success "Module profiling complete!"
  echo ""
  log_info "Tips:"
  echo "  • Modules that import many other modules are likely slower"
  echo "  • Modules that evaluate large package sets take more time"
  echo "  • Use --full flag with profile-build.sh for overall build analysis"
  echo "  • Consider lazy evaluation - modules are only evaluated if their options are accessed"
}

# Handle help
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
  echo "Usage: $0 [config-name]"
  echo ""
  echo "Profiles which modules take the most time to evaluate in your Nix configuration."
  echo ""
  echo "Arguments:"
  echo "  config-name    Configuration to profile (default: auto-detect)"
  echo ""
  echo "Examples:"
  echo "  $0                                    # Profile current system"
  echo "  $0 nixosConfigurations.jupiter       # Profile specific config"
  echo ""
  echo "Note: Module-level profiling is limited because:"
  echo "  • Nix evaluates modules lazily"
  echo "  • Modules are merged together during evaluation"
  echo "  • There's no built-in per-module timing"
  echo ""
  echo "This script provides several workarounds and analysis methods."
  exit 0
fi

main "$@"
