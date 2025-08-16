#!/usr/bin/env bash
# Main Development CLI
# Unified interface for all Nix development tools

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m'

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Available tools
declare -A TOOLS=(
  ["utils"]="$SCRIPT_DIR/dev-utils.sh"
  ["init"]="$SCRIPT_DIR/init-project.sh"
  ["monitor"]="$SCRIPT_DIR/nix-monitor.sh"
)

# Show main help
show_help() {
  echo -e "${PURPLE}🚀 Nix Development CLI${NC}"
  echo
  echo "A unified interface for Nix configuration development tools"
  echo
  echo -e "${CYAN}Usage:${NC} $0 <tool> [command] [args...]"
  echo
  echo -e "${CYAN}Available Tools:${NC}"
  echo

  # Utils commands
  echo -e "📦 ${GREEN}utils${NC} - Development utilities"
  echo "   rebuild [host]     - Quick rebuild with timing"
  echo "   diff [host]        - Show configuration differences"
  echo "   health             - Check configuration health"
  echo "   shell <type>       - Launch development shell"
  echo "   perf               - Monitor system performance"
  echo "   clean              - Clean up development environment"
  echo "   list               - List available environments"
  echo

  # Project init commands
  echo -e "🏗️  ${GREEN}init${NC} - Project initialization"
  echo "   nextjs <name>      - Create Next.js project"
  echo "   rust <name>        - Create Rust project"
  echo "   python <name>      - Create Python project"
  echo

  # Monitor commands
  echo -e "📊 ${GREEN}monitor${NC} - System monitoring"
  echo "   overview           - System and store overview"
  echo "   store              - Nix store analysis"
  echo "   performance        - Build performance tracking"
  echo "   health             - Configuration health check"
  echo "   cleanup            - Interactive cleanup"
  echo "   full               - Complete system analysis"
  echo

  # Quick commands
  echo -e "${CYAN}Quick Commands:${NC}"
  echo -e "⚡ $0 ${GREEN}r${NC}             - Quick rebuild (same as utils rebuild)"
  echo -e "⚡ $0 ${GREEN}s${NC} <type>     - Launch shell (same as utils shell)"
  echo -e "⚡ $0 ${GREEN}h${NC}             - Health check (same as utils health)"
  echo -e "⚡ $0 ${GREEN}m${NC}             - Monitor overview (same as monitor overview)"
  echo

  # Examples
  echo -e "${CYAN}Examples:${NC}"
  echo "  $0 utils rebuild jupiter    - Rebuild jupiter host"
  echo "  $0 init nextjs my-app       - Create Next.js project"
  echo "  $0 monitor performance      - Check build performance"
  echo "  $0 r                        - Quick rebuild"
  echo "  $0 s nextjs                 - Launch Next.js shell"
  echo

  echo -e "${CYAN}Environment:${NC}"
  echo "  Config Root: $CONFIG_ROOT"
  echo "  Script Dir:  $SCRIPT_DIR"
}

# Handle tool routing
route_command() {
  local tool="$1"
  shift

  case "$tool" in
    "utils"|"u")
      "${TOOLS[utils]}" "$@"
      ;;
    "init"|"i")
      "${TOOLS[init]}" "$@"
      ;;
    "monitor"|"mon")
      "${TOOLS[monitor]}" "$@"
      ;;
    # Quick commands
    "r"|"rebuild")
      "${TOOLS[utils]}" rebuild "$@"
      ;;
    "s"|"shell")
      "${TOOLS[utils]}" shell "$@"
      ;;
    "h"|"health")
      "${TOOLS[utils]}" health "$@"
      ;;
    "m"|"mon-quick")
      "${TOOLS[monitor]}" overview "$@"
      ;;
    "d"|"diff")
      "${TOOLS[utils]}" diff "$@"
      ;;
    "p"|"perf")
      "${TOOLS[utils]}" perf "$@"
      ;;
    "c"|"clean")
      "${TOOLS[utils]}" clean "$@"
      ;;
    "l"|"list")
      "${TOOLS[utils]}" list "$@"
      ;;
    *)
      echo -e "${RED}❌ Unknown tool: $tool${NC}"
      echo
      show_help
      exit 1
      ;;
  esac
}

# Interactive mode
interactive_mode() {
  echo -e "${PURPLE}🔧 Interactive Development Mode${NC}"
  echo "Type 'help' for commands, 'exit' to quit"
  echo

  while true; do
    echo -ne "${CYAN}dev>${NC} "
    read -r -a input

    if [[ ${#input[@]} -eq 0 ]]; then
      continue
    fi

    case "${input[0]}" in
      "exit"|"quit"|"q")
        echo "Goodbye!"
        break
        ;;
      "help"|"h"|"?")
        show_help
        ;;
      "clear"|"cls")
        clear
        ;;
      *)
        if route_command "${input[@]}" 2>/dev/null; then
          echo
        else
          echo -e "${RED}Command failed or not found. Type 'help' for available commands.${NC}"
        fi
        ;;
    esac
  done
}

# Status display
show_status() {
  echo -e "${BLUE}📊 Development Environment Status${NC}"
  echo

  # Quick system info
  echo -e "${CYAN}System:${NC} $(hostname) - $(uptime -p)"

  # Git status
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    if git diff-index --quiet HEAD --; then
      echo -e "${CYAN}Git:${NC} ${GREEN}✓ Clean working tree${NC}"
    else
      echo -e "${CYAN}Git:${NC} ${YELLOW}⚠ Uncommitted changes${NC}"
    fi
  fi

  # Nix store size
  local store_size=$(du -sh /nix/store 2>/dev/null | cut -f1 || echo "unknown")
  echo -e "${CYAN}Nix Store:${NC} $store_size"

  # Active processes
  local nix_procs=$(pgrep nix | wc -l || echo "0")
  if [[ $nix_procs -gt 0 ]]; then
    echo -e "${CYAN}Active Builds:${NC} $nix_procs processes"
  else
    echo -e "${CYAN}Active Builds:${NC} None"
  fi

  echo
  echo "Run '$0 monitor full' for detailed analysis"
}

# Main function
main() {
  cd "$CONFIG_ROOT" || {
    echo -e "${RED}❌ Could not change to config directory: $CONFIG_ROOT${NC}"
    exit 1
  }

  # Check if tools exist
  for tool_name in "${!TOOLS[@]}"; do
    if [[ ! -f "${TOOLS[$tool_name]}" ]]; then
      echo -e "${RED}❌ Tool not found: ${TOOLS[$tool_name]}${NC}"
      exit 1
    fi

    if [[ ! -x "${TOOLS[$tool_name]}" ]]; then
      echo -e "${YELLOW}⚠️  Making tool executable: ${TOOLS[$tool_name]}${NC}"
      chmod +x "${TOOLS[$tool_name]}"
    fi
  done

  # Handle different argument patterns
  case "${1:-help}" in
    "help"|"-h"|"--help")
      show_help
      ;;
    "status"|"st")
      show_status
      ;;
    "interactive"|"int")
      interactive_mode
      ;;
    "version"|"-v"|"--version")
      echo "Nix Development CLI v1.0"
      echo "Config: $CONFIG_ROOT"
      ;;
    *)
      if [[ $# -eq 0 ]]; then
        show_help
      else
        route_command "$@"
      fi
      ;;
  esac
}

# Handle script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
