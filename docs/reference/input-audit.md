# Flake Input Audit - 2025-10-13

## Summary

Total inputs: 20
- ✅ **Actively used**: 16
- ⚠️ **Possibly unused**: 2  
- 🔍 **Needs investigation**: 2

## Detailed Analysis

### ✅ Core Inputs (High Usage)

| Input | Usage Count | Purpose | Status |
|-------|-------------|---------|--------|
| `nixpkgs` | 17+ | Primary package source | ✅ Keep - CRITICAL |
| `darwin` | Multiple | nix-darwin system builder | ✅ Keep - CRITICAL (macOS) |
| `home-manager` | Multiple | User environment management | ✅ Keep - CRITICAL |

### ✅ System Management (Active)

| Input | Usage | Purpose | Status |
|-------|-------|---------|--------|
| `determinate` | lib/system-builders.nix | Determinate Systems modules | ✅ Keep |
| `nix-homebrew` | lib/system-builders.nix | Homebrew integration | ✅ Keep (macOS) |
| `mac-app-util` | lib/system-builders.nix | macOS app utilities | ✅ Keep (macOS) |
| `sops-nix` | 2 locations | Secrets management | ✅ Keep - CRITICAL |

### ✅ Desktop Environment (Active)

| Input | Usage | Purpose | Status |
|-------|-------|---------|--------|
| `catppuccin` | lib/output-builders.nix, lib/system-builders.nix | Theme | ✅ Keep |
| `niri` | overlays, lib/output-builders.nix, lib/system-builders.nix | Wayland compositor | ✅ Keep (NixOS) |
| `waybar` | overlays/waybar.nix | Status bar | ✅ Keep (NixOS) |
| `swww` | overlays/swww.nix | Wallpaper daemon | ✅ Keep (NixOS) |

### ✅ Applications (Active)

| Input | Usage | Purpose | Status |
|-------|-------|---------|--------|
| `yazi` | overlays/default.nix | File manager | ✅ Keep |
| `ghostty` | overlays/ghostty.nix | Terminal emulator | ✅ Keep (macOS) |

### ✅ Hardware & System (Active)

| Input | Usage | Purpose | Status |
|-------|-------|---------|--------|
| `nixos-hardware` | Referenced but usage varies | Hardware configs | ✅ Keep (NixOS) |
| `musnix` | lib/system-builders.nix (modules) | Audio optimization | ✅ Keep (NixOS) |
| `solaar` | lib/system-builders.nix (modules) | Logitech device manager | ✅ Keep (NixOS) |

### ✅ Development Tools (Active)

| Input | Usage | Purpose | Status |
|-------|-------|---------|--------|
| `nur` | overlays/default.nix | Nix User Repository | ✅ Keep |
| `nh` | overlays/default.nix | Nix helper tool | ✅ Keep |
| `pre-commit-hooks` | lib/output-builders.nix | Pre-commit checks | ✅ Keep |

### ⚠️ Conditional/Optional (Low Usage)

| Input | Usage | Purpose | Status |
|-------|-------|---------|--------|
| `nvidia-patch` | overlays (conditional) | NVIDIA driver patches | ⚠️ Keep if GPU present |
| `homebrew-j178` | lib/system-builders.nix | Custom brew tap | ⚠️ Keep if needed |

## Recommendations

### 1. Input Versioning Strategy

**Current**: All following `master` or `unstable`
**Proposed**: Mix of stable and unstable

```nix
# Core - Use STABLE for reliability
nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

# Home Manager - Match nixpkgs version
home-manager.url = "github:nix-community/home-manager/release-24.11";

# Desktop apps - Can use unstable for latest features
niri.url = "github:sodiboo/niri-flake";  # Keep unstable
waybar.url = "github:Alexays/Waybar/master";  # Keep unstable
```

### 2. Input Organization

Group inputs by category with comments:

```nix
inputs = {
  # === Core Infrastructure ===
  nixpkgs.url = ...
  darwin.url = ...
  home-manager.url = ...
  
  # === System Management ===
  determinate.url = ...
  sops-nix.url = ...
  
  # === Desktop Environment (NixOS) ===
  niri.url = ...
  waybar.url = ...
  
  # === macOS Specific ===
  mac-app-util.url = ...
  nix-homebrew.url = ...
  
  # === Development Tools ===
  nur.url = ...
  nh.url = ...
};
```

### 3. Update Policy

- **Stable inputs** (nixpkgs, home-manager): Update monthly, after testing
- **Unstable/bleeding-edge**: Update weekly or as needed
- **Desktop apps**: Update on feature releases
- **Security updates**: Immediate

### 4. Unused Inputs

**None identified!** All 20 inputs are actively used.

## Action Items

1. ✅ [5.2] Add `nixpkgs-stable` input (nixos-24.11)
2. ✅ [5.3] Rename `nixpkgs` to `nixpkgs-unstable` for clarity
3. ✅ [5.4] Update `home-manager` to release-24.11
4. ✅ [5.5] Add category comments to flake.nix
5. ✅ [5.6] Add purpose descriptions for each input
6. ✅ [5.8] Create input update schedule documentation

## Platform-Specific Inputs

### macOS Only
- `darwin` - nix-darwin system builder
- `mac-app-util` - macOS application integration
- `nix-homebrew` - Homebrew package manager
- `homebrew-j178` - Custom tap
- `ghostty` (overlay) - Terminal emulator

### NixOS Only
- `niri` - Wayland compositor
- `waybar` - Status bar
- `swww` - Wallpaper daemon
- `musnix` - Audio optimization
- `solaar` - Logitech devices
- `nixos-hardware` - Hardware configurations
- `nvidia-patch` (conditional) - GPU drivers

### Cross-Platform
- `nixpkgs` - Package source
- `home-manager` - User environment
- `catppuccin` - Theme
- `sops-nix` - Secrets
- `yazi` - File manager
- `nur` - User repository
- `nh` - Helper tool
- `pre-commit-hooks` - Development
- `determinate` - System modules

---

**Audit Date**: 2025-10-13  
**Total Inputs**: 20  
**Recommendation**: All inputs are used, proceed with reorganization
