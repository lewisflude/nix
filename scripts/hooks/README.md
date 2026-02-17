# Claude Code Hooks for Dendritic Pattern Enforcement

This directory contains hook scripts that enforce the dendritic pattern in
real-time during Claude Code sessions.

## Overview

The enforcement system uses a **layered approach** with 6 complementary
mechanisms to ensure all code follows the dendritic pattern.

## Documentation References

All hooks follow patterns documented in:

- **Claude Code Hooks Documentation**: <https://code.claude.com/docs/hooks>
- **Dendritic Pattern**: `DENDRITIC_PATTERN.md`
- **Repository Guidelines**: `CLAUDE.md`

## Enforcement Stack

### Layer 1: Education (Always Active)

- **Source**: `CLAUDE.md` + `DENDRITIC_PATTERN.md`
- **When**: Loaded at session start via `SessionStart` hook
- **Effect**: Claude understands the pattern rules
- **Determinism**: Low (relies on Claude's understanding)

### Layer 2: Expert Skills (On-Demand)

- **Source**: `.claude/skills/nix-module-expert/`,
  `.claude/skills/feature-validator/`, `.claude/skills/dendritic-validator/`
- **When**: Auto-invoked when relevant, or manual `/skill-name`
- **Effect**: Expert analysis and recommendations
- **Determinism**: Medium (AI-powered analysis)

### Layer 3: Pre-Edit Validation (Real-Time Blocking) ⭐ HIGH IMPACT

- **Source**: `validate-dendritic.sh`
- **When**: Before EVERY `Edit` or `Write` operation on `.nix` files
- **Effect**: **BLOCKS anti-patterns** before code is written
- **Determinism**: High (deterministic regex checks)
- **Documentation**:
  [PreToolUse Hooks](https://code.claude.com/docs/hooks#pretooluse)

**How it works** (per Claude Code docs):

1. Hook receives tool call JSON via stdin
2. Extracts `file_path` and `content`/`new_string`
3. Runs validation checks
4. Exit code `2` = **BLOCK** (prevents write, shows error to Claude and user)
5. Exit code `0` = allow
6. Exit code `1` = warning (shows error but allows)

**What it blocks**:

- ❌ `with pkgs;` usage
- ❌ `specialArgs` / `extraSpecialArgs`
- ❌ Direct constant imports (`import ../lib/constants.nix`)
- ❌ Config scope confusion (shadowing)
- ⚠️ Missing `flake.modules.*` in feature modules

### Layer 4: Post-Edit Formatting (Automatic Cleanup)

- **Source**: `auto-format-nix.sh`
- **When**: After EVERY `Edit` or `Write` operation on `.nix` files
- **Effect**: Auto-formats code with treefmt/nixfmt
- **Determinism**: High (deterministic formatting)
- **Documentation**:
  [PostToolUse Hooks](https://code.claude.com/docs/hooks#posttooluse)

**Formatters tried** (in order):

1. `treefmt` (recommended)
2. `nixfmt` (fallback)
3. `nix fmt` (fallback)

### Layer 5: Post-Edit Linting (Issue Detection)

- **Source**: `strict-lint-check.sh`
- **When**: After EVERY `Edit` or `Write` operation on `.nix` files
- **Effect**: Reports issues (doesn't block, Claude self-corrects)
- **Determinism**: High (linters are deterministic)
- **Documentation**:
  [PostToolUse Hooks](https://code.claude.com/docs/hooks#posttooluse)

**Linters run**:

1. `statix check` - Nix anti-patterns and best practices
2. `deadnix` - Dead code detection
3. `nix flake check --no-build` - Flake validation (if flake.nix modified)

### Layer 6: Session-End Validation (Final Gate)

- **Source**: `validate-session-dendritic.sh` + agent-based hook
- **When**: When Claude session ends
- **Effect**: Comprehensive validation of all changes
- **Determinism**: High (command) + Medium (agent)
- **Documentation**:
  [SessionEnd Hooks](https://code.claude.com/docs/hooks#sessionend)

**Two-phase validation**:

1. **Command hook**: Quick anti-pattern scan of modified files
2. **Agent hook**: Deep architectural analysis with AI

## Hook Scripts

### 1. validate-dendritic.sh (HIGH IMPACT)

**Purpose**: Real-time dendritic pattern enforcement

**Trigger**: `PreToolUse` hook on `Edit|Write` operations

**Exit Codes** (per Claude Code documentation):

- `0` = Allow the operation
- `2` = **BLOCK** the operation (shows error to Claude)
- `1` = Hook error (shows warning)

**Checks Performed**:

```bash
# Anti-pattern 1: with pkgs;
grep -q "with pkgs;"

# Anti-pattern 2: specialArgs
grep -qE "(special|extra)Args"

# Anti-pattern 3: Direct constant imports
grep -qE "import.*(lib/constants|constants\.nix)"

# Anti-pattern 4: flakeModules.modules in wrong location
grep -q "flake-parts.flakeModules.modules"

# Pattern 5: Feature modules should define flake.modules.*
grep -q "flake\.modules\."

# Anti-pattern 6: Config scope confusion
grep -P '{\s*config.*?flake\.modules\.\w+\.\w+\s*=\s*{\s*config'
```

**Example Output** (when blocking):

```
🚫 Dendritic Pattern Violation in: modules/audio.nix

   ❌ Anti-pattern 'with pkgs;' detected
   Use explicit package references: pkgs.curl pkgs.wget
   See: DENDRITIC_PATTERN.md line 1020-1026

   📖 Read DENDRITIC_PATTERN.md for complete pattern guide
   💡 Ask: 'Can you fix this following dendritic pattern?'
```

**Documentation References in Code**:

- Line 4-7: Exit code behavior from Claude Code docs
- Line 88-91: `with pkgs;` anti-pattern (DENDRITIC_PATTERN.md:1020-1026)
- Line 94-98: specialArgs anti-pattern (DENDRITIC_PATTERN.md:477-527)
- Line 101-105: Constants access pattern (DENDRITIC_PATTERN.md:723-766)
- Line 108-112: flakeModules placement (DENDRITIC_PATTERN.md:129-148)
- Line 126-132: Feature module structure (DENDRITIC_PATTERN.md:280-348)
- Line 136-141: Scope confusion (DENDRITIC_PATTERN.md:306-341)

### 2. auto-format-nix.sh

**Purpose**: Automatic code formatting after edits

**Trigger**: `PostToolUse` hook on `Edit|Write` operations

**Exit Codes**:

- `0` = Success (formatted successfully)
- `1` = Warning (no formatter available)

**Formatters** (tried in order):

1. `treefmt` - Repository-wide formatter
2. `nixfmt` - Nix-specific formatter
3. `nix fmt` - Flake-based formatter

**Example Output**:

```
🎨 Auto-formatting: modules/audio.nix
✅ Formatted with treefmt
```

### 3. strict-lint-check.sh

**Purpose**: Post-edit linting and issue detection

**Trigger**: `PostToolUse` hook on `Edit|Write` operations

**Exit Codes**: Always `0` (never blocks, Claude sees output and self-corrects)

**Linters Run**:

1. `statix check` - Nix anti-patterns
2. `deadnix` - Dead code detection
3. `nix flake check` - Flake validation (if applicable)

**Example Output**:

```
🔍 Linting: modules/audio.nix
⚠️  Linting issues found:
warning: [empty_pattern]
  This `let`-in has no variables bound
  at modules/audio.nix:5:1

💡 Claude: Please review and fix these issues
```

### 4. validate-session-dendritic.sh

**Purpose**: Session-end comprehensive validation

**Trigger**: `SessionEnd` hook (command phase)

**Exit Codes**: Always `0` (reports but doesn't block)

**Checks Performed**:

1. Finds all modified `.nix` files in `modules/`
2. Scans each for anti-patterns
3. Reports violations with file references

**Example Output**:

```
🔍 Performing comprehensive dendritic pattern validation...
📝 Modified modules:
   - modules/audio.nix
   - modules/gaming.nix

⚠️  Dendritic pattern violations detected:
   - modules/audio.nix: contains 'with pkgs;'

💡 Consider reviewing these files before committing
   Run: /feature-validator to validate modules
```

## Hook Configuration

Configuration is in `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/hooks/validate-dendritic.sh",
            "timeout": 10,
            "description": "Validate dendritic pattern compliance before writing code"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/hooks/auto-format-nix.sh",
            "timeout": 30
          },
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/hooks/strict-lint-check.sh",
            "timeout": 15
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/hooks/validate-session-dendritic.sh",
            "timeout": 15,
            "description": "Comprehensive dendritic pattern validation"
          },
          {
            "type": "agent",
            "prompt": "Perform final validation of all Nix module changes...",
            "timeout": 120,
            "description": "Agent-based comprehensive validation"
          }
        ]
      }
    ]
  }
}
```

## Claude Code Hook Types

Per [Claude Code documentation](https://code.claude.com/docs/hooks), three types
of hooks are supported:

### 1. Command Hooks (Used: Layers 3, 4, 5, 6)

**How they work**:

- Receive tool call JSON via stdin
- Execute shell command
- Return exit code:
  - `0` = Success/allow
  - `1` = Warning
  - `2` = **BLOCK** (PreToolUse only)

**Best for**: Deterministic validation (regex, linters, formatters)

**Our usage**:

- `validate-dendritic.sh` - Blocks anti-patterns
- `auto-format-nix.sh` - Auto-formats code
- `strict-lint-check.sh` - Runs linters
- `validate-session-dendritic.sh` - Final scan

### 2. Prompt-Based Hooks (Not used)

**How they work**:

- Send prompt to Claude
- Claude responds with JSON: `{"ok": true}` or `{"ok": false, "reason": "..."}`
- Can block based on response

**Best for**: Context-aware decisions requiring understanding

**Why not used**: Command hooks are faster and more deterministic for our checks

### 3. Agent-Based Hooks (Used: Layer 6)

**How they work**:

- Launch a full Claude agent with tools
- Agent performs complex multi-step tasks
- Returns result to session

**Best for**: Complex validation requiring file inspection and analysis

**Our usage**:

- SessionEnd agent: Deep architectural validation with context from
  DENDRITIC_PATTERN.md

## Testing the Hooks

### Test 1: Block `with pkgs;`

Try having Claude write this:

```nix
{ config, ... }:
{
  flake.modules.homeManager.test = { pkgs, ... }: {
    home.packages = with pkgs; [ curl wget ];
  };
}
```

**Expected**: Hook blocks with error message citing
DENDRITIC_PATTERN.md:1020-1026

### Test 2: Block `specialArgs`

Try having Claude write infrastructure with:

```nix
lib.nixosSystem {
  specialArgs = { inherit inputs; };
}
```

**Expected**: Hook blocks with error message citing DENDRITIC_PATTERN.md:477-527

### Test 3: Auto-format

Have Claude write any valid Nix code without formatting.

**Expected**: `auto-format-nix.sh` runs and formats the file automatically

### Test 4: Linting

Have Claude write code with dead code:

```nix
let
  unused = "value";
in
{ }
```

**Expected**: `strict-lint-check.sh` reports dead code, Claude sees output and
can fix

## Debugging Hooks

### View Hook Execution

Hooks log to stderr. To see hook output:

```bash
# Run Claude with debug output
claude --log-level debug
```

### Test Hook Manually

```bash
# Simulate a Write tool call
echo '{
  "tool_name": "Write",
  "tool_input": {
    "file_path": "modules/test.nix",
    "content": "{ pkgs, ... }: { home.packages = with pkgs; [ curl ]; }"
  }
}' | ./scripts/hooks/validate-dendritic.sh

# Check exit code
echo $?  # Should be 2 (blocked)
```

### Disable Hooks Temporarily

To disable hooks for a session:

```bash
# Rename settings file
mv .claude/settings.json .claude/settings.json.bak

# Run Claude (no hooks)
claude

# Restore
mv .claude/settings.json.bak .claude/settings.json
```

## Maintenance

### Adding New Anti-Pattern Checks

Edit `validate-dendritic.sh` and add checks in the validation section:

```bash
# Anti-pattern N: Description
if echo "$CONTENT" | grep -q "pattern"; then
  ERRORS+=("❌ Anti-pattern 'pattern' detected")
  ERRORS+=("   Explanation and fix")
  ERRORS+=("   See: DENDRITIC_PATTERN.md line XXX-YYY")
fi
```

### Updating Validation Logic

1. Update `validate-dendritic.sh` for blocking validation
2. Update `validate-session-dendritic.sh` for session-end checks
3. Update `.claude/skills/dendritic-validator/SKILL.md` for skill validation
4. Update `DENDRITIC_PATTERN.md` with new pattern documentation
5. Test with sample violations

## Impact Summary

| Hook                              | Impact    | Purpose                         | Blocks | When             |
| --------------------------------- | --------- | ------------------------------- | ------ | ---------------- |
| **validate-dendritic.sh**         | 🔴 HIGH   | Real-time anti-pattern blocking | ✅ Yes | Every Edit/Write |
| **auto-format-nix.sh**            | 🟡 MEDIUM | Code formatting                 | ❌ No  | After Edit/Write |
| **strict-lint-check.sh**          | 🟡 MEDIUM | Issue detection                 | ❌ No  | After Edit/Write |
| **validate-session-dendritic.sh** | 🟡 MEDIUM | Comprehensive scan              | ❌ No  | Session end      |
| **Agent validation**              | 🟡 MEDIUM | Deep analysis                   | ❌ No  | Session end      |

## References

- **Claude Code Hooks**: <https://code.claude.com/docs/hooks>
- **Dendritic Pattern**: `DENDRITIC_PATTERN.md`
- **Repository Guidelines**: `CLAUDE.md`
- **Skills Documentation**: `.claude/skills/*/SKILL.md`
