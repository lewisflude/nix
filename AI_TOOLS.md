# AI Coding Tools Configuration Guide

This repository is optimized for multiple AI coding assistants. Each tool has specific configuration files and features to enhance your development experience.

## Supported AI Tools

- **Claude Code** - Full integration with hooks, commands, and skills
- **Gemini Code Assist** - Context files and custom rules
- **Cursor AI** - Rules and agent mode support
- **Aider** - YAML configuration and conventions
- **Cline** - VSCode extension with memory bank support

## Quick Start by Tool

### Claude Code

**Status**: ✅ Fully Configured

Claude Code has the most comprehensive integration:

**Features Enabled:**
- ✅ SessionStart hook - Loads git context automatically
- ✅ PreToolUse hook - Blocks dangerous commands
- ✅ PostToolUse hooks - Auto-formatting and linting
- ✅ Permission system - Granular command controls
- ✅ Custom slash commands - Project-specific workflows
- ✅ Skills - Autonomous Nix expertise
- ✅ Status line - Session awareness

**Configuration Files:**
- `.claude/settings.json` - Main configuration
- `.claude/settings.local.json` - Local overrides
- `.claude/commands/` - Custom slash commands
- `.claude/skills/` - Autonomous AI helpers
- `CLAUDE.md` - Main AI guidelines
- `scripts/` - Hook scripts

**Available Slash Commands:**
```bash
/diagnose              # Run diagnostic scripts
/validate-module       # Check module structure
/format-project        # Format entire project
/nix/check-build       # Validate flake builds
/nix/trace-dep         # Trace dependencies
/nix/update            # Update dependencies
```

**Getting Started:**
```bash
# Claude Code reads configuration automatically
# Just start coding - hooks and commands are active
```

---

### Gemini Code Assist

**Status**: ✅ Configured

**Configuration Files:**
- `GEMINI.md` - Project-level rules and context
- `CONVENTIONS.md` - Shared coding conventions

**Features:**
- Context hierarchy (global → project → module-specific)
- Custom rules in IDE settings
- Repository indexing with `@repo` mentions (Enterprise)

**Setup:**
1. Install Gemini Code Assist extension in your IDE
2. Open this repository
3. Gemini will automatically load `GEMINI.md` context

**Usage:**
```
# In Gemini chat
@repo how do I add a new feature module?
```

**Module-Specific Context:**
You can create additional `GEMINI.md` files in subdirectories for context-aware assistance:
```
modules/nixos/GEMINI.md     # Context for NixOS modules
home/common/GEMINI.md       # Context for home-manager config
```

---

### Cursor AI

**Status**: ✅ Configured

**Configuration Files:**
- `.cursorrules` - Project-specific AI instructions
- `AGENTS.md` - Agent mode instructions
- `CLAUDE.md` - Also read by Cursor CLI
- `.cursor/` - (future) Advanced rules directory

**Features:**
- Project rules (`.cursorrules`)
- Agent mode with multi-file editing
- Terminal command execution
- Notepads for persistent context
- MCP server support (`.cursor/mcp.json`)

**Getting Started:**
1. Open repository in Cursor IDE
2. `.cursorrules` loads automatically
3. Use agent mode (Ctrl/Cmd + Shift + L) for complex tasks

**Agent Mode Usage:**
```
# Enable agent mode for autonomous coding
Ctrl/Cmd + Shift + L

# Agent can:
# - Make multi-file changes
# - Run terminal commands
# - Execute diagnostic scripts
# - Format and validate code
```

**Future Migration:**
Cursor is moving from `.cursorrules` to `.cursor/index.mdc` with Rule Type "Always". The current `.cursorrules` file will continue working for backward compatibility.

---

### Aider AI

**Status**: ✅ Configured

**Configuration Files:**
- `.aider.conf.yml` - Main configuration
- `CONVENTIONS.md` - Coding conventions (auto-loaded)
- `CLAUDE.md` - Additional context
- `docs/DX_GUIDE.md` - Development guidelines

**Features:**
- Auto-formatting with `nix fmt`
- Conventional commit messages
- Multi-file editing
- Git integration
- Custom model settings

**Getting Started:**
```bash
# Install Aider
pip install aider-chat

# Run in repository
cd /path/to/nix-config
aider

# Aider automatically loads .aider.conf.yml
```

**Usage Examples:**
```bash
# Add files to context
aider home/common/apps/git.nix

# Ask Aider to make changes
> Add support for git delta pager

# Aider will:
# - Make the changes
# - Format with nix fmt
# - Create conventional commit
# - Ask for your approval
```

**Advanced Configuration:**
You can override model settings in `.aider.model.settings.yml` if needed.

---

### Cline (VSCode Extension)

**Status**: ✅ Configured

**Configuration Files:**
- `.clinerules` - Simple project rules
- `projectBrief.md` - Memory bank: Project overview
- `techContext.md` - Memory bank: Technical details
- `CONVENTIONS.md` - Coding conventions

**Features:**
- Memory bank for persistent context
- Multi-file editing
- Terminal integration
- Custom instructions
- Tool use capabilities

**Getting Started:**
1. Install Cline extension in VSCode
2. Open this repository
3. Cline loads `.clinerules` and memory bank automatically

**Memory Bank Files:**

The memory bank helps Cline understand your project better:
- `projectBrief.md` - High-level project overview
- `techContext.md` - Technical stack and patterns
- `activeContext.md` - Current work (you can update this)
- `systemPatterns.md` - Recurring patterns and conventions

**Usage:**
```
# In Cline chat
How should I structure a new audio feature module?

# Cline uses memory bank to provide context-aware answers
```

---

## Universal Configuration Files

These files are shared across multiple AI tools:

