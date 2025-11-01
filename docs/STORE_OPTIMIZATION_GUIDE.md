# Comprehensive Nix Store Optimization Guide

**Current Store Size:** 35.4GB
**Target:** 25-30GB (realistic goal)

## Executive Summary

After research and analysis, 35.4GB is reasonable for your setup, but we can reduce it by **5-10GB** through:

1. Removing duplicate/old package versions
2. Moving dev tools to devShells
3. Optimizing font installations
4. More aggressive cleanup strategies
5. Removing unused optional packages

---

## Problem Areas Identified

### 1. **Multiple Font Versions** (~1.6GB)

- **Issue:** 6 versions of Iosevka fonts installed
- **Current:** `iosevka-33.3.1`, `33.3.2`, `33.3.3`, `33.2.5`, `33.2.6` + nerd-fonts variant
- **Fix:** Pin to single version, remove old versions
- **Savings:** ~1GB

### 2. **Development Tools in Global Scope** (~2-3GB)

- **Issue:** Development tools installed globally instead of devShells
- **Current:** `cmake`, `gnumake`, `pkg-config`, `openssl`, `libsecret`, `libiconv` installed globally
- **Fix:** Move to devShells, keep only essentials globally
- **Savings:** ~1-2GB

### 3. **Multiple Rust/LLVM Versions** (~3GB)

- **Issue:** Multiple rustc versions (1.78, 1.88, 1.89) and LLVM versions (6 different)
- **Fix:** Use `rustup` exclusively, remove global rustc installations
- **Savings:** ~1-1.5GB

### 4. **LibreOffice Duplication** (~1.3GB)

- **Issue:** LibreOffice installed in both system and home-manager
- **Current:** `libreoffice-25.2.6.2` (695MB + 359MB) + `libreoffice-24.8.7.2` (659MB)
- **Fix:** Install in one location only (prefer home-manager)
- **Savings:** ~1.3GB

### 5. **Old Package Versions** (~2-3GB)

- **Issue:** Old versions of packages still in store
- **Examples:** Zoom (3 versions), OpenJDK (2 versions), Ollama (2 versions)
- **Fix:** Aggressive GC + cleanup script
- **Savings:** ~1-2GB

### 6. **Debug Packages** (~750MB)

- **Issue:** Debug packages installed but not needed
- **Fix:** Remove debug packages from global installs
- **Savings:** ~500MB-750MB

### 7. **Font Packages** (~1.6GB total)

- **Issue:** Multiple font packages installed
- **Current:** Nerd Fonts (501MB) + multiple Iosevka versions (~1.1GB)
- **Fix:** Use single font variant, remove unused fonts
- **Savings:** ~500MB-1GB

---

## Optimization Strategy

### Phase 1: Quick Wins (Saves ~3-4GB)

#### 1.1 Remove Old Font Versions

**Action:** Pin Iosevka to single version

```nix
# In home/common/theme.nix
home.packages = with pkgs; [
  # Replace multiple Iosevka versions with single pinned version
  iosevka-bin  # Use binary version instead of building from source
  nerd-fonts.iosevka  # Only one nerd-font variant
];
```

**Savings:** ~1GB

#### 1.2 Remove LibreOffice from System Packages

**Action:** Install LibreOffice only in home-manager (already done in `desktop-apps.nix`)

**Check:** Ensure it's not in system packages
**Savings:** ~1.3GB if duplicated

#### 1.3 Run Aggressive Cleanup

**Action:** Run cleanup script + GC

```bash
sudo bash ~/.config/nix/scripts/cleanup-enhanced.sh
sudo nix-collect-garbage -d
sudo nix-store --optimise
```

**Savings:** ~1-2GB

### Phase 2: Development Tools Optimization (Saves ~1-2GB)

#### 2.1 Move Dev Tools to devShells

**Action:** Create devShells for common development scenarios

**Current:** These are installed globally:

- `cmake`, `gnumake`, `pkg-config`, `openssl`, `libsecret`, `libiconv`

**Fix:** Create devShells in `shells/projects/`:

```nix
# shells/projects/development.nix
{
  pkgs,
  ...
}: {
  default = pkgs.mkShell {
    buildInputs = with pkgs; [
      cmake
      gnumake
      pkg-config
      openssl
      libsecret
      libiconv
      # ... other dev tools
    ];
  };
}
```

**Then remove from:** `home/common/apps/packages.nix` and `home/common/apps/core-tooling.nix`

**Savings:** ~1-2GB

#### 2.2 Use rustup Instead of Global rustc

**Action:** Ensure `rustup` is used, remove global rustc installations

**Current:** Multiple rustc versions in store
**Fix:** Already using `rustup` in config, but old versions still in store
**Action:** Run cleanup to remove old rustc versions

**Savings:** ~700MB-1GB

### Phase 3: Font Optimization (Saves ~500MB-1GB)

#### 3.1 Use Binary Fonts Instead of Building

**Action:** Replace `iosevka` with `iosevka-bin`

