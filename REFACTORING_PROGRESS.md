# Refactoring Progress Report

**Date:** 2025-11-20
**Session:** Addressing Over-Engineering Issues
**Branch:** `claude/review-nix-overengineering-013KxQhDS7sJYJxoMjnABV9J`

---

## ✅ Completed Refactorings

### 1. Removed Validation System (911 lines) 🔴 CRITICAL

**Deleted:**

- `modules/shared/features/theming/validation.nix` (523 lines)
  - WCAG 2.1 contrast ratio calculations
  - APCA (Advanced Perceptual Contrast Algorithm)
  - sRGB to linear RGB conversion
  - Relative luminance with gamma correction
- `modules/shared/features/theming/tests/validation.nix`
- `lib/validators.nix` (21 lines)
- Validation options from `theming/options.nix` (59 lines)
- `tests/evaluation.nix` validation test case

**Why:** Enterprise-grade color science algorithms implemented in pure Nix to validate a statically-defined palette that never changes. This is the type of validation that belongs in design tools, not configuration management.

**Impact:**

- **-911 lines** of unnecessary code
- **Faster evaluation** (no color science calculations)
- **Simpler mental model** (no validation complexity)
- **Zero functional loss** (palette was always valid)

**Commit:** `c60d72d`

---

## 📋 Remaining High-Priority Items

### 2. Three-Layer Media Management Pattern 🔴 CRITICAL

**Current Structure:**

```
Layer 1: modules/shared/host-options/services/media-management.nix (240 lines)
         └─> host.features.mediaManagement options (user-facing)

Layer 2: modules/nixos/features/media-management.nix (33 lines)
         └─> Pure passthrough! Just copies cfg.prowlarr to cfg.prowlarr

Layer 3: modules/nixos/services/media-management/options.nix (34 lines)
         └─> host.services.mediaManagement options (internal)

Layer 4: modules/nixos/services/media-management/*.nix (15 files)
         └─> Actual service implementations
```

**Problem:** Layer 2 is pure abstraction adding zero value. Layer 3 duplicates Layer 1 options.

**Solution:**

1. Delete `modules/nixos/features/media-management.nix` (passthrough layer)
2. Update service modules to read from `host.features.mediaManagement` directly
3. Remove `host.services.mediaManagement` options (duplicate of Layer 1)

**Affected Files:** ~17 files (1 deleted, 16 updated)

**Risk:** MEDIUM - Requires updating multiple service files, but pattern is straightforward

**Estimated Reduction:** ~300 lines of duplicate/passthrough code

---

### 3. Brand Governance Over-Engineering 🟠 HIGH

**Location:** `modules/shared/features/theming/options.nix`

**Current Complexity:**

- 3 governance policies (functional-override, separate-layer, integrated)
- `brandLayers` with priority system
- Duplicate color type definitions (l, c, h, hex) repeated 3 times
- 130+ lines of options for... personal dotfiles

**Usage:** Only referenced in assertions (lines 79-90 in theming/default.nix)

**Modern Approach:**

```nix
# Simple color overrides (if even needed)
colorOverrides = {
  accent-primary = "#your-color";
  accent-secondary = "#another-color";
};
```

**Solution:**

1. Replace entire `brandGovernance` section with simple `colorOverrides`
2. Remove `overrides` option (marked DEPRECATED)
3. Update assertions to match simplified model

**Risk:** LOW if no one is using brand governance (check host configs first)

**Estimated Reduction:** ~120 lines

---

### 4. Feature Builders Abstraction 🟡 MEDIUM

**Location:** `lib/feature-builders.nix` (130 lines)

**Used By:**

- `home/common/features/development/default.nix`
- `modules/shared/features/development/default.nix`
- `shells/default.nix`
- `shells/projects/*.nix`

**What It Does:**

```nix
mkHomePackages = { cfg, pkgs }:
  lib.concatLists [
    (lib.optionals (cfg.rust or false) packageSets.rustToolchain)
    (lib.optionals (cfg.python or false) (packageSets.pythonToolchain pkgs))
    # ... more concatenation
  ];
```

**Modern Approach:**

```nix
# Inline in consuming modules
home.packages = lib.optionals cfg.rust [ pkgs.rustc pkgs.cargo ]
  ++ lib.optionals cfg.python [ pkgs.python3 pkgs.poetry ];
```

**Solution:**

1. Inline the logic into the 6 consuming files
2. Delete `lib/feature-builders.nix`

**Risk:** LOW - Straightforward inlining, clear pattern

**Estimated Reduction:** ~130 lines (lib) + ~30 lines (simplified consumers) = ~100 net

---

### 5. Flake-Parts Fragmentation 🟡 MEDIUM

**Location:** `flake-parts/` (14 files, ~303 lines)

**Structure:**

```
flake-parts/
├── core.nix (35 lines) - Just imports the others
├── systems.nix (8 lines)
├── module-args.nix (20 lines)
├── outputs/ (4 files, ~80 lines)
└── per-system/ (7 files, ~160 lines)
```

**Modern Best Practice** (from jade.fyi):
> "Use flakes as entry points, not composition tools. The Nix language and nixpkgs utilities handle internal composition."

**Solution:**

