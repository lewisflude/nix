#!/usr/bin/env bash
# AI Tool Configuration Setup and Validation
# Helps verify and test AI tool configurations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Change to repository root
cd "$(dirname "$(dirname "$(readlink -f "$0")")")"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🤖 AI Tool Configuration Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Function to check if file exists
check_file() {
  local file=$1
  local name=$2

  if [[ -f "$file" ]]; then
    echo -e "${GREEN}✓${NC} $name: Found"
    return 0
  else
    echo -e "${RED}✗${NC} $name: Missing"
    return 1
  fi
}

# Function to check if directory exists
check_dir() {
  local dir=$1
  local name=$2

  if [[ -d "$dir" ]]; then
    echo -e "${GREEN}✓${NC} $name: Found"
    return 0
  else
    echo -e "${RED}✗${NC} $name: Missing"
    return 1
  fi
}

# Track status
all_passed=true

echo -e "${YELLOW}Checking Multi-Tool Documentation:${NC}"
check_file "CLAUDE.md" "AI Guidelines" || all_passed=false
check_file "GEMINI.md" "Gemini Rules" || all_passed=false
check_file "CONVENTIONS.md" "Coding Conventions" || all_passed=false
check_file "AGENTS.md" "Agent Instructions" || all_passed=false
check_file "AI_TOOLS.md" "AI Tools Guide" || all_passed=false
echo ""

echo -e "${YELLOW}Checking Tool-Specific Configs:${NC}"
check_file ".cursorrules" "Cursor Rules" || all_passed=false
check_file ".aider.conf.yml" "Aider Config" || all_passed=false
check_file ".clinerules" "Cline Rules" || all_passed=false
check_file "projectBrief.md" "Cline Project Brief" || all_passed=false
check_file "techContext.md" "Cline Tech Context" || all_passed=false
echo ""

echo -e "${YELLOW}Checking Claude Code Integration:${NC}"
check_dir ".claude" "Claude Directory" || all_passed=false
check_file ".claude/settings.json" "Claude Settings" || all_passed=false
check_file ".claude/settings.local.json" "Claude Local Settings" || all_passed=false
check_dir ".claude/commands" "Slash Commands" || all_passed=false
check_dir ".claude/skills" "Skills Directory" || all_passed=false
echo ""

echo -e "${YELLOW}Checking Hook Scripts:${NC}"
check_file "scripts/load-context.sh" "Context Loader" || all_passed=false
check_file "scripts/block-dangerous-commands.sh" "Command Blocker" || all_passed=false
check_file "scripts/auto-format-nix.sh" "Auto Formatter" || all_passed=false
check_file "scripts/strict-lint-check.sh" "Lint Checker" || all_passed=false
check_file "scripts/final-git-check.sh" "Final Git Check" || all_passed=false
check_file "scripts/preserve-nix-context.sh" "Context Preserver" || all_passed=false
echo ""

echo -e "${YELLOW}Checking Slash Commands:${NC}"
check_file ".claude/commands/diagnose.md" "/diagnose" || all_passed=false
check_file ".claude/commands/validate-module.md" "/validate-module" || all_passed=false
check_file ".claude/commands/format-project.md" "/format-project" || all_passed=false
check_file ".claude/commands/nix/check-build.md" "/nix/check-build" || all_passed=false
check_file ".claude/commands/nix/trace-dep.md" "/nix/trace-dep" || all_passed=false
check_file ".claude/commands/nix/update.md" "/nix/update" || all_passed=false
echo ""

echo -e "${YELLOW}Checking Skills:${NC}"
check_file ".claude/skills/nix-module-expert/SKILL.md" "Nix Module Expert" || all_passed=false
check_file ".claude/skills/feature-validator/SKILL.md" "Feature Validator" || all_passed=false
check_file ".claude/skills/doc-reviewer/SKILL.md" "Doc Reviewer" || all_passed=false
echo ""

echo -e "${YELLOW}Testing Hook Script Permissions:${NC}"
if [[ -x "scripts/load-context.sh" ]]; then
  echo -e "${GREEN}✓${NC} load-context.sh: Executable"
else
  echo -e "${RED}✗${NC} load-context.sh: Not executable (run: chmod +x scripts/load-context.sh)"
  all_passed=false
fi

if [[ -x "scripts/block-dangerous-commands.sh" ]]; then
  echo -e "${GREEN}✓${NC} block-dangerous-commands.sh: Executable"
else
  echo -e "${RED}✗${NC} block-dangerous-commands.sh: Not executable (run: chmod +x scripts/block-dangerous-commands.sh)"
  all_passed=false
fi

if [[ -x "scripts/final-git-check.sh" ]]; then
  echo -e "${GREEN}✓${NC} final-git-check.sh: Executable"
else
  echo -e "${RED}✗${NC} final-git-check.sh: Not executable (run: chmod +x scripts/final-git-check.sh)"
  all_passed=false
fi
echo ""

echo -e "${YELLOW}Testing Hook Scripts:${NC}"
if ./scripts/load-context.sh >/dev/null 2>&1; then
  echo -e "${GREEN}✓${NC} load-context.sh: Works"
else
  echo -e "${RED}✗${NC} load-context.sh: Failed to run"
  all_passed=false
fi

if echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | ./scripts/block-dangerous-commands.sh >/dev/null 2>&1; then
  echo -e "${GREEN}✓${NC} block-dangerous-commands.sh: Works"
else
  echo -e "${RED}✗${NC} block-dangerous-commands.sh: Failed to run"
  all_passed=false
fi
echo ""

echo -e "${YELLOW}Checking Formatting Tools:${NC}"
if command -v nix &> /dev/null; then
  echo -e "${GREEN}✓${NC} nix: Available"
else
  echo -e "${RED}✗${NC} nix: Not found"
  all_passed=false
fi

if command -v treefmt &> /dev/null; then
  echo -e "${GREEN}✓${NC} treefmt: Available"
elif nix run .#treefmt -- --version &> /dev/null; then
  echo -e "${GREEN}✓${NC} treefmt: Available (via flake)"
else
  echo -e "${YELLOW}⚠${NC} treefmt: Not available (formatting may not work)"
fi
echo ""

# Final summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if $all_passed; then
  echo -e "${GREEN}✓ All checks passed!${NC}"
  echo ""
  echo "AI tool configurations are properly set up."
  echo ""
  echo "Configured tools:"
  echo "  • Claude Code - Full integration (hooks, commands, skills)"
  echo "  • Gemini Code Assist - Context and rules configured"
  echo "  • Cursor AI - Rules and agent mode ready"
  echo "  • Aider - YAML configuration complete"
  echo "  • Cline - Rules and memory bank configured"
  echo ""
  echo "Next steps:"
  echo "  1. Start using your preferred AI tool"
  echo "  2. See AI_TOOLS.md for tool-specific guides"
  echo "  3. Review CLAUDE.md for general guidelines"
else
  echo -e "${RED}✗ Some checks failed${NC}"
  echo ""
  echo "Please review the errors above and fix missing configurations."
  echo "See AI_TOOLS.md for setup instructions."
fi
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Exit with appropriate code
if $all_passed; then
  exit 0
else
  exit 1
fi
