# Validation & Configuration Testing Scripts

Scripts for validating system configuration and AI tool setups. These ensure your Nix configuration is correct before applying changes and verify that AI tooling is properly configured.

**Integration**: Standalone validation tools (manual execution)

## Available Scripts (2 scripts)

### Configuration Validation

#### `validate-config.sh`

**Integration**: standalone validation tool
**Purpose**: Validate Nix configuration before rebuilding the system

**Usage**:

```bash
./scripts/validation/validate-config.sh
```

**What it validates**:

1. **Flake syntax** - Ensures flake.nix is syntactically correct
2. **Build success** - Attempts to build configuration without applying
3. **Module imports** - Verifies all modules can be imported
4. **Option conflicts** - Detects conflicting options
5. **Deprecated options** - Warns about deprecated configuration

**Output Example**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Nix Configuration Validation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Checking flake syntax...
   ✓ Flake syntax is valid

2. Building NixOS configuration (dry-run)...
   ✓ Configuration builds successfully

3. Checking for deprecated options...
   ⚠️ Found 1 deprecated option:
   - services.xserver.enable → services.displayManager.enable

4. Checking for conflicts...
   ✓ No conflicts detected

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary: Configuration is valid ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Safe to rebuild with: nh os switch
```

**When to use**:

- Before running `nh os switch` or `nixos-rebuild switch`
- After making configuration changes
- Before committing changes to git
- In pre-commit hooks (automated)
- Before pushing to remote

**Integration with git hooks**:

```bash
# .git/hooks/pre-commit
#!/usr/bin/env bash
./scripts/validation/validate-config.sh || exit 1
```

---

### AI Tool Configuration

#### `ai-tool-setup.sh`

**Integration**: standalone validation tool
**Purpose**: Verify and test AI tool configurations across multiple AI assistants

**Usage**:

```bash
./scripts/validation/ai-tool-setup.sh
```

**What it validates**:

1. **Documentation files** - CLAUDE.md, GEMINI.md, CONVENTIONS.md, AGENTS.md, AI_TOOLS.md
2. **Tool-specific configs** - .cursorrules, .aider.conf.yml, .clinerules, projectBrief.md, techContext.md
3. **Claude Code integration** - .claude/ directory, settings.json, commands, skills
4. **Hook scripts** - Existence, permissions, functionality
5. **Formatting tools** - nix, treefmt availability

**Output Example**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 AI Tool Configuration Setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Checking Multi-Tool Documentation:
✓ AI Guidelines: Found
✓ Gemini Rules: Found
✓ Coding Conventions: Found
✓ Agent Instructions: Found
✓ AI Tools Guide: Found

Checking Tool-Specific Configs:
✓ Cursor Rules: Found
✓ Aider Config: Found
✓ Cline Rules: Found
✓ Cline Project Brief: Found
✓ Cline Tech Context: Found

Checking Claude Code Integration:
✓ Claude Directory: Found
✓ Claude Settings: Found
✓ Claude Local Settings: Found
✓ Slash Commands: Found
✓ Skills Directory: Found

Checking Hook Scripts:
✓ Context Loader: scripts/hooks/load-context.sh
✓ Command Blocker: scripts/hooks/block-dangerous-commands.sh
✓ Auto Formatter: scripts/hooks/auto-format-nix.sh
✓ Lint Checker: scripts/hooks/strict-lint-check.sh
✓ Final Git Check: scripts/hooks/final-git-check.sh
✓ Context Preserver: scripts/hooks/preserve-nix-context.sh

Testing Hook Script Permissions:
✓ load-context.sh: Executable
✓ block-dangerous-commands.sh: Executable
✓ final-git-check.sh: Executable

Testing Hook Scripts:
✓ load-context.sh: Works
✓ block-dangerous-commands.sh: Works

Checking Formatting Tools:
✓ nix: Available
✓ treefmt: Available

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ All checks passed!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

AI tool configurations are properly set up.

Configured tools:
  • Claude Code - Full integration (hooks, commands, skills)
  • Gemini Code Assist - Context and rules configured
  • Cursor AI - Rules and agent mode ready
  • Aider - YAML configuration complete
  • Cline - Rules and memory bank configured

Next steps:
  1. Start using your preferred AI tool
  2. See AI_TOOLS.md for tool-specific guides
  3. Review CLAUDE.md for general guidelines
```

**When to use**:

- Initial repository setup
- After adding new AI tools
- When hooks aren't working
- After updating AI tool configurations
- Troubleshooting AI assistant behavior

**Validates these AI tools**:

- **Claude Code** - Full integration with hooks, commands, skills
- **Cursor AI** - Rules and agent mode configuration
- **Aider** - YAML configuration
- **Cline** - Rules and memory bank
- **Gemini Code Assist** - Context and rules

