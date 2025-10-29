#!/usr/bin/env bash
# Benchmark rebuild time and track performance over time
# Usage: ./scripts/utils/benchmark-rebuild.sh [config-name]
#
# This script measures evaluation and build times for your Nix configurations
# and stores historical data for trend analysis.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BENCHMARK_DIR="$REPO_ROOT/.benchmark-history"
mkdir -p "$BENCHMARK_DIR"

# Detect system and configuration
detect_config() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "darwinConfigurations.$(hostname -s)"
  else
    echo "nixosConfigurations.$(hostname)"
  fi
}

CONFIG="${1:-$(detect_config)}"
TIMESTAMP=$(date +%s)
# Cross-platform date formatting
if [[ "$OSTYPE" == "darwin"* ]]; then
  DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
else
  DATE=$(date -Iseconds)
fi
BENCHMARK_FILE="$BENCHMARK_DIR/$(date +%Y-%m-%d_%H-%M-%S).json"

echo -e "${BLUE}🔍 Benchmarking configuration: ${GREEN}$CONFIG${NC}"
echo -e "${BLUE}📊 Results will be saved to: ${YELLOW}$BENCHMARK_FILE${NC}"
echo ""

# Function to measure evaluation time
measure_evaluation() {
  echo -e "${YELLOW}⏱️  Measuring evaluation time...${NC}"

  # macOS date doesn't support nanoseconds, use gdate if available or fall back to seconds
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v gdate &> /dev/null; then
      local start=$(gdate +%s%N)
      nix eval --raw ".#$CONFIG.config.system.build.toplevel" --show-trace 2>&1 > /dev/null || true
      local end=$(gdate +%s%N)
      local duration=$(( (end - start) / 1000000 ))
    else
      local start=$(date +%s)
      nix eval --raw ".#$CONFIG.config.system.build.toplevel" --show-trace 2>&1 > /dev/null || true
      local end=$(date +%s)
      local duration=$(( (end - start) * 1000 ))  # Convert seconds to milliseconds
    fi
  else
    local start=$(date +%s%N)
    nix eval --raw ".#$CONFIG.config.system.build.toplevel" --show-trace 2>&1 > /dev/null || true
    local end=$(date +%s%N)
    local duration=$(( (end - start) / 1000000 ))
  fi

  echo -e "${GREEN}✓ Evaluation time: ${duration}ms${NC}"
  echo "$duration"
}

# Function to measure build time (dry-run)
measure_build_dryrun() {
  echo -e "${YELLOW}⏱️  Measuring build time (dry-run)...${NC}"

  # macOS date doesn't support nanoseconds, use gdate if available or fall back to seconds
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v gdate &> /dev/null; then
      local start=$(gdate +%s%N)
      nix build ".#$CONFIG" --dry-run --json 2>&1 > /tmp/nix-build-dryrun.json || true
      local end=$(gdate +%s%N)
      local duration=$(( (end - start) / 1000000 ))
    else
      local start=$(date +%s)
      nix build ".#$CONFIG" --dry-run --json 2>&1 > /tmp/nix-build-dryrun.json || true
      local end=$(date +%s)
      local duration=$(( (end - start) * 1000 ))
    fi
  else
    local start=$(date +%s%N)
    nix build ".#$CONFIG" --dry-run --json 2>&1 > /tmp/nix-build-dryrun.json || true
    local end=$(date +%s%N)
    local duration=$(( (end - start) / 1000000 ))
  fi

  echo -e "${GREEN}✓ Build planning time: ${duration}ms${NC}"
  echo "$duration"
}

# Count derivations and packages
count_derivations() {
  echo -e "${YELLOW}📦 Counting packages...${NC}"

  # Try to get package count from the build output
  local pkg_count=$(nix eval ".#$CONFIG.config.environment.systemPackages" --apply 'x: builtins.length x' 2>/dev/null || echo "0")

  echo -e "${GREEN}✓ System packages: $pkg_count${NC}"
  echo "$pkg_count"
}

# Main benchmark execution
echo "Starting benchmark..."
echo ""

EVAL_TIME=$(measure_evaluation)
echo ""

BUILD_TIME=$(measure_build_dryrun)
echo ""

PKG_COUNT=$(count_derivations)
echo ""

# Create JSON output
cat > "$BENCHMARK_FILE" <<EOF
{
  "timestamp": $TIMESTAMP,
  "date": "$DATE",
  "config": "$CONFIG",
  "hostname": "$(hostname)",
  "system": "$OSTYPE",
  "metrics": {
    "evaluation_ms": $EVAL_TIME,
    "build_planning_ms": $BUILD_TIME,
    "total_ms": $(( EVAL_TIME + BUILD_TIME )),
    "package_count": $PKG_COUNT
  },
  "git": {
    "commit": "$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo "unknown")",
    "branch": "$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")",
    "dirty": $(git -C "$REPO_ROOT" diff-index --quiet HEAD -- && echo "false" || echo "true")
  }
}
EOF

echo -e "${GREEN}✓ Benchmark complete!${NC}"
echo ""
echo -e "${BLUE}📊 Summary:${NC}"
echo -e "  Evaluation time:    ${GREEN}${EVAL_TIME}ms${NC}"
echo -e "  Build planning:     ${GREEN}${BUILD_TIME}ms${NC}"
echo -e "  Total time:         ${GREEN}$(( EVAL_TIME + BUILD_TIME ))ms${NC}"
echo -e "  Package count:      ${GREEN}${PKG_COUNT}${NC}"
echo ""

# Generate trend report if we have historical data
if [ $(ls -1 "$BENCHMARK_DIR"/*.json 2>/dev/null | wc -l) -gt 1 ]; then
  echo -e "${BLUE}📈 Historical trend (last 5 benchmarks):${NC}"
  echo ""

  # Simple trend analysis using jq if available
  if command -v jq &> /dev/null; then
    for file in $(ls -t "$BENCHMARK_DIR"/*.json | head -5); do
      local date=$(jq -r '.date' "$file" | cut -d'T' -f1)
      local total=$(jq -r '.metrics.total_ms' "$file")
      local commit=$(jq -r '.git.commit' "$file" | cut -c1-7)
      echo -e "  ${date} (${commit}): ${YELLOW}${total}ms${NC}"
    done
    echo ""

    # Calculate average
    local avg=$(jq -s 'map(.metrics.total_ms) | add / length | floor' $(ls -t "$BENCHMARK_DIR"/*.json | head -5))
    echo -e "${BLUE}Average (last 5): ${GREEN}${avg}ms${NC}"
  fi
fi

echo ""
echo -e "${GREEN}💡 Tip: Run this script regularly to track performance over time${NC}"
echo -e "${BLUE}   View all results: ls -lh $BENCHMARK_DIR${NC}"
