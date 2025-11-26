# Claude Code Hook Scripts

These scripts are automatically executed by Claude Code at specific lifecycle events. They enforce code quality, safety standards, and provide context to the AI assistant.

**Integration**: `.claude/settings.json`

## Available Hooks (7 scripts)

### Session Management

#### `load-context.sh`

**Hook**: SessionStart
**Purpose**: Load project context when Claude Code starts a new session

**Output** (added to Claude's context):

- Current git branch
- Last 3 commits
- Working tree status

**Performance**: ~100ms overhead

---

#### `final-git-check.sh`

**Hook**: SessionEnd
**Purpose**: Display session summary when Claude Code ends

**Output**:

- Current branch
- Working tree status
- Recent activity (last 3 commits)

---

#### `preserve-nix-context.sh`

**Hook**: PreCompact
**Purpose**: Preserve critical context before conversation compaction

**Preserves**:

- Critical rules (no system rebuilds, no `with pkgs;`, module placement)
- Current work context (branch, changes)
- Active modules being edited
- Documentation references

---

### Command Safety

#### `block-dangerous-commands.sh`

**Hook**: PreToolUse (Bash)
**Purpose**: Block dangerous commands before Claude executes them

**Blocked operations**:

- System rebuilds: `nh os switch`, `nixos-rebuild`, `darwin-rebuild`
- Destructive file operations: `rm -rf`, `mv to /dev/null`
- Git force operations: `git push --force`, `git reset --hard`
- Production host access: patterns `prod*`, `production*`, `*-prod`, `*-production`

**Exit codes**:

- `0`: Command allowed
- `2`: Command blocked (shown to Claude)

**Example blocked command**:

```bash
# ❌ BLOCKED
sudo nixos-rebuild switch

# Output:
# ❌ System rebuild commands are blocked per CLAUDE.md guidelines.
# Please run this command manually: sudo nixos-rebuild switch
```

---

### Code Quality

#### `auto-format-nix.sh`

**Hook**: PostToolUse (Write|Edit)
**Purpose**: Automatically format Nix files after Claude edits them

**Behavior**:

- Runs `nixfmt` on all `.nix` files after Write/Edit operations
- Blocks (exit 2) if formatting fails (indicates syntax errors)
- Skips non-Nix files silently

**Requirements**: `nixfmt` must be in PATH (available in `nix develop`)

**Example**:

```bash
# Claude edits module.nix
# → auto-format-nix.sh runs automatically
# → nixfmt formats the file
# → ✓ Formatted: module.nix
```

---

#### `strict-lint-check.sh`

**Hook**: PostToolUse (Write|Edit)
**Purpose**: Enforce code quality standards and architectural guidelines

**Checks performed**:

1. **statix**: Nix antipattern detection
2. **deadnix**: Unused code detection
3. **`with pkgs;` antipattern**: Enforces explicit package references (from `CLAUDE.md`)
4. **Module placement validation**: Ensures system vs home-manager separation

**Exit codes**:

- `0`: All checks passed
- `2`: Issues found (blocks Claude, requires fixes)

**Example validation failure**:

```bash
# Claude writes: home.packages = with pkgs; [ curl ];
# → strict-lint-check.sh detects antipattern
# → ❌ ANTIPATTERN: Found 'with pkgs;' usage
# → Please use explicit references: pkgs.curl
```

---

#### `statusline.sh`

**Hook**: StatusLine
**Purpose**: Display session information in Claude Code's status bar

**Displays**:

- Model name
- Directory name
- Git branch
- Lines added/removed in session
- Session cost (USD)

**Format**: `[model] dir:branch | +lines/-lines | $cost`

**Example**: `[Claude 3.5 Sonnet] nix:main | +42/-13 | $0.23`

---

## Hook Configuration

Hooks are configured in `.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "type": "command",
        "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/hooks/load-context.sh",
        "timeout": 10
      }
    ],
    "SessionEnd": [
      {
        "type": "command",
        "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/hooks/final-git-check.sh",
        "timeout": 10
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "type": "command",
        "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/hooks/block-dangerous-commands.sh",
        "timeout": 5
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "type": "command",
        "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/hooks/auto-format-nix.sh",
        "timeout": 30
      },
      {
        "matcher": "Write|Edit",
        "type": "command",
        "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/hooks/strict-lint-check.sh",
        "timeout": 15
      }
    ],
    "PreCompact": [
      {
        "type": "command",
        "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/hooks/preserve-nix-context.sh",
        "timeout": 10
      }
    ]
  },
  "statusLine": {
    "type": "command",
    "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/hooks/statusline.sh",
    "padding": 0
  }
}
```

## Testing Hooks

You can test hooks manually by simulating Claude Code's input format:

```bash
# Test block-dangerous-commands.sh
echo '{"tool_name":"Bash","tool_input":{"command":"nh os switch"}}' | \
  ./scripts/hooks/block-dangerous-commands.sh

# Test auto-format-nix.sh (requires a .nix file)
echo '{"tool_name":"Write","tool_input":{"file_path":"test.nix"}}' | \
  ./scripts/hooks/auto-format-nix.sh

# Test load-context.sh (no input needed)
./scripts/hooks/load-context.sh
```

## Troubleshooting

### Hook not executing

1. Check `.claude/settings.json` has correct path
2. Verify script is executable: `chmod +x scripts/hooks/*.sh`
3. Check logs in Claude Code's output panel

### Hook timeout

1. Increase timeout in `.claude/settings.json`
2. Optimize script performance
3. Consider moving heavy operations to background

### Hook blocking legitimate operations

1. Review the blocking rules in the script
2. Adjust patterns if needed
3. Consider adding exclusions for specific cases

## Development

When creating new hooks:

1. Follow the standard script header format (see `scripts/templates/generic-script.sh`)
2. Handle JSON input via stdin (for PreToolUse/PostToolUse hooks)
3. Use exit code 0 for success, 2 for blocking operations
4. Keep execution time under 5-10 seconds
5. Add to `.claude/settings.json`
6. Test manually before relying on it

## See Also

- [Claude Code Documentation](../../docs/AI_TOOLS.md#claude-code)
- [AI Assistant Guidelines](../../CLAUDE.md)
- [Agent Instructions](../../AGENTS.md)
- [Script Organization Proposal](../../docs/SCRIPT_ORGANIZATION_PROPOSAL.md)