```nix
# In home/common/theme.nix
home.packages = with pkgs; [
  iosevka-bin  # Pre-built binary instead of building from source
  nerd-fonts.iosevka  # Keep nerd-font variant
];
```

**Savings:** ~200-300MB

#### 3.2 Remove Unused Font Packages

**Action:** Audit and remove fonts not actively used

**Check:** What fonts are actually used?

- Iosevka (terminal, GTK)
- Nerd Fonts (terminal icons)
- Catppuccin cursors (already using)

**Remove:** Any other font packages not needed

**Savings:** ~300-500MB

### Phase 4: Package Cleanup (Saves ~1-2GB)

#### 4.1 Remove Old Package Versions

**Action:** Enhanced cleanup script should handle this

**Packages to target:**

- Zoom: 3 versions → keep latest only
- OpenJDK: 2 versions → keep latest only
- Ollama: 2 versions → keep latest only
- NVIDIA drivers: Keep only current kernel version

**Savings:** ~1-2GB

#### 4.2 Remove Debug Packages

**Action:** Enhanced cleanup script should handle this

**Known debug packages:**

- `cmake-3.31.7-debug`: 454MB
- Various other debug packages: ~300MB

**Savings:** ~750MB

### Phase 5: Configuration Optimizations (Saves ~500MB-1GB)

#### 5.1 More Aggressive GC

**Action:** Already configured to 3 days (good!)

**Current:** `--delete-older-than 3d`
**Status:** ✅ Already optimized

#### 5.2 Reduce System Generations Further

**Action:** Already set to 5 (good!)

**Current:** `boot.loader.systemd-boot.configurationLimit = 5`
**Status:** ✅ Already optimized

#### 5.3 Disable Keep-Outputs/Derivations (Optional)

**Warning:** Only if you never rebuild from source

```nix
# In modules/nixos/system/nix/nix-optimization.nix
nix.settings.keep-outputs = false;
nix.settings.keep-derivations = false;
```

**Savings:** ~2-3GB but **makes rebuilds slower**
**Recommendation:** ⚠️ Only if desperate for space

---

## Implementation Plan

### Step 1: Analyze Current State

```bash
# Check current store size
du -sh /nix/store

# List largest packages
nix path-info -rSh /run/current-system | sort -rn | head -50

# Check for duplicates
bash ~/.config/nix/scripts/analyze-services.sh
```

### Step 2: Run Cleanup Scripts

```bash
# Run enhanced cleanup
sudo bash ~/.config/nix/scripts/cleanup-enhanced.sh

# Run GC
sudo nix-collect-garbage -d

# Optimize store
sudo nix-store --optimise
```

### Step 3: Optimize Font Configuration

- Update `home/common/theme.nix` to use `iosevka-bin`
- Remove duplicate font installations
- Rebuild home-manager

### Step 4: Move Dev Tools to devShells

- Create devShells for common scenarios
- Remove dev tools from global packages
- Update documentation

### Step 5: Verify Savings

```bash
# Check new store size
du -sh /nix/store

# Compare before/after
```

---

## Expected Results

### Conservative Estimate (Safe Optimizations)

- Font optimization: -1GB
- Dev tools to devShells: -1GB
- Cleanup old versions: -1GB
- **Total: -3GB → ~32GB**

### Aggressive Estimate (All Optimizations)

- Font optimization: -1GB
- Dev tools to devShells: -2GB
- Cleanup old versions: -2GB
- Remove debug packages: -750MB
- Remove LibreOffice duplication: -1.3GB
- **Total: -7GB → ~28GB**

### Realistic Goal

**Target: 28-30GB** (down from 35.4GB)

- Achievable with safe optimizations
- Maintains all functionality
- No performance impact

---

## What NOT to Optimize

❌ **Don't remove:**

- Services you're using (media management, AI tools)
- CUDA libraries (needed for Ollama GPU)
- NVIDIA drivers (needed for GPU)
- Linux firmware (needed for hardware)
- Active development tools (move to devShells instead)

❌ **Don't disable:**

- Auto-optimization (already enabled)
- GC (already optimized)
- Keep-outputs (unless desperate)

---

## Maintenance

### Regular Cleanup Schedule

- **Weekly:** Automatic GC (already configured)
- **Monthly:** Enhanced cleanup script (already configured)
- **Quarterly:** Manual audit of large packages

### Monitoring

```bash
# Check store size regularly
du -sh /nix/store

# Analyze largest packages
nix path-info -rSh /run/current-system | sort -rn | head -20

# Use nix-du for interactive analysis
nix-shell -p nix-du --run "nix-du /nix/store | less"
```

---

## References

- [NixOS Storage Optimization](https://nixos.wiki/wiki/Storage_optimization)
- [Nix Store Optimization](https://nix.dev/manual/nix/latest/command-ref/nix-store/optimise)
- [Cleaning the Nix Store](https://wiki.nixos.org/wiki/Cleaning_the_nix_store)
