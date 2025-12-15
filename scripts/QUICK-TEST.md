# Quick Cachix Testing Reference

## TL;DR - Test Commands

### Before Rebuild
```bash
# Check if configuration will include caches
nix eval --raw '.#darwinConfigurations.mercury.config.nix.settings.extra-substituters' | tr ' ' '\n'
```

### After Rebuild  
```bash
# Verify caches are active
./scripts/check-nix-config.sh

# Test if Zed is cached
./scripts/test-cachix-simple.sh

# Full diagnostic
./scripts/test-zed-cachix.sh
```

## One-Liner Tests

### Check if zed.cachix.org is configured:
```bash
nix config show | grep "zed.cachix.org" && echo "✅ Configured" || echo "❌ Not configured"
```

### Check if Zed version is in cache:
```bash
ZED=$(nix eval --raw '.#darwinConfigurations.mercury.pkgs.zed-editor.outPath' 2>/dev/null)
curl -sI "https://zed.cachix.org${ZED}.narinfo" | head -n1
# HTTP/2 200 = Cached ✅
# HTTP/2 404 = Not cached ❌
```

### Verify doCheck=false:
```bash
nix eval --json '.#darwinConfigurations.mercury.pkgs.zed-editor.drvAttrs' 2>/dev/null | grep -q '"doCheck":false' && echo "✅ Tests disabled" || echo "❌ Tests enabled"
```

## Current Status Summary

**✅ Configuration:** Correct (all caches configured)  
**⚠️  Cache Hit:** Zed 0.215.3 not in any cache  
**✅ Optimization:** doCheck = false applied  
**📦 Result:** Will build from source, but ~50% faster

## Next Steps

1. **Rebuild system:**
   ```bash
   darwin-rebuild switch --flake .
   ```

2. **Verify config:**
   ```bash
   ./scripts/check-nix-config.sh
   ```

3. **Build Zed (when needed):**
   ```bash
   # The build will happen automatically during system rebuild
   # Or manually test:
   nix build '.#darwinConfigurations.mercury.pkgs.zed-editor' -L
   ```

## Expected Results

- ⚡ **First build:** 15-25 min (no tests)
- 🚀 **Future updates:** ~30 sec (if cached)
- 📊 **Cache queries:** ~20 substituters checked automatically

## Full Documentation

See `README-TESTING-CACHIX.md` for complete testing guide.
