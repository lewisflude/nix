# Quick Optimization Guide for 35.4GB Store

## Current Status ✅

- **Store size:** 35.4GB (down from 60GB!)
- **All services:** Running and in use
- **Still has duplicates:** Need to run cleanup again

## Immediate Actions

### 1. Run Cleanup Script Again (Removes Remaining Duplicates)

The cleanup script found duplicates that weren't removed. Run it again:

```bash
sudo bash ~/.config/nix/scripts/cleanup-duplicates.sh
```

This should remove:

- Old LibreOffice (659MB) - ✅ Verified as NOT referenced
- Duplicate Ollama versions (~1.2GB)
- Duplicate CUDA libraries (672MB)
- Debug packages (~750MB)

**Expected savings:** ~3-4GB → **~31-32GB**

### 2. Configuration Optimizations (Already Applied!)

I've added two optimizations to your config:

✅ **Limit system generations** (added to `hosts/jupiter/configuration.nix`)

- Keeps only 5 generations instead of default
- **Savings:** ~500MB-1GB

✅ **More aggressive GC** (updated in `nix-optimization.nix`)

- Keeps packages only 3 days instead of 7
- **Savings:** ~1-2GB

**Total from config changes:** ~1.5-3GB

### 3. Optional: Disable LibreOffice (if not needed)

If you don't use LibreOffice, edit `hosts/jupiter/default.nix`:

```nix
productivity = {
  enable = true;
  office = false;  # Disable LibreOffice
};
```

**Savings:** ~1.3GB

## Expected Results

**Current:** 35.4GB

**After cleanup script:** ~31-32GB
**After config optimizations:** ~28-30GB (after rebuild)
**After removing LibreOffice:** ~27-29GB (if disabled)

**Total potential:** ~6-8GB reduction

## Next Steps

1. ✅ **Run cleanup script again** (removes duplicates)
2. ✅ **Rebuild system** (applies config changes)
3. ⚠️ **Review LibreOffice** (disable if not needed)

## What's Using Space (After Optimization)

### Services (~4.5GB) - All in use, keep them

- Media management: ~2GB
- AI tools: ~2.2GB
- Home Assistant: ~350MB
- Cal.com: ~300MB

### System (~2.5GB) - Required

- Linux firmware: ~700MB
- NVIDIA drivers: ~400MB
- CUDA libraries: ~1.3GB (needed for Ollama GPU)

### User Packages (~23GB) - Can optimize

- LibreOffice: ~1.3GB (can disable)
- Development tools: ~2GB
- Other packages: ~20GB

## Summary

**Immediate actions:**

1. Run cleanup script → saves ~3-4GB
2. Rebuild system → applies config optimizations → saves ~1.5-3GB
3. Disable LibreOffice (optional) → saves ~1.3GB

**Target:** ~27-29GB (**~6-8GB reduction**)

35.4GB is already good! These optimizations will get you to ~27-29GB which is excellent for a system with media server, AI tools, and development environment.