---

## Common Workflows

### 1. Before System Rebuild

```bash
# Validate configuration
./scripts/validation/validate-config.sh

# If validation passes
nh os switch

# If validation fails
# Fix issues reported by validator
# Re-run validation
```

### 2. After Configuration Changes

```bash
# Edit configuration
vim hosts/jupiter/default.nix

# Validate changes
./scripts/validation/validate-config.sh

# Check diff
git diff

# Commit if valid
git add .
git commit -m "feat(jupiter): add new service"
```

### 3. Setting Up AI Tools

```bash
# Initial setup
./scripts/validation/ai-tool-setup.sh

# If issues found, fix them
# Example: chmod +x scripts/hooks/*.sh

# Re-validate
./scripts/validation/ai-tool-setup.sh

# Start using AI tools
# All hooks should now work correctly
```

### 4. Troubleshooting AI Tool Issues

```bash
# Check AI tool configuration
./scripts/validation/ai-tool-setup.sh

# If hook scripts fail
ls -la scripts/hooks/  # Check permissions
which nixfmt  # Check dependencies

# Test specific hook
echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | \
  ./scripts/hooks/block-dangerous-commands.sh

# Check Claude Code settings
cat .claude/settings.json
```

---

## Validation in CI/CD

### GitHub Actions Example

```yaml
name: Validate Configuration

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v24
        with:
          nix_path: nixpkgs=channel:nixos-unstable

      - name: Validate Nix configuration
        run: ./scripts/validation/validate-config.sh

      - name: Check formatting
        run: nix fmt --check

      - name: Run linters
        run: |
          nix-shell -p statix --run "statix check ."
          nix-shell -p deadnix --run "deadnix --fail ."
```

### Pre-commit Hook Integration

```bash
# .git/hooks/pre-commit
#!/usr/bin/env bash
set -euo pipefail

echo "Running validation..."
./scripts/validation/validate-config.sh || {
  echo "❌ Configuration validation failed"
  echo "Fix the issues above before committing"
  exit 1
}

echo "✓ Validation passed"
```

---

## Error Examples & Solutions

### Validation Error: Build Failure

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Configuration validation failed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Error: attribute 'invalidOption' missing
  at hosts/jupiter/default.nix:42

The option 'services.invalidOption' does not exist.
```

**Solution**: Remove or fix the invalid option reference.

---

### Validation Error: Syntax Error

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Flake syntax check failed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Error: syntax error, unexpected '}', expecting ';'
  at flake.nix:45:3
```

**Solution**: Fix the syntax error (missing semicolon, extra brace, etc.).

---

### AI Tool Setup Error: Missing Executable

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Testing Hook Script Permissions:
✗ load-context.sh: Not executable

Fix: chmod +x scripts/hooks/load-context.sh
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Solution**: Make scripts executable:

```bash
chmod +x scripts/hooks/*.sh
```

---

### AI Tool Setup Error: Missing Configuration

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Checking Claude Code Integration:
✗ Claude Settings: Missing

Expected: .claude/settings.json
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Solution**: Create missing configuration file or check it's in the correct location.

---

## Best Practices

### Always Validate Before Rebuilding

```bash
# ❌ DON'T
nh os switch  # No validation

# ✅ DO
./scripts/validation/validate-config.sh && nh os switch
```

### Integrate into Git Workflow

```bash
# ❌ DON'T
git commit -m "changes"  # No validation

# ✅ DO
./scripts/validation/validate-config.sh
git add .
git commit -m "changes"  # Pre-commit hook validates automatically
```

### Test in Safe Environment First

```bash
# Build configuration for testing
nix build .#nixosConfigurations.jupiter.config.system.build.toplevel

# Test in VM
nh os test

# Then apply to live system
./scripts/validation/validate-config.sh && nh os switch
```

---

## Dependencies

Required packages:

- `nix` - Nix package manager
- `git` - Version control
- `bash` - Shell interpreter
- `coreutils` - Basic utilities

Optional (for AI tool validation):

- `nixfmt` - Nix formatter
- `treefmt` - Multi-formatter
- `statix` - Nix linter
- `deadnix` - Dead code detection

Install missing dependencies:

```bash
nix-shell -p nix git bash coreutils nixfmt treefmt statix deadnix
```

---

## See Also

- [Hooks Scripts](../hooks/README.md) - Claude Code integration
- [Flake Check](../../docs/CI.md#flake-validation) - CI/CD validation
- [AI Tools Guide](../../AI_TOOLS.md) - Multi-tool AI setup
- [Contributing Guide](../../CONTRIBUTING.md) - Development workflow
