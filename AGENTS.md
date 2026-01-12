# AI Agent Instructions

This file provides specialized instructions for AI coding agents (Cursor Agent, autonomous AI assistants, etc.) working with this Nix configuration repository.

## Agent Mode Capabilities

When operating in agent mode, you have access to:

- Multi-file editing capabilities
- Terminal command execution
- Code exploration and analysis
- Automated testing and validation

## Primary Objectives

As an AI agent working in this repository, your goals are:

1. **Maintain architectural integrity** - Follow module placement guidelines strictly
2. **Preserve code quality** - Adhere to coding conventions and formatting
3. **Ensure safety** - Never run system rebuild commands without explicit permission
4. **Provide context** - Always explain changes and reasoning

## Agent Workflow

### For Feature Implementation

1. **Analyze Request**
   - Understand the feature requirements
   - Determine if it's system-level or user-level
   - Check for existing similar implementations

2. **Plan Implementation**
   - Identify affected modules
   - List required changes
   - Consider cross-platform compatibility (NixOS vs nix-darwin)

3. **Execute Changes**
   - Use `nix run .#new-module` for scaffolding new modules
   - Follow patterns from existing modules
   - Update documentation as needed

4. **Validate**
   - Format code: `nix fmt` or `treefmt`
   - Run flake check: `nix flake check`
   - Test builds (suggest to user, don't run)

5. **Document**
   - Update relevant docs in `docs/`
   - Add comments to complex logic
   - Update CLAUDE.md if behavior changes

### For Bug Fixes

1. **Diagnose**
   - Use diagnostic scripts from `scripts/`
   - Check logs and error messages
   - Identify root cause

2. **Fix**
   - Make minimal, targeted changes
   - Follow existing code patterns
   - Avoid over-engineering

3. **Test**
   - Validate fix doesn't break other features
   - Run relevant diagnostic scripts
   - Suggest manual testing steps

### For Refactoring

1. **Assess**
   - Review `docs/reference/REFACTORING_EXAMPLES.md` for antipatterns
   - Ensure refactoring adds real value
   - Avoid premature optimization

2. **Refactor**
   - Make changes incrementally
   - Maintain backward compatibility when possible
   - Document breaking changes clearly

## Module Placement Decision Tree

```
Is this configuration needed?
│
├─ Does it require root privileges?
│  └─ YES → System module (modules/nixos/ or modules/darwin/)
│
├─ Is it a system service (systemd/launchd)?
│  └─ YES → System module (modules/nixos/services/)
│
├─ Is it hardware configuration?
│  └─ YES → System module (modules/nixos/hardware/)
│
├─ Is it a container runtime daemon?
│  └─ YES → System module (modules/nixos/features/virtualisation.nix)
│
├─ Is it a user application or CLI tool?
│  └─ YES → Home-Manager (home/common/apps/)
│
├─ Is it dotfile or shell configuration?
│  └─ YES → Home-Manager (home/common/apps/)
│
└─ Is it a development tool (LSP, formatter)?
   └─ YES → Home-Manager (home/common/apps/)
```

## Critical Safety Rules

### Commands to NEVER Execute

**Absolute prohibitions** (will break user's system if run without permission):

- `nh os switch`
- `nh os boot`
- `sudo nixos-rebuild switch`
- `sudo nixos-rebuild boot`
- `sudo darwin-rebuild switch`
- `darwin-rebuild activate`
- `rm -rf` (especially in system directories)
- `sudo rm -rf`

### Commands to Suggest (Not Execute)

When changes are complete, suggest commands like:

```bash
# Review changes first
git diff

# Test the build (VM or target system)
nh os test  # or user's preferred method

# If tests pass, ask user to run:
nh os switch  # User runs this manually
```

### Dangerous Git Operations (Ask First)

- `git push --force`
- `git push -f`
- `git reset --hard`
- `git clean -fd`

## Available Tools and Scripts

### POG Scripts (Interactive CLI)

Run with `nix run .#<name>`:

- **`new-module`** - Scaffold new modules with proper structure
- **`update-all`** - Update flake inputs and ZSH plugins
- **`visualize-modules`** - Generate dependency graphs (useful for understanding architecture)
- **`setup-cachix`** - Configure binary cache

Use these instead of creating modules manually - they ensure correct structure.

### Diagnostic Scripts

Located in `scripts/`:

**qBittorrent & VPN:**

- `diagnose-qbittorrent-seeding.sh` - Full seeding diagnostics
- `test-qbittorrent-connectivity.sh` - Network tests
- `verify-qbittorrent-vpn.sh` - VPN verification
- `monitor-protonvpn-portforward.sh` - Port forwarding status

**SSH & Network:**

- `diagnose-ssh-slowness.sh` - SSH troubleshooting
- `test-ssh-performance.sh` - Performance benchmarking
- `test-vlan2-speed.sh` - Network speed testing

**Validation:**

- `validate-config.sh` - Flake validation
- `strict-lint-check.sh` - Linting validation

### Code Formatting

Always format after editing `.nix` files:

```bash
# Single file
nix fmt path/to/file.nix

# Entire project
treefmt
```

## Code Style Enforcement

### Antipatterns - Detect and Fix

1. **`with pkgs;` usage**

   ```nix
   # If you see this:
   home.packages = with pkgs; [ package1 package2 ];

   # Change to:
   home.packages = [ pkgs.package1 pkgs.package2 ];
   ```

2. **Hardcoded values**

   ```nix
   # If you see this:
   services.app.port = 8080;

   # Change to:
   let
     constants = import ../lib/constants.nix;
   in
   {
     services.app.port = constants.ports.services.app;
   }
   ```

3. **Wrong module placement**
   - System packages in home-manager → Move to system modules
   - User apps in system config → Move to home-manager
   - Container runtimes in home → Move to system virtualisation

## Documentation Standards

### When Adding Features

1. **Module Documentation**

   ```nix
   options.features.myFeature = {
     enable = lib.mkEnableOption "my feature";

     someOption = lib.mkOption {
       type = lib.types.str;
       default = "value";
       description = "Clear description of what this does";
     };
   };
   ```

2. **Update Docs**
   - Add to `docs/FEATURES.md` if it's a feature flag
   - Update `docs/reference/architecture.md` if structure changes
   - Add guides to `docs/` for complex features

3. **Comment Complex Logic**

   ```nix
   # Use PipeWire low-latency settings for pro audio
   # This reduces buffer size to 64 frames at 48kHz
   services.pipewire.extraConfig = {
     # ...
   };
   ```

## Agent-Specific Best Practices

### Context Gathering

Before making changes:

1. **Read existing modules** in the same category
2. **Check documentation** in `docs/`
3. **Review git history** to understand evolution
4. **Use grep/search** to find similar patterns

### Multi-File Changes

When changes span multiple files:

1. **Plan the full changeset** before editing
2. **Make changes atomically** (all related changes together)
3. **Maintain consistency** across all files
4. **Test interactions** between changed modules

### Communication

When presenting changes:

1. **Explain the reasoning** behind decisions
2. **Highlight trade-offs** if any exist
3. **Document assumptions** you made
4. **Suggest testing steps** for validation

## Error Recovery

If you encounter errors:

1. **Read error messages carefully** - Nix errors are usually precise
2. **Check syntax** - Run `nix flake check`
3. **Verify imports** - Ensure all paths are correct
4. **Review recent changes** - Use `git diff`
5. **Consult docs** - Check `docs/` for guidance

## Integration with CI/CD

This repository may have automated checks:

1. **Formatting validation** - All `.nix` files must be formatted
2. **Lint checks** - No critical linting errors allowed
3. **Build validation** - Flake must build successfully

Ensure your changes pass these checks before suggesting commits.

## Resources

- **Architecture**: `docs/reference/architecture.md`
- **Features**: `docs/FEATURES.md`
- **DX Guide**: `docs/DX_GUIDE.md`
- **TODO**: `docs/TODO.md` - Future refactoring tasks and improvements
- **Coding Conventions**: `CONVENTIONS.md`
- **AI Guidelines**: `CLAUDE.md`
- **Gemini Rules**: `GEMINI.md`

## Agent Mode Tips

1. **Use available tools** - Don't recreate functionality that exists in POG scripts
2. **Follow existing patterns** - The codebase has established conventions
3. **Ask when uncertain** - Better to clarify than make wrong assumptions
4. **Test thoroughly** - Suggest comprehensive testing before deployment
5. **Document everything** - Future you (or other agents) will thank you

## Collaboration with Humans

Remember:

- You are an **assistant**, not a replacement for human judgment
- Always **explain your reasoning** clearly
- **Suggest, don't dictate** - present options when multiple approaches exist
- **Learn from feedback** - If corrected, understand why
- **Stay humble** - Acknowledge limitations and ask for help when needed
