# AI Assistant Guidelines

This document provides guidelines for AI assistants working with this Nix configuration repository.

## System Rebuilds

**CRITICAL**: Never rebuild NixOS or nix-darwin systems directly. Always ask the user to build instead, as you do not have permissions to run commands like:

- `nh os switch`
- `sudo nixos-rebuild switch`
- `sudo darwin-rebuild switch`

Instead, suggest commands for the user to run manually.

## Repository Structure

This is a cross-platform Nix configuration supporting:

- **NixOS** (Linux) - hosts defined in `hosts/`
- **nix-darwin** (macOS) - hosts defined in `hosts/`
- **Home Manager** - user configuration in `home/`
- **Modules** - system-level modules in `modules/`
- **POG Scripts** - CLI tools in `pkgs/pog-scripts/` (run with `nix run .#<name>`)
- **Shell Scripts** - utility scripts in `scripts/`

## Available Tools

### POG Apps (Interactive CLI Tools)

These are modern CLI tools built with pog library:

- `nix run .#new-module` - Create new modules interactively
- `nix run .#update-all` - Update all dependencies
- `nix run .#cleanup-duplicates` - Remove old package versions
- `nix run .#analyze-services` - Analyze service usage
- `nix run .#visualize-modules` - Generate module dependency graphs
- `nix run .#setup-cachix` - Configure Cachix binary cache

### Shell Scripts

Located in `scripts/`:

- `scripts/utils/profile-build.sh` - Build profiling
- `scripts/utils/profile-evaluation.sh` - Evaluation profiling
- `scripts/utils/profile-modules.sh` - Module profiling
- `scripts/utils/test-caches.sh` - Test cache connectivity
- `scripts/utils/test-cache-substitution.sh` - Test cache substitution
- `scripts/build/nix-monitor.sh` - System monitoring

## Best Practices

1. **Always check existing patterns** before suggesting new code
2. **Use templates** when creating modules: `nix run .#new-module`
3. **Follow conventional commits** - see `docs/DX_GUIDE.md`
4. **Format code** using `nix fmt` or `treefmt`
5. **Check for existing modules** before creating new ones
6. **Document changes** in relevant documentation files

## Common Tasks

### Adding a Package

- Check if it exists in `home/common/apps/` or `modules/nixos/features/`
- Use feature-based configuration when appropriate
- See `docs/FEATURES.md` for feature patterns

### Creating a Module

- Use `nix run .#new-module` for scaffolding
- Follow naming conventions in `docs/reference/architecture.md`
- Add documentation to module options

### Updating Dependencies

- Use `nix run .#update-all` to update everything
- Or manually: `nix flake update`

## Documentation

- **Architecture**: `docs/reference/architecture.md`
- **Features**: `docs/FEATURES.md`
- **DX Guide**: `docs/DX_GUIDE.md`
- **Contributing**: `CONTRIBUTING.md`

## Important Notes

- Never run system rebuild commands
- Always suggest commands for the user to run
- Check documentation before suggesting solutions
- Use existing patterns and conventions
- Format code before suggesting changes
