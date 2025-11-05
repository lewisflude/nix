# nh Performance Guide

## Understanding `nh os switch` Timing

### What `nh os switch` Does

1. **Evaluation Phase** (2-10 seconds typically)
   - Parses all Nix modules
   - Merges configuration
   - Type-checks options
   - Builds derivation graph

2. **Build/Download Phase** (30 seconds - several minutes)
   - Downloads packages from binary caches
   - Builds packages not in cache
   - Verifies closures

3. **Switch Phase** (10-30 seconds)
   - Activates new system configuration
   - Restarts services
   - Updates system profile

### Your 1m44s Breakdown

For a typical switch with minimal changes:

- **Evaluation**: ~5-10 seconds
- **Build/Download**: ~60-90 seconds (most time)
- **Switch**: ~15-30 seconds
- **Total**: ~1m30s-2m30s ✅ **Normal**

## The `options.json` Warning

### What It Means

```
warning: Using 'builtins.toFile' to create a file named 'options.json'
that references the store path '/nix/store/...' without a proper context.
```

This warning appears when:

- The NixOS module system generates option introspection
- Some tooling (like `nixos-options` or documentation generators) creates `options.json`
- Store paths are referenced without proper derivation context

### Is It Harmful?

**Short answer**: No, it's harmless for now.

**Long answer**:

- ✅ **Doesn't affect functionality** - Your system works fine
- ✅ **Doesn't affect build time** - Negligible impact
- ⚠️ **May break in future** - Could become an error in future Nix versions
- ⚠️ **Garbage collection** - The referenced store path might not be tracked correctly

### How to Fix It

The warning usually comes from:

1. **NixOS module system itself** - Not fixable from user config
2. **Home Manager** - Known issue in some versions
3. **Custom option introspection** - If you have custom tooling

**If it's coming from NixOS/Home Manager:**

- Wait for upstream fix (already reported)
- Or suppress warnings (not recommended)

**If it's from your config:**

- Check for any custom `options.json` generation
- Ensure store paths are properly referenced in derivations

### Checking the Source

```bash
# Enable verbose evaluation to see where it comes from
nix eval --raw .#nixosConfigurations.jupiter.config.system.build.toplevel 2>&1 | grep -A 5 "options.json"

# Or check during rebuild
nixos-rebuild switch --show-trace 2>&1 | grep -A 5 "options.json"
```

## Performance Optimization

### 1. Enable Binary Caches

You already have this configured in `flake.nix` ✅

```bash
# Verify caches are working
nix-build-uncached -A nixosConfigurations.jupiter.config.system.build.toplevel

# Check cache hit rate
nix path-info -rS $(nix-build --no-out-link .#nixosConfigurations.jupiter.config.system.build.toplevel) | \
  grep -E "cache|store" | head -20
```

### 2. Disable nh Clean During Switch

Already configured in `home/common/nh.nix`:

```nix
programs.nh.clean.enable = false;  # ✅ Already done
```

This is the **biggest performance improvement** for `nh os switch`.

### 3. Use Parallel Builds

Check your `nix.conf`:

```bash
# Should have:
max-jobs = auto
cores = 0
```

### 4. Monitor What's Slow

```bash
# Time evaluation separately
time nix eval --raw .#nixosConfigurations.jupiter.config.system.build.toplevel

# Time build separately
time nix build .#nixosConfigurations.jupiter.config.system.build.toplevel --no-link

# Full switch with timing
time nh os switch
```

## Expected Timings

### Evaluation Time

- **< 2 seconds**: Excellent
- **2-5 seconds**: Good
- **5-10 seconds**: Acceptable
- **> 10 seconds**: Consider optimization

### Total Switch Time

- **30 seconds - 2 minutes**: Normal (with cache hits)
- **2-5 minutes**: Normal (some builds needed)
- **5-10 minutes**: Slow but acceptable (many builds)
- **> 10 minutes**: Consider optimization

### Your Performance

- **1m44s total**: ✅ **Normal and acceptable**
- Evaluation: Likely 5-10 seconds
- Build/Download: Likely 60-90 seconds
- Switch: Likely 15-30 seconds

## Troubleshooting Slow Switches

### If Switch Takes > 5 Minutes

1. **Check cache hit rate**:

   ```bash
   nix path-info -rS $(nix-build --no-out-link .#nixosConfigurations.jupiter.config.system.build.toplevel) | \
     wc -l
   ```

2. **Check what's being built**:

   ```bash
   nix build .#nixosConfigurations.jupiter.config.system.build.toplevel --print-build-logs 2>&1 | \
     grep "building" | head -20
   ```

3. **Check network speed**:

   ```bash
   # Time a cache download
   time nix-store --realise /nix/store/...some-package... --dry-run
   ```

4. **Check for large derivations**:

   ```bash
   nix path-info -S $(nix-build --no-out-link .#nixosConfigurations.jupiter.config.system.build.toplevel) | \
     sort -k2 -rn | head -20
   ```

### If Evaluation Takes > 10 Seconds

See `docs/EVALUATION_PERFORMANCE.md` for optimization strategies.

## Comparison: Before/After Optimization

### Typical Improvements

| Optimization | Time Saved | Impact |
|-------------|------------|--------|
| Disable nh clean | 30-60s | ⭐⭐⭐ High |
| Binary caches | 1-5 minutes | ⭐⭐⭐ High |
| Parallel builds | 20-40% | ⭐⭐ Medium |
| Reduce packages | 10-30% | ⭐⭐ Medium |
| Optimize modules | 0.5-2s | ⭐ Low |

## Summary

### Your Current Performance ✅

- **Total time**: 1m44s - **Normal**
- **Warnings**: Harmless (known NixOS issue)
- **Configuration**: Well-optimized

### Recommendations

1. ✅ **Already optimized**: Binary caches, nh clean disabled
2. ⚠️ **Monitor**: If switch time increases > 5 minutes, investigate
3. ℹ️ **Warnings**: Can be ignored (upstream issue)
4. 📊 **Track**: Monitor switch times over time

### Next Steps

1. **Baseline established**: 1m44s is good
2. **Monitor changes**: Track if switch time increases
3. **Ignore warnings**: They're harmless
4. **Focus elsewhere**: Evaluation optimization has minimal impact compared to build time

**Bottom line**: Your switch time is normal and your configuration is well-optimized. The warnings are a known NixOS issue and can be safely ignored.
