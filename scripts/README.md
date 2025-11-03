# Nix Configuration Scripts

This directory contains utility scripts for managing your cross-platform Nix configuration (NixOS + nix-darwin).

## 🚀 Quick Start

**Load convenient aliases:**

```bash
source ~/.config/nix/scripts/ALIASES.sh
```

Add to your `~/.zshrc` to make permanent:

```bash
echo 'source ~/.config/nix/scripts/ALIASES.sh' >> ~/.zshrc
```

## 📂 Directory Structure

```
scripts/
├── ALIASES.sh              # Shell aliases ⭐
├── build/
│   ├── init-project.sh    # Project scaffolding
│   └── nix-monitor.sh     # Cross-platform monitoring ⭐
├── containers/
│   └── test-containers.sh # Container testing
├── mcp/
│   ├── mcp_love2d_docs.py # Love2D MCP server
│   └── mcp_lua_docs.py    # Lua MCP server
├── utils/
│   ├── benchmark-rebuild.sh # Performance benchmarking
│   └── profile-build.sh     # Build profiling (NEW) ⭐
└── visualize-modules.sh    # Module visualization

POG Apps (nix run .#<name>):
├── new-module ⭐           # Create new modules (interactive)
├── setup-cachix           # Configure Cachix caching
└── update-all ⭐           # Update all dependencies

Community Tools (use these):
├── nix-update            # Update package hashes (replaces update-git-hash)
├── nvd                   # View config diffs
└── nh                    # NixOS helper (NixOS only)

⭐ = Most commonly used
```

## 🔧 Common Tasks

### Update Everything

```bash
# Update flake.lock and ZSH plugins (POG app)
nix run .#update-all

# Options
nix run .#update-all -- --dry_run
nix run .#update-all -- --skip_plugins

# Or manually
nix flake update  # Just flake.lock
```

### Build & Switch

```bash
# macOS (nix-darwin)
darwin-rebuild switch --flake ~/.config/nix

# NixOS (with nh)
nh os switch

# Or use aliases
nix-build    # Build only
nix-switch   # Build and activate
nix-test     # Test build
```

### Check Configuration

```bash
# Direct commands (best practice)
nix flake check
nix build .#darwinConfigurations.$(hostname -s).system --dry-run  # macOS
nix build .#nixosConfigurations.$(hostname).config.system.build.toplevel --dry-run  # NixOS

# Or use aliases
nix-build  # Validates during build
```

### View Differences

```bash
# Install nvd first if not available
nix profile install nixpkgs#nvd

# Compare configurations
nvd diff /run/current-system $(darwin-rebuild build --flake ~/.config/nix --print-out-paths | tail -1)

# Or use alias
nix-diff  # Requires nvd
```

### System Monitoring

```bash
# Cross-platform monitoring tool
~/.config/nix/scripts/build/nix-monitor.sh

# Commands:
nix-monitor.sh overview    # System overview (default)
nix-monitor.sh store       # Nix store analysis
nix-monitor.sh performance # Build performance
nix-monitor.sh health      # Configuration health
nix-monitor.sh cleanup     # Interactive cleanup
nix-monitor.sh full        # Complete analysis

# Or use aliases
nix-monitor       # Quick overview
nix-monitor-full  # Complete analysis
```

### Maintenance

```bash
# Garbage collection
nix-collect-garbage -d           # Delete all old generations
nix-collect-garbage --delete-older-than 30d

# Store optimization (deduplication)
nix store optimise

# Clean up duplicate package versions
sudo bash scripts/cleanup-duplicates.sh

# Or use aliases
nix-gc          # Delete all old
nix-gc-old      # Delete > 30 days
nix-optimize    # Deduplicate
```

### Cleanup Duplicate Packages

Remove old/unused package versions to free up space:

```bash
sudo bash scripts/cleanup-duplicates.sh
```

This script will:

- Run garbage collection to remove dead paths
- Identify and remove old versions of packages
- Keep only the latest versions currently in use
- Show estimated space savings before proceeding

**What gets cleaned:**

- Old LibreOffice versions (keeps latest)
- Old Ollama versions (keeps latest)
- Old NVIDIA drivers (keeps current kernel version)
- Old LLVM/Clang versions (keeps latest)
- Old OpenJDK versions (keeps latest)
- Old Iosevka fonts (keeps latest)
- Old Zoom versions (keeps latest)
- Debug packages (cmake debug)
- Old Rust toolchains (if not referenced)

