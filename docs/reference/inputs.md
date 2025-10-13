# Flake Input Management

Complete guide to managing flake inputs in this configuration.

## Table of Contents

- [Overview](#overview)
- [Input Categories](#input-categories)
- [Update Policy](#update-policy)
- [Using Stable vs Unstable](#using-stable-vs-unstable)
- [Adding New Inputs](#adding-new-inputs)
- [Removing Inputs](#removing-inputs)

---

## Overview

This configuration uses **21 flake inputs** organized by purpose and platform. All inputs use `inputs.nixpkgs.follows = "nixpkgs"` to ensure consistent package versions across the entire system.

### Key Decisions

- **Stable by Default**: Core system uses `nixpkgs` (24.11 stable) for reliability
- **Unstable Available**: `nixpkgs-unstable` accessible via `pkgs.unstable.*` 
- **Matched Versions**: Home Manager tracks the same nixpkgs version
- **Bleeding Edge Desktop**: Window managers and desktop apps use latest commits

---

## Input Categories

### Core Infrastructure

Essential inputs that form the foundation of the configuration.

| Input | URL | Version | Purpose |
|-------|-----|---------|---------|
| `nixpkgs` | `nixos-24.11` | Stable | Primary package source |
| `nixpkgs-unstable` | `nixpkgs-unstable` | Rolling | Latest packages via overlay |
| `darwin` | `nix-darwin/master` | Latest | macOS system framework |
| `home-manager` | `release-24.11` | Stable | User environment management |
| `determinate` | FlakeHub | Latest | Enhanced Nix features |

**Update Frequency**: Monthly after testing  
**Breaking Changes**: Review changelogs before updating

### System Management

| Input | Platform | Purpose |
|-------|----------|---------|
| `sops-nix` | Both | Secrets management with age encryption |

**Update Frequency**: As needed for security patches

### macOS Specific

Only loaded and used on Darwin systems.

| Input | Purpose |
|-------|---------|
| `mac-app-util` | Proper macOS app integration |
| `nix-homebrew` | Declarative Homebrew management |
| `homebrew-j178` | Custom brew tap (non-flake) |

**Update Frequency**: Monthly or when brew formula updates needed

### NixOS Desktop

Window managers, bars, and desktop utilities for Linux.

| Input | Purpose | Why Latest? |
|-------|---------|-------------|
| `niri` | Scrollable-tiling Wayland compositor | Active development, new features |
| `waybar` | Wayland status bar | Frequent updates, bug fixes |
| `swww` | Animated wallpaper daemon | Performance improvements |

**Update Frequency**: Weekly or on feature releases

### NixOS Hardware & Audio

| Input | Purpose |
|-------|---------|
| `nixos-hardware` | Hardware-specific configurations |
| `musnix` | Real-time audio optimization |
| `solaar` | Logitech device manager |
| `nvidia-patch` | NVIDIA driver unlocking (conditional) |

**Update Frequency**: As needed for hardware changes

### Cross-Platform Applications

| Input | Platforms | Purpose |
|-------|-----------|---------|
| `catppuccin` | Both | Soothing pastel theme |
| `yazi` | Both | Blazing fast file manager |
| `ghostty` | macOS | GPU-accelerated terminal |

**Update Frequency**: On releases

### Development Tools

| Input | Purpose |
|-------|---------|
| `nur` | Nix User Repository (community packages) |
| `nh` | Better Nix CLI helper |
| `pre-commit-hooks` | Code quality automation |

**Update Frequency**: Monthly

---

## Update Policy

### Recommended Schedule

```bash
# Stable inputs (monthly)
nix flake lock --update-input nixpkgs
nix flake lock --update-input home-manager

# Unstable (weekly or as needed)
nix flake lock --update-input nixpkgs-unstable

# Desktop apps (on releases)
nix flake lock --update-input niri
nix flake lock --update-input waybar

# All inputs (quarterly full update)
nix flake update

# After any update, test before deploying
nix flake check
```

### Update Process

1. **Update flake.lock**:
   ```bash
   nix flake update
   ```

2. **Test configuration**:
   ```bash
   # macOS
   darwin-rebuild build --flake .#Lewiss-MacBook-Pro
   
   # NixOS
   nixos-rebuild build --flake .#jupiter
   ```

3. **Review changes**:
   ```bash
   nix flake lock --update-input nixpkgs
   git diff flake.lock
   ```

4. **Apply if successful**:
   ```bash
   # macOS
   darwin-rebuild switch --flake .#Lewiss-MacBook-Pro
   
   # NixOS
   sudo nixos-rebuild switch --flake .#jupiter
   ```

5. **Commit**:
   ```bash
   git add flake.lock
   git commit -m "chore: update flake inputs"
   ```

### Rollback on Issues

```bash
# Revert flake.lock
git checkout HEAD~1 flake.lock

# Or use previous generation
darwin-rebuild --rollback  # macOS
nixos-rebuild --rollback   # NixOS
```

---

## Using Stable vs Unstable

### Default (Stable)

Most packages come from stable nixpkgs:

```nix
{pkgs, ...}: {
  home.packages = with pkgs; [
    ripgrep  # From nixos-24.11
    fd       # From nixos-24.11
  ];
}
```

### Unstable Packages

Use `pkgs.unstable` for bleeding-edge packages:

```nix
{pkgs, ...}: {
  home.packages = with pkgs; [
    ripgrep          # Stable version
    unstable.helix   # Latest helix editor from unstable
    unstable.zed     # Newest features
  ];
}
```

### When to Use Unstable

- ✅ Development tools where you need latest features
- ✅ CLI tools with frequent updates
- ✅ Editors and IDEs
- ❌ System libraries (use stable)
- ❌ Core utilities (use stable)
- ❌ Production services (use stable)

---

## Adding New Inputs

### 1. Add to flake.nix

Place in appropriate category with comment:

```nix
inputs = {
  # ... existing inputs ...
  
  # === Your Category ===
  # Short description of what it does
  new-input = {
    url = "github:owner/repo";
    inputs.nixpkgs.follows = "nixpkgs";  # Important!
  };
};
```

### 2. Update outputs

If the input provides overlays or modules:

```nix
# overlays/default.nix
[
  # ... existing overlays ...
  inputs.new-input.overlays.default
]

# lib/system-builders.nix (if module)
modules = [
  # ... existing modules ...
  inputs.new-input.nixosModules.default
];
```

### 3. Document

Add to this file and `docs/reference/input-audit.md`.

### 4. Test

```bash
nix flake show
nix flake check
```

---

## Removing Inputs

### 1. Audit Usage

```bash
# Find all references
rg "inputs\.your-input" --type nix

# Or use grep
grep -r "inputs.your-input" . --include="*.nix"
```

### 2. Remove References

Remove from:
- `flake.nix` inputs
- `overlays/default.nix` if overlay
- `lib/system-builders.nix` if module
- Any other files found in audit

### 3. Clean Up

```bash
# Remove from lock file
nix flake lock

# Test
nix flake check
```

---

## Troubleshooting

### Hash Mismatches

If you see `hash mismatch` errors:

```bash
# Clear the input cache
nix flake lock --update-input problem-input

# Or clear all
rm flake.lock && nix flake lock
```

### Evaluation Errors

```bash
# Check what changed
nix flake metadata

# Evaluate without building
nix eval .#nixosConfigurations.jupiter.config.system.build.toplevel --show-trace
```

### Rollback Individual Input

```bash
# Copy hash from old flake.lock
git show HEAD~1:flake.lock | grep "your-input" -A 10

# Manually edit flake.lock or:
nix flake lock --override-input your-input github:owner/repo/OLD_COMMIT
```

---

## Input Dependency Graph

```
nixpkgs (24.11 stable) ← Almost everything follows this
├── home-manager (release-24.11)
├── niri
├── waybar
├── sops-nix
├── catppuccin
└── ... (most inputs)

nixpkgs-unstable ← Available via pkgs.unstable overlay
└── Used selectively for latest packages

darwin ← Follows nixpkgs
├── mac-app-util
└── nix-homebrew

Independent (don't follow nixpkgs):
├── nixos-hardware
├── determinate
└── homebrew-j178 (non-flake)
```

---

## Best Practices

1. **Always use `inputs.nixpkgs.follows`** to avoid multiple nixpkgs copies
2. **Test updates in a VM or separate generation** before main system
3. **Update one category at a time** to isolate issues
4. **Read changelogs** for breaking changes (especially nixpkgs major versions)
5. **Keep flake.lock in git** for reproducibility
6. **Comment your inputs** so others know why they exist
7. **Review `git diff flake.lock`** before committing updates

---

## Related Documentation

- [Input Audit Report](./input-audit.md) - Detailed usage analysis
- [Architecture Improvements](../ARCHITECTURE-IMPROVEMENTS.md) - Historical context
- [Contributing Guide](../../CONTRIBUTING.md) - How to propose input changes

---

**Last Updated**: 2025-10-13  
**Next Review**: 2026-01-13 (Quarterly)
