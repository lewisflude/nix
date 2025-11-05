# Conventional Commit Examples

This document provides real-world examples of conventional commits for this Nix configuration repository.

## Basic Examples

### Features

```
feat(nixos): add media management services

Add Radarr, Sonarr, and Prowlarr as containerized services with
automatic configuration and monitoring.
```

```
feat(darwin): add keyboard shortcuts module

Implement macOS keyboard shortcuts using Karabiner-Elements with
support for custom key mappings and vim-style navigation.
```

```
feat(home): add zsh completions for nh

Enable tab completion for nh commands in zsh shell configuration.
```

### Bug Fixes

```
fix(nixos): resolve audio crackling in pipewire

Adjust buffer size and latency settings to fix audio crackling
issues on AMD hardware.

Fixes #234
```

```
fix(darwin): correct homebrew tap configuration

Fix homebrew-j178 tap path that was causing formula installation
failures.
```

```
fix(home): prevent duplicate PATH entries in zsh

Add deduplication logic to shell initialization to avoid PATH
pollution from multiple sourcing.
```

### Documentation

```
docs: update installation instructions for macOS

Add troubleshooting section for common installation issues and
improve formatting of command examples.
```

```
docs(modules): add examples for container configuration

Include real-world examples of configuring containerized services
with custom networks and volumes.
```

### Refactoring

```
refactor(lib): extract common module functions

Create shared utility functions for module configuration to reduce
code duplication across NixOS and Darwin modules.
```

```
refactor(home): reorganize shell configuration

Split monolithic shell.nix into separate files for aliases,
functions, and environment variables for better maintainability.
```

### Chores

```
chore: update flake inputs

Update nixpkgs, home-manager, and darwin to latest versions.
```

```
chore(deps): bump helix to latest version

Update helix editor to v24.07 for improved LSP support.
```

```
chore: clean up unused overlays

Remove deprecated overlays for waybar and swww that are no longer
needed.
```

### Performance

```
perf(nix): enable lazy tree evaluation

Configure Nix to use lazy tree evaluation for faster flake
evaluation times.
```

```
perf(build): add binary cache configuration

Add additional substituters to speed up builds by using pre-built
packages.
```

### CI/CD

```
ci: add workflow for automatic cache generation

Set up GitHub Actions workflow to build and push packages to
Cachix after successful builds.
```

```
ci: parallelize build matrix

Split CI builds by system (x86_64-linux, aarch64-darwin) to
improve build times.
```

### Build System

```
build: add dev shell with debugging tools

Include gdb, valgrind, and strace in development shell for
debugging native applications.
```

```
build(cachix): configure automatic cache pushing

Set up cachix-action to automatically push successful builds to
project cache.
```

### Tests

```
test(nixos): add integration test for containers

Create NixOS test for containerized service deployment and
networking configuration.
```

```
test(home): verify shell configuration loads correctly

Add test to ensure zsh configuration doesn't have syntax errors
and loads all required plugins.
```

### Style

```
style(nix): format all files with nixfmt

Run nixfmt formatter across entire codebase for consistent
formatting.
```

```
style: enforce consistent indentation in YAML

Apply prettier formatting to all YAML configuration files.
```

### Reverts

```
revert: "feat(nixos): add experimental feature"

This reverts commit abc123def456. The feature caused system
instability on AMD systems.

See issue #345 for details.
```

## Complex Examples

### Feature with Breaking Change

```
feat(nixos)!: migrate to pipewire from pulseaudio

BREAKING CHANGE: This removes pulseaudio support entirely.
Users must manually migrate their audio configuration to pipewire.

Migration steps:
1. Remove any pulseaudio-specific configuration
2. Enable services.pipewire instead of pulseaudio
3. Adjust application audio settings if needed

See docs/AUDIO_MIGRATION.md for detailed instructions.
```

### Multiple Scopes

```
feat(nixos,darwin): add cross-platform backup module

Implement unified backup module that works on both NixOS and
Darwin using restic. Supports local, S3, and B2 backends.

Features:
- Automatic scheduling
- Encryption by default
- Per-host configuration
- Notification on failure

Closes #123
```

### With References

```
fix(containers): resolve network isolation issue

Container services were unable to communicate with each other
due to incorrect network configuration. This fix:

- Adds proper bridge network setup
- Configures DNS for inter-container communication
- Updates firewall rules

Fixes #456
Relates to #123
See also: https://github.com/NixOS/nixpkgs/issues/789
```

### Refactoring with Rationale

```
refactor(modules): consolidate feature modules

Merge separate gaming-related modules into single cohesive module
for better maintainability and clearer dependencies.

Before:
- modules/nixos/gaming/steam.nix
- modules/nixos/gaming/lutris.nix
- modules/nixos/gaming/gamemode.nix

After:
- modules/nixos/features/gaming.nix

This reduces duplication and makes it easier to enable all gaming
features at once.
```

## Anti-Patterns (What NOT to Do)

### ❌ Too Vague

```
fix: stuff

Fixed some things.
```

**Better:**

```
fix(nixos): resolve boot failure on AMD systems

Add required kernel modules for AMD graphics cards to initrd.

Fixes #234
```

### ❌ Non-Conventional Format

```
Fixed the audio issue with PipeWire
```

**Better:**

```
fix(nixos): resolve audio crackling in pipewire

Adjust buffer size settings to fix audio crackling on AMD hardware.
```

### ❌ Too Many Changes in One Commit

```
feat: add 20 new features and fix 15 bugs

- Added media management
- Fixed audio
- Updated documentation
- Refactored modules
- [... 30 more items]
```

**Better:** Split into multiple focused commits.

### ❌ Missing Context

```
feat: add thing
```

**Better:**

```
feat(darwin): add keyboard shortcuts module

Implement macOS keyboard shortcuts using Karabiner-Elements for
improved window management and vim-style navigation.
```

### ❌ Not Imperative Mood

```
fix: fixed the bug
```

**Better:**

```
fix: resolve memory leak in service
```

## Scope Guidelines

Common scopes for this repository:

- `nixos` - NixOS-specific changes
- `darwin` - macOS/Darwin-specific changes
- `home` - Home-manager configuration
- `modules` - Module system changes
- `lib` - Library functions
- `shells` - Development shells
- `ci` - CI/CD configuration
- `docs` - Documentation
- `deps` - Dependencies
- `containers` - Container/virtualization
- `services` - System services

## Tips

1. **Keep the subject line under 50 characters**
2. **Wrap the body at 72 characters**
3. **Use the imperative mood** ("add" not "added")
4. **Explain *why* not *what*** (the diff shows what)
5. **Reference issues and PRs** when relevant
6. **One logical change per commit**
7. **Use breaking change marker** when appropriate

## Resources

- [Conventional Commits Spec](https://www.conventionalcommits.org/)
- [How to Write a Git Commit Message](https://chris.beams.io/posts/git-commit/)
- [Angular Commit Guidelines](https://github.com/angular/angular/blob/master/CONTRIBUTING.md#commit)
