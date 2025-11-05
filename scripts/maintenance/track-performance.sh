#!/usr/bin/env bash
# Monthly Performance Tracking Script
# Task 4.1: Establish Performance Tracking Routine
#
# This script measures:
# - Evaluation time measurements
# - Store size growth over time
# - Binary cache hit rates
# - Documents performance trends
#
# Usage: ./scripts/maintenance/track-performance.sh
# Schedule: Run monthly via cron or systemd timer

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
METRICS_DIR="$REPO_ROOT/.performance-metrics"
mkdir -p "$METRICS_DIR"

# Detect system
detect_system() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "darwin"
  else
    echo "nixos"
  fi
}

SYSTEM=$(detect_system)
TIMESTAMP=$(date +%s)
if [[ "$OSTYPE" == "darwin"* ]]; then
  DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
else
  DATE=$(date -Iseconds)
fi
METRICS_FILE="$METRICS_DIR/$(date +%Y-%m).json"

log() { echo -e "${BLUE}▶${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# Get time function (cross-platform)
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

# Calculate duration in milliseconds
calc_duration() {
  local start=$1
  local end=$2
  if [[ "$OSTYPE" == "darwin"* ]] && ! command -v gdate &> /dev/null; then
    echo $(( (end - start) * 1000 ))
  else
    echo $(( (end - start) / 1000000 ))
  fi
}

# 1. System Information
collect_system_info() {
  log "Collecting system information..."

  local os_version kernel_version nix_version determinate_version

  if [[ "$SYSTEM" == "darwin" ]]; then
    os_version=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
    kernel_version=$(uname -r)
  else
    os_version=$(nixos-version 2>/dev/null || echo "unknown")
    kernel_version=$(uname -r)
  fi

  nix_version=$(nix --version 2>/dev/null | head -1 || echo "unknown")
  determinate_version=$(nix --version 2>/dev/null | grep -i determinate || echo "unknown")

  cat <<EOF
  "system": {
    "os": "$os_version",
    "kernel": "$kernel_version",
    "nix_version": "$nix_version",
    "determinate_version": "$(echo "$determinate_version" | sed 's/"/\\"/g')",
    "hostname": "$(hostname)"
  },
EOF
}

# 2. Evaluation Time Measurements
measure_evaluation_times() {
  log "Measuring evaluation times..."

  local flake_eval_ms nixos_eval_ms darwin_eval_ms

  # Flake evaluation time
  log "  Measuring flake check..."
  local start=$(get_time)
  nix flake check --no-build &>/dev/null || true
  local end=$(get_time)
  flake_eval_ms=$(calc_duration $start $end)

  # Platform-specific evaluation
  if [[ "$SYSTEM" == "nixos" ]]; then
    log "  Measuring NixOS evaluation..."
    if command -v nh &> /dev/null; then
      start=$(get_time)
      nh os build --dry &>/dev/null || true
      end=$(get_time)
      nixos_eval_ms=$(calc_duration $start $end)
    else
      nixos_eval_ms=0
      log_warning "  nh not available, skipping NixOS evaluation"
    fi
    darwin_eval_ms=null
  else
    log "  Measuring Darwin evaluation..."
    if command -v darwin-rebuild &> /dev/null; then
      start=$(get_time)
      darwin-rebuild switch --dry-run --flake "$REPO_ROOT#$(hostname -s)" &>/dev/null || true
      end=$(get_time)
      darwin_eval_ms=$(calc_duration $start $end)
    else
      darwin_eval_ms=0
      log_warning "  darwin-rebuild not available"
    fi
    nixos_eval_ms=null
  fi

  cat <<EOF
  "evaluation": {
    "flake_check_ms": $flake_eval_ms,
    "nixos_eval_ms": $nixos_eval_ms,
    "darwin_eval_ms": $darwin_eval_ms
  },
EOF
}

# 3. Store Size Metrics
measure_store_size() {
  log "Measuring store size..."

  local store_size_bytes store_size_human generations

  if [[ -d "/nix/store" ]]; then
    store_size_bytes=$(du -sb /nix/store 2>/dev/null | awk '{print $1}' || echo "0")
    store_size_human=$(du -sh /nix/store 2>/dev/null | awk '{print $1}' || echo "0")
  else
    store_size_bytes=0
    store_size_human="N/A"
    log_warning "  /nix/store not found"
  fi

  # Count generations
  if [[ "$SYSTEM" == "nixos" ]]; then
    if [[ -f "/nix/var/nix/profiles/system" ]]; then
      generations=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system 2>/dev/null | wc -l || echo "0")
    else
      generations=0
    fi
  else
    generations=$(darwin-rebuild --list-generations 2>/dev/null | wc -l || echo "0")
  fi

  # Home Manager generations
  local hm_generations
  hm_generations=$(nix profile list 2>/dev/null | wc -l || echo "0")

  cat <<EOF
  "store": {
    "size_bytes": $store_size_bytes,
    "size_human": "$store_size_human",
    "nixos_generations": $generations,
    "hm_generations": $hm_generations
  },
EOF
}

