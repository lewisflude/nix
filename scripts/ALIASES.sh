#!/usr/bin/env bash
# Nix Configuration Aliases
# Source this file or add these to your shell config
#
# Usage: source ~/.config/nix/scripts/ALIASES.sh
#
# These aliases replace the deleted wrapper scripts with direct commands
# for better transparency and less complexity.

# Platform detection
if [[ "$(uname)" == "Darwin" ]]; then
  PLATFORM="darwin"
  REBUILD_CMD="darwin-rebuild"
  CONFIG_PATH="${HOME}/.config/nix"
  HOSTNAME=$(hostname -s)
else
  PLATFORM="nixos"
  REBUILD_CMD="nixos-rebuild"
  CONFIG_PATH="${HOME}/.config/nix"
  HOSTNAME=$(hostname)
fi

# Flake management
alias nix-update-flake='nix flake update'
alias nix-metadata='nix flake metadata'
alias nix-check='nix flake check'

# Configuration management
if [[ "$PLATFORM" == "darwin" ]]; then
  alias nix-build='darwin-rebuild build --flake ~/.config/nix'
  alias nix-switch='darwin-rebuild switch --flake ~/.config/nix'
  alias nix-test='darwin-rebuild build --flake ~/.config/nix && echo "✅ Build successful"'
else
  # Use nh on NixOS if available, otherwise fallback to nixos-rebuild
  if command -v nh &> /dev/null; then
    alias nix-build='nh os build'
    alias nix-switch='nh os switch'
    alias nix-test='nh os build'
  else
    alias nix-build='sudo nixos-rebuild build --flake ~/.config/nix'
    alias nix-switch='sudo nixos-rebuild switch --flake ~/.config/nix'
    alias nix-test='sudo nixos-rebuild build --flake ~/.config/nix && echo "✅ Build successful"'
  fi
fi

# Show diffs (requires nvd)
if command -v nvd &> /dev/null; then
  if [[ "$PLATFORM" == "darwin" ]]; then
    alias nix-diff='nvd diff /run/current-system $(darwin-rebuild build --flake ~/.config/nix --print-out-paths | tail -1)'
  else
    alias nix-diff='nvd diff /run/current-system $(nixos-rebuild build --flake ~/.config/nix --print-out-paths | tail -1)'
  fi
fi

# Garbage collection
alias nix-gc='nix-collect-garbage -d'
alias nix-gc-old='nix-collect-garbage --delete-older-than 30d'

# Store optimization
alias nix-optimize='nix store optimise'

# Store inspection
alias nix-store-size='du -sh /nix/store'
alias nix-store-dead='nix-store --gc --print-dead | wc -l'
alias nix-why-depends='nix-store --query --roots'

# Development shells
alias nix-shell-node='nix develop ~/.config/nix#projects.node'
alias nix-shell-nextjs='nix develop ~/.config/nix#projects.nextjs'
alias nix-shell-python='nix develop ~/.config/nix#projects.python'
alias nix-shell-rust='nix develop ~/.config/nix#projects.rust'
alias nix-shell-qmk='nix develop ~/.config/nix#projects.qmk'

# Monitoring
alias nix-monitor='~/.config/nix/scripts/build/nix-monitor.sh'
alias nix-monitor-full='~/.config/nix/scripts/build/nix-monitor.sh full'

# Useful functions
nix-search-pkg() {
  if [[ -z "$1" ]]; then
    echo "Usage: nix-search-pkg <package-name>"
    return 1
  fi
  nix search nixpkgs "$1"
}

nix-info-pkg() {
  if [[ -z "$1" ]]; then
    echo "Usage: nix-info-pkg <package-name>"
    return 1
  fi
  nix eval "nixpkgs#$1.meta.description"
}

nix-tree-current() {
  if command -v nix-tree &> /dev/null; then
    if [[ "$PLATFORM" == "darwin" ]]; then
      nix-tree /run/current-system
    else
      nix-tree /run/current-system
    fi
  else
    echo "nix-tree not installed. Install with: nix profile install nixpkgs#nix-tree"
  fi
}

# Help function
nix-aliases-help() {
  echo "Nix Configuration Aliases"
  echo "========================="
  echo ""
  echo "Flake Management:"
  echo "  nix-update-flake    - Update flake.lock"
  echo "  nix-metadata        - Show flake metadata"
  echo "  nix-check           - Check flake validity"
  echo ""
  echo "Configuration:"
  echo "  nix-build           - Build configuration"
  echo "  nix-switch          - Build and activate configuration"
  echo "  nix-test            - Test build (verify it works)"
  echo "  nix-diff            - Show package differences (requires nvd)"
  echo ""
  echo "Maintenance:"
  echo "  nix-gc              - Garbage collect old generations"
  echo "  nix-gc-old          - Delete generations older than 30 days"
  echo "  nix-optimize        - Optimize store (deduplicate)"
  echo ""
  echo "Inspection:"
  echo "  nix-store-size      - Show Nix store size"
  echo "  nix-store-dead      - Count dead paths"
  echo "  nix-monitor         - System monitoring tool"
  echo "  nix-tree-current    - Visualize current system dependencies"
  echo ""
  echo "Functions:"
  echo "  nix-search-pkg <pkg>   - Search for package"
  echo "  nix-info-pkg <pkg>     - Show package info"
  echo ""
  echo "Development Shells:"
  echo "  nix-shell-node         - Node.js development shell"
  echo "  nix-shell-nextjs       - Next.js development shell"
  echo "  nix-shell-python       - Python development shell"
  echo "  nix-shell-rust         - Rust development shell"
  echo "  nix-shell-qmk          - QMK keyboard development shell"
}

# Export functions
export -f nix-search-pkg
export -f nix-info-pkg
export -f nix-tree-current
export -f nix-aliases-help

echo "✅ Nix aliases loaded. Type 'nix-aliases-help' for available commands."
