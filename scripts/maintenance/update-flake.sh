#!/usr/bin/env bash
# Flake Input Update Script
# Task 4.3: Review Flake Input Freshness
#
# This script:
# - Updates flake inputs using nix flake update
# - Monitors for deprecated or archived repositories
# - Checks for alternative sources with better cache coverage
# - Documents problematic inputs
#
# Usage: ./scripts/maintenance/update-flake.sh [--dry-run] [--input <name>]
# Schedule: Run weekly via cron or systemd timer

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
LOG_DIR="$REPO_ROOT/.flake-updates"
mkdir -p "$LOG_DIR"

DRY_RUN=false
SPECIFIC_INPUT=""

log() { echo -e "${BLUE}▶${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1"; }

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --input)
      SPECIFIC_INPUT="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--dry-run] [--input <name>]"
      exit 1
      ;;
  esac
done

# Check for deprecated/archived repositories
check_repo_status() {
  local input_name=$1
  local url=$2

  log "Checking status of $input_name..."

  # Extract GitHub repo from URL
  local github_repo=""
  if [[ "$url" =~ github:([^/]+/[^/]+) ]]; then
    github_repo="${BASH_REMATCH[1]}"
  elif [[ "$url" =~ github\.com/([^/]+/[^/]+) ]]; then
    github_repo="${BASH_REMATCH[1]}"
  fi

  if [[ -n "$github_repo" ]]; then
    # Check if repo exists and is not archived
    if command -v gh &> /dev/null; then
      local archived=$(gh repo view "$github_repo" --json isArchived 2>/dev/null | jq -r '.isArchived' || echo "unknown")
      if [[ "$archived" == "true" ]]; then
        log_warning "  Repository $github_repo is archived!"
        return 1
      fi
    else
      # Fallback: try to check via HTTP
      local status_code=$(curl -s -o /dev/null -w "%{http_code}" "https://github.com/$github_repo" 2>/dev/null || echo "000")
      if [[ "$status_code" == "404" ]]; then
        log_warning "  Repository $github_repo not found (404)"
        return 1
      fi
    fi
  fi

  return 0
}

# Check for FlakeHub alternatives
check_flakehub_alternative() {
  local input_name=$1
  local current_url=$2

  # If already on FlakeHub, no need to check
  if [[ "$current_url" == *"flakehub.com"* ]]; then
    return 0
  fi

  # Extract repo identifier
  local repo_id=""
  if [[ "$current_url" =~ github:([^/]+/[^/]+) ]]; then
    repo_id="${BASH_REMATCH[1]}"
  fi

  if [[ -n "$repo_id" ]]; then
    log "  Checking for FlakeHub alternative for $repo_id..."
    # Note: Actual FlakeHub search would require API access
    # This is a placeholder for manual checking
    echo "    Manual check recommended: https://flakehub.com/search?q=$repo_id"
  fi
}

# Update flake inputs
update_inputs() {
  log "Updating flake inputs..."

  if [[ "$DRY_RUN" == "true" ]]; then
    log "  DRY RUN: Would update inputs"
    nix flake update --dry-run 2>&1 || true
    return
  fi

  if [[ -n "$SPECIFIC_INPUT" ]]; then
    log "  Updating specific input: $SPECIFIC_INPUT"
    nix flake update "$SPECIFIC_INPUT"
  else
    log "  Updating all inputs..."
    nix flake update
  fi

  log_success "Flake inputs updated"
}

# Analyze input changes
analyze_changes() {
  log "Analyzing input changes..."

  local lock_file="$REPO_ROOT/flake.lock"
  local prev_lock="$LOG_DIR/flake.lock.prev"

  if [[ ! -f "$prev_lock" ]]; then
    log_warning "  No previous lock file found (first run)"
    cp "$lock_file" "$prev_lock" 2>/dev/null || true
    return
  fi

  if command -v jq &> /dev/null; then
    # Compare lock files
    local changes=$(diff -u "$prev_lock" "$lock_file" 2>/dev/null || true)

    if [[ -z "$changes" ]]; then
      log_success "  No changes detected"
    else
      log "  Changes detected:"
      echo "$changes" | grep -E "^\+|^-" | head -20 || true

      # Save change log
      local changelog_file="$LOG_DIR/changelog-$(date +%Y-%m-%d).txt"
      {
        echo "Flake input update: $(date)"
        echo "========================================"
        echo "$changes"
      } > "$changelog_file"
      log "  Change log saved to: $changelog_file"
    fi

    # Update previous lock file
    cp "$lock_file" "$prev_lock"
  else
    log_warning "  jq not available for detailed analysis"
  fi
}

# Check all inputs for issues
check_all_inputs() {
  log "Checking all flake inputs..."

  if [[ ! -f "$REPO_ROOT/flake.lock" ]]; then
    log_error "flake.lock not found"
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    log_warning "jq not available - skipping input checks"
    return 0
  fi

  local issues=0

  # Extract inputs from flake.lock
  jq -r '.nodes | to_entries[] | "\(.key)|\(.value.locked.url // .value.original.url // "")"' "$REPO_ROOT/flake.lock" | while IFS='|' read -r name url; do
    if [[ -z "$url" ]]; then
      continue
    fi

    if ! check_repo_status "$name" "$url"; then
      issues=$((issues + 1))
    fi

    check_flakehub_alternative "$name" "$url"
  done

  if [[ $issues -eq 0 ]]; then
    log_success "All inputs appear healthy"
  else
    log_warning "Found $issues potentially problematic input(s)"
  fi
}

# Generate update report
generate_report() {
  log "Generating update report..."

  local report_file="$LOG_DIR/report-$(date +%Y-%m-%d).json"
  local timestamp=$(date +%s)
  local date=$(date -Iseconds)

  {
    echo "{"
    echo "  \"timestamp\": $timestamp,"
    echo "  \"date\": \"$date\","
    echo "  \"dry_run\": $DRY_RUN,"
    echo "  \"specific_input\": \"$SPECIFIC_INPUT\","
    echo "  \"git\": {"
    echo "    \"commit\": \"$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo "unknown")\","
    echo "    \"branch\": \"$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")\","
    echo "    \"dirty\": $(git -C "$REPO_ROOT" diff-index --quiet HEAD -- && echo "false" || echo "true")"
    echo "  }"
    echo "}"
  } > "$report_file"

  log_success "Report saved to: $report_file"
}

# Main execution
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo -e "${CYAN}  Flake Input Update${NC}"
echo -e "${CYAN}════════════════════════════════════════${NC}"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
  log_warning "DRY RUN MODE - No changes will be made"
  echo ""
fi

check_all_inputs
echo ""

if [[ "$DRY_RUN" != "true" ]]; then
  update_inputs
  echo ""
  analyze_changes
  echo ""
fi

generate_report

echo ""
echo -e "${GREEN}💡 Next Steps:${NC}"
echo "  1. Review changes: git diff flake.lock"
echo "  2. Test build: nix flake check"
echo "  3. Document any problematic inputs in docs/PERFORMANCE_TUNING.md"
echo "  4. Schedule weekly runs: Add to cron or systemd timer"
echo ""