### CLAUDE.md
Primary AI assistant guidelines - comprehensive documentation including:
- System rebuild warnings
- Repository structure
- Module placement guidelines
- Available tools (POG scripts, shell scripts)
- Best practices
- Common antipatterns

**Used by**: Claude Code, Cursor, Aider

### CONVENTIONS.md
Detailed coding conventions and standards:
- Module organization principles
- Code style requirements
- Git commit conventions
- Common antipatterns
- Testing and validation rules

**Used by**: All tools (Aider, Gemini, Cursor, Cline)

### GEMINI.md
Gemini-specific context and rules:
- Project overview
- Critical rules for module placement
- Code style requirements
- Commands to never run
- Decision checklist

**Used by**: Gemini Code Assist

### AGENTS.md
Instructions for autonomous AI agents:
- Agent workflow guidelines
- Module placement decision tree
- Safety rules
- Available tools and scripts
- Multi-file change best practices

**Used by**: Cursor Agent, autonomous assistants

---

## Common Patterns Across All Tools

### Module Placement Rules

All AI tools follow the same placement rules:

**System-Level** (`modules/nixos/` or `modules/darwin/`):
- System services (systemd, launchd)
- Hardware configuration
- Container runtimes
- Graphics drivers

**Home-Manager** (`home/common/apps/`):
- User applications
- Dotfiles
- Development tools
- Desktop applications

### Code Style

All tools enforce:
- ✅ Explicit package references (no `with pkgs;`)
- ✅ Constants from `lib/constants.nix`
- ✅ Conventional commit messages
- ✅ Auto-formatting with `nix fmt` or `treefmt`

### Safety Rules

All tools must:
- ❌ Never run `nh os switch` or `sudo nixos-rebuild switch`
- ❌ Never use `rm -rf` without explicit permission
- ❌ Never hardcode sensitive values
- ✅ Always ask before dangerous git operations

---

## Choosing the Right Tool

### Use Claude Code for:
- Complex multi-file refactoring
- Learning the codebase with skills
- Automated workflows with slash commands
- Projects with hooks and automation

### Use Gemini Code Assist for:
- Quick inline suggestions
- Repository-wide context (Enterprise)
- Google Cloud integration
- Team collaboration with shared style guides

### Use Cursor for:
- Agent mode for autonomous coding
- Multi-file editing with AI
- Terminal-integrated development
- Fast iteration with Composer

### Use Aider for:
- Terminal-based workflow
- Git-integrated development
- Scripting and automation
- Multiple AI model support

### Use Cline for:
- VSCode-native experience
- Memory bank context management
- Visual file editing
- Integrated terminal workflows

---

## Scripts and Automation

### Diagnostic Scripts (`scripts/`)

All AI tools can use these scripts:

**qBittorrent & VPN:**
```bash
./scripts/diagnose-qbittorrent-seeding.sh
./scripts/verify-qbittorrent-vpn.sh
./scripts/monitor-protonvpn-portforward.sh
```

**SSH & Network:**
```bash
./scripts/diagnose-ssh-slowness.sh
./scripts/test-ssh-performance.sh
./scripts/test-vlan2-speed.sh
```

**Validation:**
```bash
./scripts/validate-config.sh
./scripts/strict-lint-check.sh
```

### POG Scripts (`nix run .#<name>`)

Interactive CLI tools available to all AI assistants:

```bash
nix run .#new-module         # Create new modules
nix run .#update-all         # Update dependencies
nix run .#visualize-modules  # Generate graphs
nix run .#setup-cachix       # Configure cache
```

---

## Setup Script

For initial configuration help, run:

```bash
./scripts/ai-tool-setup.sh
```

This script helps you:
- Verify AI tool configurations
- Test hook scripts
- Validate formatting setup
- Check documentation links

---

## Documentation

### Primary Docs (for all tools)
- `CLAUDE.md` - AI assistant guidelines
- `CONVENTIONS.md` - Coding standards
- `docs/DX_GUIDE.md` - Development guide
- `docs/FEATURES.md` - Feature patterns
- `docs/reference/architecture.md` - Architecture guide

### Tool-Specific Docs
- `GEMINI.md` - Gemini Code Assist rules
- `AGENTS.md` - Agent mode instructions
- `.aider.conf.yml` - Aider configuration
- `.cursorrules` - Cursor project rules
- `.clinerules` - Cline project rules

---

## Contributing

When adding new AI tool configurations:

1. **Create appropriate config files** in repository root
2. **Update this README** with tool-specific instructions
3. **Test the configuration** with the actual tool
4. **Document any limitations** or special requirements
5. **Add examples** of common usage patterns

---

## Troubleshooting

### Claude Code

**Problem**: Hooks not running
**Solution**: Check `.claude/settings.json` and verify script permissions

**Problem**: Slash commands not appearing
**Solution**: Ensure commands are in `.claude/commands/` with `.md` extension

### Gemini Code Assist

**Problem**: Context not loading
**Solution**: Verify `GEMINI.md` exists and IDE recognizes it

### Cursor

**Problem**: Rules not applying
**Solution**: Check `.cursorrules` file exists and restart Cursor

### Aider

**Problem**: Config not loading
**Solution**: Ensure `.aider.conf.yml` is valid YAML, run `aider --check-config`

### Cline

**Problem**: Memory bank not working
**Solution**: Verify `projectBrief.md` and `techContext.md` exist in root

---

## Resources

- **Claude Code**: https://code.claude.com/docs
- **Gemini Code Assist**: https://cloud.google.com/gemini/docs/codeassist
- **Cursor**: https://docs.cursor.com
- **Aider**: https://aider.chat/docs
- **Cline**: https://docs.cline.bot

---

## Updates and Maintenance

This configuration is actively maintained. To get the latest improvements:

```bash
git pull origin main
```

Last updated: 2025-11-22