1. Consolidate all flake-parts/* into main `flake.nix`
2. Keep package definitions in `pkgs/` (good separation)
3. Keep module definitions in `modules/` (good separation)

**Risk:** MEDIUM - Requires careful ordering of let bindings

**Estimated Impact:** 14 files → 1 file (same ~300 lines, but single source of truth)

---

### 6. Container Supplemental Micro-Modules 🟡 MEDIUM

**Location:** `modules/nixos/services/containers-supplemental/` (12 files)

**Pattern:** Each 30-50 line file follows identical structure:

```nix
{ config, lib, pkgs, ... }:
let cfg = config.host.services.containersSupplement.serviceName;
in {
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.serviceName = {
      image = "...";
      ports = [ "..." ];
      volumes = [ "..." ];
    };
  };
}
```

**Solution:**

1. Merge all services into single `containers-supplemental.nix` (~250-300 lines)
2. Group related services together with comments

**Risk:** LOW - Services are independent, no cross-dependencies

**Estimated Reduction:** 12 files + boilerplate → 1 file (~200 lines net reduction)

---

## 📊 Summary Statistics

### Completed

- **Files deleted:** 4
- **Lines removed:** 911
- **Complexity reduced:** 🔴 CRITICAL issue resolved

### Remaining (Recommended Order)

1. **Merge container-supplemental** (LOW risk, ~200 lines saved)
2. **Simplify brand governance** (LOW risk, ~120 lines saved)
3. **Inline feature-builders** (LOW risk, ~100 lines saved)
4. **Flatten media-management** (MEDIUM risk, ~300 lines saved)
5. **Consolidate flake-parts** (MEDIUM risk, better structure)

### Potential Total Impact

- **Files:** 345 → ~315 (-30 files, -9%)
- **Lines:** 26,949 → ~25,200 (-1,749 lines, -6.5%)
- **Plus previous:** Total ~2,660 lines removed (-10%)

---

## 🛠️ How to Safely Continue

### Step 1: Merge Container-Supplemental (Safest)

```bash
# Create new consolidated file
# modules/nixos/services/containers-supplemental.nix

# Test it works
nix flake check

# Delete old files
git rm modules/nixos/services/containers-supplemental/*.nix
git mv modules/nixos/services/containers-supplemental.nix modules/nixos/services/

# Commit
git commit -m "refactor: consolidate container-supplemental micro-modules"
```

### Step 2: Simplify Brand Governance

```bash
# Check if anyone is using it
rg "brandGovernance\.(policy|brandColors|brandLayers)" --type nix hosts/

# If unused, simplify options.nix
# Test
nix flake check

# Commit
git commit -m "refactor: simplify over-engineered brand governance"
```

### Step 3: Inline Feature Builders

```bash
# For each consuming file, inline the logic
# Test each change
nix flake check

# Delete lib/feature-builders.nix
# Commit
git commit -m "refactor: inline feature-builders abstraction"
```

### Step 4: Flatten Media Management (Most Complex)

```bash
# Update each service file in media-management/
# Change: config.host.services.mediaManagement
# To:     config.host.features.mediaManagement

# Delete passthrough layer
git rm modules/nixos/features/media-management.nix

# Test thoroughly
nix flake check

# Commit
git commit -m "refactor: remove media-management three-layer abstraction"
```

### Step 5: Consolidate Flake Parts (Optional)

```bash
# Merge all flake-parts/* into flake.nix
# Careful with let binding order

# Test
nix flake check

# Commit
git commit -m "refactor: consolidate flake-parts into main flake"
```

---

## ⚠️ Important Notes

### What NOT to Remove

These are **good engineering** and should stay:

- ✅ Overlays (`overlays/default.nix`) - Clean, purposeful
- ✅ Scripts directory - Practical utilities
- ✅ Host configurations - Well-structured
- ✅ Individual app configs - Appropriately sized
- ✅ Per-service files for complex services (qBittorrent VPN, ProtonVPN)

### Testing Strategy

After each refactoring:

```bash
# 1. Syntax check
nix flake check

# 2. Build a system (if applicable)
# nixos-rebuild build --flake .#hostname

# 3. Check evaluation
nix eval .#nixosConfigurations --apply 'x: "ok"'

# 4. Git bisect if issues arise
git bisect start
git bisect bad
git bisect good <last-known-good-commit>
```

### Rollback Plan

Each commit is atomic and can be reverted:

```bash
git revert <commit-hash>
```

Or reset to before refactoring:

```bash
git reset --hard 5972689  # Before refactoring started
```

---

## 🎯 Success Criteria

A successful refactoring:

1. ✅ Removes unnecessary abstraction layers
2. ✅ Makes codebase easier to understand
3. ✅ Reduces line count and file count
4. ✅ Maintains all functionality
5. ✅ Passes `nix flake check`
6. ✅ Builds successfully
7. ✅ No runtime errors

---

## 📚 References

- **Modern Nix Best Practices:** jade.fyi/blog/flakes-arent-real
- **Determinate Systems:** Best practices for Nix at work
- **NixOS Wiki:** Flakes patterns and anti-patterns
- **This Repository:** OVER_ENGINEERING_ANALYSIS.md

---

**Remember:** The goal isn't to remove all abstraction—it's to keep abstractions that provide clear value. The system should be as complex as necessary, but no more.

**Next Session:** Pick the lowest-risk item from the list above and execute it with full testing.
