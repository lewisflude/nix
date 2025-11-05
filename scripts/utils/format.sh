#!/usr/bin/env bash
# Formatting helper script for Nix configuration
# Provides convenient commands for formatting code

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Check if command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Format Nix files using nixfmt-rfc-style
format_nix() {
  local target="${1:-.}"
  echo -e "${BLUE}Formatting Nix files in: ${target}${NC}"

  if command_exists nixfmt-rfc-style; then
    if [ -d "$target" ]; then
      find "$target" -name "*.nix" -type f ! -path "*/result*" ! -path "*/.direnv/*" ! -path "*/node_modules/*" ! -name "flake.lock" | while read -r file; do
        echo -e "  ${GREEN}Formatting: ${file}${NC}"
        nixfmt-rfc-style "$file" || echo -e "  ${RED}Failed to format: ${file}${NC}"
      done
    elif [ -f "$target" ]; then
      nixfmt-rfc-style "$target"
    else
      echo -e "${RED}Error: ${target} is not a valid file or directory${NC}"
      return 1
    fi
  else
    echo -e "${RED}Error: nixfmt-rfc-style not found. Install it with: nix profile install nixpkgs#nixfmt-rfc-style${NC}"
    return 1
  fi
}

# Format using treefmt (recommended for projects)
format_treefmt() {
  if command_exists treefmt; then
    echo -e "${BLUE}Formatting with treefmt...${NC}"
    treefmt
  else
    echo -e "${YELLOW}treefmt not found. Falling back to nixfmt-rfc-style...${NC}"
    format_nix "${1:-.}"
  fi
}

# Format using nix fmt (flake formatter)
format_nix_fmt() {
  echo -e "${BLUE}Formatting with nix fmt...${NC}"
  if command_exists nix; then
    nix fmt
  else
    echo -e "${RED}Error: nix command not found${NC}"
    return 1
  fi
}

# Format all files (Nix, YAML, Markdown, Shell)
format_all() {
  echo -e "${BLUE}Formatting all supported files...${NC}"
  format_treefmt
}

# Show formatting status (check what would be formatted)
format_status() {
  echo -e "${BLUE}Checking formatting status...${NC}"
  if command_exists treefmt; then
    treefmt --check || true
  else
    echo -e "${YELLOW}treefmt not found. Using nixfmt-rfc-style check...${NC}"
    if command_exists nixfmt-rfc-style; then
      find . -name "*.nix" -type f ! -path "*/result*" ! -path "*/.direnv/*" ! -path "*/node_modules/*" ! -name "flake.lock" | while read -r file; do
        if ! nixfmt-rfc-style --check "$file" >/dev/null 2>&1; then
          echo -e "  ${YELLOW}Needs formatting: ${file}${NC}"
        fi
      done
    fi
  fi
}

# Help message
show_help() {
  cat <<EOF
${BLUE}Formatting Helper Script${NC}

Usage: format.sh [COMMAND] [OPTIONS]

Commands:
  nix [PATH]           Format Nix files using nixfmt-rfc-style
                       (default: current directory)

  treefmt              Format all files using treefmt (recommended)
                       Formats: Nix, YAML, Markdown, Shell scripts

  nix-fmt              Format using \`nix fmt\` (flake formatter)

  all                  Format all supported file types
                       (equivalent to treefmt)

  status               Check formatting status without making changes
                       Shows which files need formatting

  help                 Show this help message

Examples:
  format.sh nix .                    # Format all Nix files in current dir
  format.sh nix modules/nixos        # Format Nix files in specific directory
  format.sh treefmt                  # Format all files with treefmt
  format.sh nix-fmt                  # Use nix fmt command
  format.sh status                   # Check what needs formatting

Git Integration:
  git mergetool -t nixfmt <file>     # Use nixfmt to resolve merge conflicts
  git mergetool -t nixfmt .          # Resolve all merge conflicts

EOF
}

# Main command dispatcher
main() {
  local command="${1:-help}"

  case "$command" in
    nix)
      format_nix "${2:-.}"
      ;;
    treefmt)
      format_treefmt
      ;;
    nix-fmt)
      format_nix_fmt
      ;;
    all)
      format_all
      ;;
    status)
      format_status
      ;;
    help|--help|-h)
      show_help
      ;;
    *)
      echo -e "${RED}Unknown command: ${command}${NC}"
      echo ""
      show_help
      exit 1
      ;;
  esac
}

main "$@"