# 4. Binary Cache Hit Rate Analysis
analyze_cache_hits() {
  log "Analyzing binary cache hit rates..."

  # This is a simplified analysis - actual cache hit rate requires
  # monitoring during an actual build/substitution operation
  # We'll collect cache connectivity and basic metrics

  local cache_status="unknown"
  local cache_servers=0

  # Check cache connectivity
  if nix store ping &>/dev/null; then
    cache_status="connected"
  else
    cache_status="disconnected"
  fi

  # Count configured cache servers from flake.nix
  if [[ -f "$REPO_ROOT/flake.nix" ]]; then
    cache_servers=$(grep -c "https://.*\.cachix\.org" "$REPO_ROOT/flake.nix" 2>/dev/null || echo "0")
    cache_servers=$((cache_servers + $(grep -c "cache\.flakehub\.com" "$REPO_ROOT/flake.nix" 2>/dev/null || echo "0")))
  fi

  # Note: Actual hit rate requires build-time monitoring
  # See docs/PERFORMANCE_TUNING.md for build-time monitoring commands

  cat <<EOF
  "cache": {
    "status": "$cache_status",
    "configured_servers": $cache_servers,
    "note": "Actual hit rate requires build-time monitoring. Use 'nix build --log-format internal-json' for detailed metrics."
  },
EOF
}

# 5. Generate Trend Analysis
generate_trends() {
  log "Generating trend analysis..."

  if [[ ! -f "$METRICS_FILE" ]]; then
    echo "  No previous data found (first run)"
    cat <<EOF
  "trends": {
    "note": "First measurement - no trends available yet"
  },
EOF
    return
  fi

  # Load previous month's data
  local prev_file=$(ls -t "$METRICS_DIR"/*.json 2>/dev/null | head -2 | tail -1)

  if [[ -z "$prev_file" ]] || [[ "$prev_file" == "$METRICS_FILE" ]]; then
    echo "  No previous data found"
    cat <<EOF
  "trends": {
    "note": "First measurement - no trends available yet"
  },
EOF
    return
  fi

  if command -v jq &> /dev/null && [[ -f "$prev_file" ]]; then
    local prev_store_size=$(jq -r '.store.size_bytes // 0' "$prev_file" 2>/dev/null || echo "0")
    local prev_flake_eval=$(jq -r '.evaluation.flake_check_ms // 0' "$prev_file" 2>/dev/null || echo "0")

    cat <<EOF
  "trends": {
    "previous_month_file": "$(basename "$prev_file")",
    "note": "Trend analysis available after multiple measurements"
  },
EOF
  else
    cat <<EOF
  "trends": {
    "note": "jq not available for trend analysis"
  },
EOF
  fi
}

# Main execution
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo -e "${CYAN}  Monthly Performance Tracking${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo ""

# Collect all metrics
{
  echo "{"
  echo "  \"timestamp\": $TIMESTAMP,"
  echo "  \"date\": \"$DATE\","
  echo "  \"month\": \"$(date +%Y-%m)\","
  collect_system_info
  measure_evaluation_times
  measure_store_size
  analyze_cache_hits
  generate_trends
  echo "  \"git\": {"
  echo "    \"commit\": \"$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo "unknown")\","
  echo "    \"branch\": \"$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")\""
  echo "  }"
  echo "}"
} > "$METRICS_FILE"

log_success "Performance metrics saved to: $METRICS_FILE"
echo ""

# Display summary
echo -e "${CYAN}📊 Performance Summary:${NC}"
if command -v jq &> /dev/null; then
  echo ""
  jq -r '
    "  System: \(.system.os) (\(.system.kernel))",
    "  Evaluation Times:",
    "    Flake check: \(.evaluation.flake_check_ms)ms",
    (if .evaluation.nixos_eval_ms != null then "    NixOS: \(.evaluation.nixos_eval_ms)ms" else empty end),
    (if .evaluation.darwin_eval_ms != null then "    Darwin: \(.evaluation.darwin_eval_ms)ms" else empty end),
    "  Store Size: \(.store.size_human) (\(.store.size_bytes) bytes)",
    "  Generations: NixOS=\(.store.nixos_generations), HM=\(.store.hm_generations)",
    "  Cache Status: \(.cache.status) (\(.cache.configured_servers) servers)"
  ' "$METRICS_FILE"
else
  echo "  (Install jq for formatted output)"
fi

echo ""
echo -e "${GREEN}💡 Next Steps:${NC}"
echo "  1. Review trends: $METRICS_DIR"
echo "  2. Update PERFORMANCE_TUNING.md with significant changes"
echo "  3. Schedule monthly runs: Add to cron or systemd timer"
echo ""
