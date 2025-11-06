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
│   └── nix-monitor.sh     # Cross-platform monitoring ⭐
├── containers/
│   └── test-containers.sh # Container testing
└── utils/
    ├── analyze-build-time.sh # Build time analysis
    ├── benchmark-rebuild.sh  # Performance benchmarking
    ├── monitor-cache-hits.sh # Cache hit monitoring
    ├── nix-with-github-token.sh # Nix commands with GitHub token
    ├── profile-build.sh      # Build profiling ⭐
    ├── profile-evaluation.sh # Evaluation profiling
    ├── profile-modules.sh    # Module profiling
    ├── test-cache-substitution.sh # Test cache substitution
    └── test-caches.sh        # Test cache connectivity

POG Apps (nix run .#<name>):
├── new-module ⭐           # Create new modules (interactive)
├── setup-cachix           # Configure Cachix caching
├── update-all ⭐           # Update all dependencies
├── cleanup-duplicates ⭐   # Remove old package versions
├── analyze-services       # Analyze service usage
└── visualize-modules      # Generate module dependency graphs

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
sudo nix run .#cleanup-duplicates

# Or use aliases
nix-gc          # Delete all old
nix-gc-old      # Delete > 30 days
nix-optimize    # Deduplicate
```

### Cleanup Duplicate Packages

Remove old/unused package versions to free up space:

```bash
# Use the pog-powered version (recommended)
sudo nix run .#cleanup-duplicates

# With flags
sudo nix run .#cleanup-duplicates -- --dry-run    # Preview changes
sudo nix run .#cleanup-duplicates -- --non-interactive  # Auto-confirm
```

This tool will:

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
# Use the pog-powered version (recommended)
nix run .#new-module -- --type feature --name kubernetes
nix run .#new-module -- --type service --name grafana

# Interactive mode (prompts for missing args)
nix run .#new-module
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

### `visualize-modules` - Dependency Graph (POG)

Generate module dependency visualizations.

```bash
# Use the pog-powered version (recommended)
nix run .#visualize-modules

# With options
nix run .#visualize-modules -- --format svg --output_dir docs/generated
# Options: --format (svg|png|dot|all), --output_dir <path>
```

The old bash script has been removed. Use the POG version: `nix run .#visualize-modules`.

### Cache Testing Utilities

Test binary cache connectivity and substitution:

```bash
# Test cache connectivity (HTTP checks)
./scripts/utils/test-caches.sh

# Test actual cache substitution with real packages
./scripts/utils/test-cache-substitution.sh [package-name]
# Default package: hello
```

These scripts help diagnose cache issues and verify substituter configuration.

## 🗑️ Recently Removed/Migrated Scripts

### Migrated to POG Apps

The following scripts have been migrated to pog-powered CLI tools with better UX:

| Old Script | New POG App | Usage |
|-----------|-------------|-------|
| `setup-cachix-local.sh` | `setup-cachix` | `nix run .#setup-cachix` |
| `cleanup-duplicates.sh` ✅ | `cleanup-duplicates` | `nix run .#cleanup-duplicates` |
| `analyze-services.sh` ✅ | `analyze-services` | `nix run .#analyze-services` |
| `visualize-modules.sh` ✅ | `visualize-modules` | `nix run .#visualize-modules` |
| `update-flake.sh` ✅ | `update-all` | `nix run .#update-all` |

✅ = Old script removed, use POG version

**Benefits of pog migration:**

- ✅ Auto-generated help text (`--help`)
- ✅ Tab completion for flags
- ✅ Interactive prompts for missing required flags
- ✅ Consistent interface across all tools
- ✅ Better error messages and validation
- ✅ Built-in verbose mode (`-v`)

### Removed Scripts

The following wrapper scripts were removed in favor of direct commands and aliases:

| Removed Script | Replacement |
|---------------|-------------|
| `fix-file-limits.sh` | Now handled declaratively in `modules/darwin/system.nix` |
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
nix run .#update-all  # Replaces update-flake.sh
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
