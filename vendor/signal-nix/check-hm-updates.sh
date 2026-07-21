#!/usr/bin/env bash
# check-hm-updates.sh
# 
# Checks for Home-Manager updates that might add new theme/color options
# for applications we integrate with Signal Design System.
#
# This helps detect schema drift and identifies when we should upgrade
# from a lower tier (e.g., raw-config) to a higher tier (e.g., native-theme).

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Applications we integrate (module name -> category)
declare -A APPS=(
  # Terminals
  ["kitty"]="terminals"
  ["alacritty"]="terminals"
  ["wezterm"]="terminals"
  ["ghostty"]="terminals"
  
  # CLI tools
  ["bat"]="cli"
  ["delta"]="cli"
  ["eza"]="cli"
  ["fzf"]="cli"
  ["lazygit"]="cli"
  ["yazi"]="cli"
  
  # Editors
  ["helix"]="editors"
  ["neovim"]="editors"
  
  # Desktop
  ["fuzzel"]="desktop"
  
  # Prompts
  ["starship"]="prompts"
  
  # Shells
  ["zsh"]="shells"
  
  # Monitors
  ["btop"]="monitors"
  
  # Multiplexers
  ["tmux"]="multiplexers"
  ["zellij"]="multiplexers"
)

# Theme-related keywords to search for
THEME_KEYWORDS=(
  "theme"
  "themes"
  "color"
  "colors"
  "colour"
  "colours"
  "style"
  "styles"
  "palette"
  "colorscheme"
)

echo -e "${BLUE}=== Home-Manager Theme Option Scanner ===${NC}"
echo -e "${BLUE}Checking for new theme/color options...${NC}\n"

# Check if Home-Manager is available
if ! command -v home-manager &> /dev/null; then
  echo -e "${RED}Error: home-manager command not found${NC}"
  echo "Please ensure Home-Manager is installed and in your PATH"
  exit 1
fi

# Get Home-Manager version
HM_VERSION=$(home-manager --version 2>/dev/null || echo "unknown")
echo -e "Home-Manager version: ${GREEN}${HM_VERSION}${NC}\n"

# Function to check a single app for theme options
check_app() {
  local app=$1
  local category=$2
  
  echo -e "${YELLOW}Checking ${app}...${NC}"
  
  # Try to evaluate the Home-Manager module options
  # This uses nix eval to check what options are available
  local options_exist=false
  local found_options=()
  
  # Check if programs.$app exists
  if nix eval --impure --expr "
    let
      hm = builtins.getFlake \"github:nix-community/home-manager\";
      pkgs = import <nixpkgs> {};
    in
    builtins.hasAttr \"${app}\" (builtins.functionArgs (import \${hm}/modules/programs/${app}.nix))
  " 2>/dev/null | grep -q "true"; then
    options_exist=true
  fi
  
  if [ "$options_exist" = false ]; then
    # Try alternative path
    if nix eval --impure --expr "
      let
        hm = builtins.getFlake \"github:nix-community/home-manager\";
      in
      builtins.pathExists \${hm}/modules/programs/${app}
    " 2>/dev/null | grep -q "true"; then
      options_exist=true
    fi
  fi
  
  if [ "$options_exist" = false ]; then
    echo -e "  ${RED}✗${NC} No Home-Manager module found"
    return
  fi
  
  # Search for theme-related options
  for keyword in "${THEME_KEYWORDS[@]}"; do
    # Try to list options containing the keyword
    if nix eval --impure --raw --expr "
      let
        hm = builtins.getFlake \"github:nix-community/home-manager\";
        pkgs = import <nixpkgs> {};
        opts = (import \${hm}/modules/programs/${app}.nix { inherit pkgs; lib = pkgs.lib; config = {}; }).options or {};
      in
      builtins.toJSON (builtins.attrNames (pkgs.lib.filterAttrs (n: v: pkgs.lib.hasInfix \"${keyword}\" (builtins.toString n)) opts))
    " 2>/dev/null; then
      local result=$(nix eval --impure --raw --expr "
        let
          hm = builtins.getFlake \"github:nix-community/home-manager\";
          pkgs = import <nixpkgs> {};
          opts = (import \${hm}/modules/programs/${app}.nix { inherit pkgs; lib = pkgs.lib; config = {}; }).options or {};
        in
        builtins.toJSON (builtins.attrNames (pkgs.lib.filterAttrs (n: v: pkgs.lib.hasInfix \"${keyword}\" (builtins.toString n)) opts))
      " 2>/dev/null || echo "[]")
      
      if [ "$result" != "[]" ]; then
        found_options+=("$keyword: $result")
      fi
    fi
  done
  
  if [ ${#found_options[@]} -gt 0 ]; then
    echo -e "  ${GREEN}✓${NC} Found theme-related options:"
    for opt in "${found_options[@]}"; do
      echo -e "    ${BLUE}→${NC} $opt"
    done
  else
    echo -e "  ${GREEN}✓${NC} Module exists, no new theme options detected"
  fi
}

# Main scan loop
for app in "${!APPS[@]}"; do
  check_app "$app" "${APPS[$app]}"
  echo ""
done

echo -e "${BLUE}=== Scan Complete ===${NC}"
echo -e "\n${YELLOW}Recommendations:${NC}"
echo "1. Review any new theme options found above"
echo "2. Check if we can upgrade from lower tiers (raw-config, freeform-settings)"
echo "3. Update module metadata comments with new findings"
echo "4. Test new options in a development environment before deploying"

echo -e "\n${BLUE}Current tier distribution:${NC}"
echo "  - Tier 1 (native-theme): bat, helix"
echo "  - Tier 2 (structured-colors): alacritty"
echo "  - Tier 3 (freeform-settings): kitty, ghostty, delta, lazygit, yazi, fuzzel, starship, zellij"
echo "  - Tier 4 (raw-config): wezterm, eza, fzf, neovim, zsh, btop, tmux, gtk"

echo -e "\n${GREEN}Done!${NC}"
