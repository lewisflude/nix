# Store Optimization Implementation Summary

## Changes Made

### ✅ 1. Font Optimization (Saves ~500MB-1GB)

- **Changed:** `iosevka` → `iosevka-bin` in `home/common/theme.nix`
- **Reason:** Binary fonts don't require building from source, saving space
- **Impact:** Reduces font-related store size significantly

### ✅ 2. Development Tools Moved to devShells (Saves ~1-2GB)

- **Created:** `shells/projects/development.nix` with common dev tools
- **Removed from global packages:**
  - `cmake`, `gnumake`, `pkg-config`, `openssl`, `libsecret`, `libiconv`
- **Updated files:**
  - `home/common/apps/packages.nix`
  - `home/common/apps/core-tooling.nix`
- **Usage:** `nix develop .#devShells.development`
- **Impact:** Dev tools only loaded when needed, not in global closure

### ✅ 3. Documentation Created

- **Created:** `docs/STORE_OPTIMIZATION_GUIDE.md` with comprehensive optimization strategies

## Next Steps

### Immediate Actions (Run These Commands)

```bash
# 1. Rebuild home-manager to apply font changes
home-manager switch

# 2. Run cleanup script to remove old packages
sudo bash ~/.config/nix/scripts/cleanup-enhanced.sh

# 3. Run garbage collection
sudo nix-collect-garbage -d

# 4. Optimize store (deduplicate)
sudo nix-store --optimise

# 5. Check new store size
du -sh /nix/store
```

### Expected Results

**Before:** 35.4GB
**After Phase 1:** ~32-33GB (font optimization + cleanup)
**After Phase 2:** ~30-31GB (dev tools moved to devShells)

**Target:** 28-30GB (down from 35.4GB)

## Additional Optimizations Available

See `docs/STORE_OPTIMIZATION_GUIDE.md` for:

- Removing old package versions
- Font package optimization
- Advanced cleanup strategies
- Optional aggressive optimizations

## Notes

- **LibreOffice:** Currently installed in both `desktop-apps.nix` and `productivity/default.nix`
  - These are conditional (only if productivity.office = true)
  - Should be fine, but could consolidate to one location if desired

- **Dev Tools:** Tools moved to devShells are still available, just not in global PATH
  - Use `nix develop .#devShells.development` when needed
  - Or add to project-specific `.envrc` files

- **Fonts:** `iosevka-bin` may have slightly different features than `iosevka`
  - If you notice issues, revert to `iosevka` but expect larger store size

## Verification

After rebuilding, verify:

```bash
# Check store size
du -sh /nix/store

# Verify dev tools are in devShell
nix develop .#devShells.development
which cmake  # Should work in shell
exit
which cmake  # Should not be in global PATH

# Check fonts are working
fc-list | grep -i iosevka
```