**Expected savings:** ~7-8GB after cleanup

### Module Scaffolding

```bash
# Create new module from template
~/.config/nix/scripts/utils/new-module.sh feature kubernetes
~/.config/nix/scripts/utils/new-module.sh service grafana
```

## 📊 Useful Tools

### `update-all` - Master Update Tool (POG)

Updates all dependencies in one command.

```bash
# Update everything
nix run .#update-all

# Options
nix run .#update-all -- -d              # Dry run (preview changes)
nix run .#update-all -- -f              # Skip flake.lock
nix run .#update-all -- -p              # Skip ZSH plugins
nix run .#update-all -- -k              # Skip custom packages
```

### `nix-update` - Package Updates (Community Tool)

Use instead of custom update-git-hash script.

```bash
# Update any package
nix-update package-name --flake

# With auto-commit
nix-update package-name --flake --commit

# See: WHY_NIX_UPDATE.md for full details
```

### `nix-monitor.sh` - System Monitoring

Cross-platform system and Nix store monitoring.

**Features:**

- System overview (CPU, memory, disk)
- Nix store analysis (size, dead paths)
- Build performance tracking
- Configuration health checks
- Optimization suggestions
- Interactive cleanup

**Platform Support:**

- ✅ macOS (nix-darwin)
- ✅ NixOS

### `benchmark-rebuild.sh` - Performance Tracking

Track rebuild performance over time.

```bash
./scripts/utils/benchmark-rebuild.sh
# Results saved to .benchmark-history/
```

### `visualize-modules.sh` - Dependency Graph

Generate module dependency visualizations.

```bash
./scripts/visualize-modules.sh
# Outputs to docs/generated/
```

## 🗑️ Recently Removed Scripts

The following wrapper scripts were removed in favor of direct commands and aliases:

| Removed Script | Replacement |
|---------------|-------------|
| `fix-file-limits.sh` | Now handled declaratively in `modules/darwin/system.nix` |
| `update-flake.sh` | Use `nix flake update` or `nix-update` alias |
| `check-config.sh` | Use `nix build .#... --dry-run` or `nix-build` alias |
| `diff-config.sh` | Use `nvd diff` directly or `nix-diff` alias |
| `build/dev.sh` | Use direct commands or aliases from `ALIASES.sh` |

**Why removed?**

- Reduced complexity and maintenance burden
- Improved transparency (see actual commands being run)
- Better integration with standard Nix tooling
- Aliases provide same convenience without wrapper layers

## 🔍 Migration Guide

If you were using the old wrapper scripts:

### Before

```bash
./scripts/fix-file-limits.sh
./scripts/maintenance/update-flake.sh
./scripts/maintenance/check-config.sh
./scripts/utils/diff-config.sh
./scripts/build/dev.sh rebuild
```

### After

```bash
# File limits now declarative (already configured)
# Just rebuild to apply

nix flake update
nix build .#darwinConfigurations.$(hostname -s).system --dry-run
nvd diff /run/current-system ./result
darwin-rebuild switch --flake ~/.config/nix

# Or use aliases (source ALIASES.sh first)
nix-update
nix-build
nix-diff
nix-switch
```

## 🎯 Best Practices

1. **Use direct Nix commands** when possible for transparency
2. **Use aliases** for frequently-used command combinations
3. **Avoid wrapper scripts** that just call other commands
4. **Keep configuration declarative** rather than using imperative scripts
5. **Document what scripts do** so they can be replaced with native tools

## 📚 Additional Resources

- [Nix Manual](https://nixos.org/manual/nix/stable/)
- [nix-darwin Manual](https://daiderd.com/nix-darwin/manual/)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [nh - Nix Helper](https://github.com/viperML/nh)
- [nvd - Nix Version Diff](https://gitlab.com/khumba/nvd)

## 🤝 Contributing

When adding new scripts:

1. ✅ **DO** - Scripts that automate complex multi-step processes
2. ✅ **DO** - Scripts specific to your configuration structure
3. ✅ **DO** - Cross-platform compatible scripts
4. ❌ **DON'T** - Simple wrappers around single Nix commands
5. ❌ **DON'T** - Scripts that manage system state imperatively
6. ❌ **DON'T** - Meta-wrappers that just route to other scripts

Always prefer:

- Declarative configuration over imperative scripts
- Direct commands over wrappers
- Aliases over wrapper scripts
- Native tooling over custom tools
