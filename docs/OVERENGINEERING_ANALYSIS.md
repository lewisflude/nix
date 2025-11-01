# Overengineering & Complexity Analysis

This document identifies areas of overengineering and overcomplexity in the Nix configuration that should be cleaned up for better maintainability.

## Executive Summary

**High Priority Issues Found:**

- ✅ **2 confirmed unused files/functions** (~200+ lines of dead code):
  - `lib/cache.nix` - Entire file unused (135 lines)
  - `mkDevShells` in `lib/output-builders.nix` - Function unused (~35 lines)
- ⚠️ **3 duplicate pkgs config blocks** - Same config repeated in 3 locations
- 📚 **20+ documentation files** - Many appear to be temporary planning docs

**Total Dead Code:** ~170+ lines that can be removed immediately

**Estimated Cleanup Time:**

- Phase 1 (Quick wins): ~30 minutes
- Phase 2 (Medium effort): ~1-2 hours
- Phase 3 (Review): ~2-3 hours

## 1. Duplicate pkgs Configuration (High Priority)

**Problem**: The same `nixpkgs.config` block is repeated in 3+ places with identical values:

- `flake-parts/core.nix` (lines 61-65)
- `lib/output-builders.nix` (lines 111-118)
- `lib/system-builders.nix` (lines 136-142, 213-219)

**Impact**: Changes require updates in multiple places, risk of inconsistency.

**Solution**: Extract to a single function in `lib/functions.nix`:

```nix
mkPkgsConfig = {
  allowUnfree = true;
  allowUnfreePredicate = _: true;
  allowBroken = true;
  allowUnsupportedSystem = false;
};
```

Then use: `config = lib.mkPkgsConfig;`

## 2. Unused mkDevShells Function (High Priority) ✅ CONFIRMED UNUSED

**Problem**: `lib/output-builders.nix` defines `mkDevShells` (lines 70-105) but it's **never used**. The actual dev shells are built directly in `flake-parts/core.nix` using `shellsConfig.devShells`.

**Impact**: Dead code, confusion about which implementation is active.

**Solution**: **Remove `mkDevShells` entirely** from `output-builders.nix` - it's not referenced anywhere.

## 3. Overly Complex Virtualisation Abstraction (Medium Priority)

**Problem**: `lib/virtualisation.nix` has complex path-based flag derivation:

- Multiple possible paths for same flags (`enableDocker`, `docker.enable`, `docker`)
- Uses `getBoolFlag` with multiple path arrays
- Adds derived flags back to the original structure

**Impact**: Hard to understand, fragile, may not be needed if host configs are consistent.

**Solution**: Standardize on a single path structure in host configs, simplify the helper to just pass through normalized values.

## 4. Unused Cache Library Functions (High Priority) ✅ CONFIRMED UNUSED

**Problem**: `lib/cache.nix` exports functions that are **completely unused**:

- `createManifest`
- `generateCacheKey`
- `cachePackageLists`
- `evalCache`
- `cachixConfig`
- `prebuildManifest`

**Impact**: Dead code (135 lines) increases maintenance burden. The file is exported in `flake-parts/core.nix` line 158 but never actually used.

**Solution**: **Remove `lib/cache.nix` entirely** and remove it from the lib export in `flake-parts/core.nix` line 158, unless there are plans to use these functions.

## 5. withSystem Pattern (INFORMATIONAL - Actually Used) ✅

**Status**: `withSystem` is actively used in **24 files**, so it's providing value. This is NOT overengineering - it's a useful abstraction.

**Conclusion**: Keep `withSystem` as-is. It reduces boilerplate across many modules.

## 6. Multiple Overlay Import Patterns (Medium Priority)

**Problem**: Overlays are imported with slightly different patterns:

- `lib/system-builders.nix`: `lib.attrValues (import ../overlays {...})`
- `lib/output-builders.nix`: `lib.attrValues (import ../overlays {...})`
- `flake-parts/core.nix`: `lib.attrValues (import ../overlays {...})`
- `modules/shared/overlays.nix`: Different import pattern

**Impact**: Minor, but could be unified.

**Solution**: Extract overlay import to a helper function that returns the list directly.

## 7. Redundant System Detection Helpers (Low Priority)

**Problem**: `lib/functions.nix` wraps `lib.hasInfix` in functions like `isLinux`, `isDarwin`:

```nix
isLinux = system: lib.hasInfix "linux" system;
```

**Impact**: Very minor, but adds indirection. `lib.hasInfix` is already clear and concise.

**Solution**: Use `lib.hasInfix` directly where appropriate, or keep helpers if they're heavily used for consistency.

## 8. Overly Complex Validation System (Low Priority)

**Problem**: `lib/validation.nix` has a complex check system with severity levels, but only validates 4 required fields and one optional secrets check.

**Impact**: Overkill for simple field validation.

**Solution**: Consider simplifying to direct assertions or use NixOS module type checking instead.

## 9. Duplicate Host Filtering Logic (Low Priority)

**Problem**: `lib/hosts.nix` has `getDarwinHosts` and `getNixosHosts` that filter by system strings, but this could be done inline where needed.

**Impact**: Minor abstraction layer.

**Solution**: If only used once or twice, inline the filtering.

## 10. Documentation Overload (Informational)

**Problem**: 20+ documentation files in `docs/`, many appear to be temporary analysis/planning documents:

- Multiple optimization docs
- Multiple qbittorrent VPN docs
- Multiple Catppuccin docs

**Impact**: Hard to find relevant docs, many may be outdated.

**Solution**: Archive or consolidate old planning docs, keep only current reference material.

## 11. Complex qBittorrent Module (Informational)

**Problem**: `modules/nixos/services/media-management/qbittorrent.nix` is 715+ lines with complex VPN integration.

**Impact**: This may be justified complexity, but worth reviewing if it can be split into smaller modules.

**Solution**: Consider splitting into:

- `qbittorrent.nix` (core service)
- `qbittorrent-vpn.nix` (VPN integration)
- `qbittorrent-proxy.nix` (proxy setup)

## Recommended Cleanup Order

1. **Phase 1 (Quick Wins - ~30 minutes)**:
   - ✅ Remove unused `mkDevShells` from `lib/output-builders.nix` (confirmed unused)
   - ✅ Remove unused `lib/cache.nix` and its export (confirmed unused, saves ~135 lines)
   - Extract duplicate pkgs config to shared function (3 locations)

2. **Phase 2 (Medium Effort - ~1-2 hours)**:
   - Simplify virtualisation abstraction (if host configs can be standardized)
   - Consolidate overlay import patterns
   - Archive outdated documentation

3. **Phase 3 (Review & Optimize - ~2-3 hours)**:
   - ✅ Keep `withSystem` - it's actively used and valuable
   - Simplify validation system (if appropriate)
   - Consider splitting large modules like qBittorrent

## Metrics to Track

- Number of duplicate config blocks
- Lines of unused code
- Documentation files vs. actively maintained docs
- Number of abstraction layers for common operations
