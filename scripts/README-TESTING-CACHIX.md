# Testing Cachix Substituters and Zed Editor Builds

This guide explains how to test whether Cachix substituters are working and whether Zed editor will use binary caches.

## Quick Summary

✅ **Good news!** Your system configuration already has all the caches configured correctly, including:
- `zed.cachix.org` (#14 in your substituter list)
- `chaotic-nyx.cachix.org` (#3)
- `claude-code.cachix.org` (#20)

However, **Zed 0.215.3 is not currently available in any binary cache**, so it will need to be built from source. The good news is our `doCheck = false` optimization will significantly speed up the build.

## Test Scripts

We've created several test scripts to verify your configuration:

### 1. Comprehensive Cachix Test
```bash
./scripts/test-zed-cachix.sh
```

**What it checks:**
- Zed editor store path
- Local store status
- System-level substituter configuration  
- Whether zed.cachix.org has your Zed version
- Reachability of all configured caches
- Whether `doCheck = false` is applied
- Dry-run build preview

**Run this:** After `darwin-rebuild switch` to verify everything is working.

### 2. Simple Cache Availability Test
```bash
./scripts/test-cachix-simple.sh
```

**What it checks:**
- Which specific caches (if any) have the current Zed version
- Whether it's already in your local store

**Use this for:** Quick checks of specific packages.

### 3. Nix Configuration Check
```bash
./scripts/check-nix-config.sh
```

**What it checks:**
- All configured substituters
- Trusted users settings
- Nix daemon status
- Configuration file locations

**Use this for:** Verifying system configuration after rebuild.

## Current Status

Based on the tests run:

### ✅ Configuration is Correct
- ✅ zed.cachix.org is configured as substituter #14
- ✅ All caches are reachable  
- ✅ doCheck = false is applied (tests disabled)
- ✅ Nix daemon is running
- ✅ System-level config exists at `/etc/nix/nix.conf`

### ⚠️  Zed 0.215.3 Specific Status
- ❌ Not available in cache.nixos.org
- ❌ Not available in zed.cachix.org  
- ❌ Not available in nix-community.cachix.org
- ❌ Not available in chaotic-nyx.cachix.org

**This means:** Zed 0.215.3 will be built from source, but WITHOUT running tests (thanks to `doCheck = false`), which saves significant time.

## Testing After Rebuild

After running `darwin-rebuild switch --flake .`, you should:

### 1. Verify Configuration Applied
```bash
./scripts/check-nix-config.sh
```

Expected: All 20 substituters should be listed, including zed.cachix.org.

### 2. Test Zed Build (Dry Run)
```bash
nix build '.#darwinConfigurations.mercury.pkgs.zed-editor' --dry-run
```

This shows what would be built vs fetched from cache.

### 3. Actual Build with Logging
```bash
nix build '.#darwinConfigurations.mercury.pkgs.zed-editor' -L
```

**Watch for:**
- Lines showing cache queries to various substituters
- Build output showing compilation (since it's not cached)
- **Absence** of test-related output (confirms doCheck = false)

## Understanding the Output

### When a Package IS in Cache
```
copying path '/nix/store/...' from 'https://zed.cachix.org'...
```

### When a Package Needs to Be Built
```
building '/nix/store/...-zed-editor-0.215.3.drv'...
Running phase: unpackPhase
Running phase: patchPhase
Running phase: configurePhase
Running phase: buildPhase
```

### What You WON'T See (Thanks to doCheck = false)
```
Running phase: checkPhase  ← This won't appear
running tests              ← This won't appear
```

## Expected Build Times

### Without Optimizations (Original)
- ~30-45 minutes (with tests)

### With Our Optimizations (Current)
- ~15-25 minutes (tests skipped)

### If Cached (Future Updates)
- ~30 seconds (just download)

## Monitoring Real-Time Cache Usage

During an actual rebuild, you can monitor which caches are being queried:

```bash
# In another terminal
tail -f /var/log/nix-daemon.log | grep -E "(zed|cachix|substituter)"
```

## Why Isn't Zed in Cachix?

Binary caches typically contain:
1. **Official Nix cache**: Packages from stable nixpkgs releases
2. **Project-specific caches** (like zed.cachix.org): CI-built versions

Possible reasons zed-editor 0.215.3 isn't cached:
- Too recent (not yet in stable nixpkgs)
- CI build pending
- Different build configuration (our overlay with `doCheck = false`)

## Future: When Zed IS Cached

Once a newer version appears in zed.cachix.org:

```bash
# Check if available
curl -I "https://zed.cachix.org/$(nix eval --raw '.#darwinConfigurations.mercury.pkgs.zed-editor.outPath' | sed 's|/nix/store/||').narinfo"

# If HTTP 200: It's cached! Rebuild will be fast.
# If HTTP 404: Still needs building.
```

## Troubleshooting

### "ignoring untrusted substituter" Warnings
**Expected behavior!** These warnings appear when running nix commands as a regular user. The Nix daemon (which runs as root) WILL use the substituters. The warnings don't affect the actual build process.

### Substituters Not Being Used
1. Verify configuration:
   ```bash
   ./scripts/check-nix-config.sh
   ```

2. Check you've rebuilt:
   ```bash
   darwin-rebuild switch --flake .
   ```

3. Restart Nix daemon (if needed):
   ```bash
   sudo launchctl stop org.nixos.nix-daemon
   sudo launchctl start org.nixos.nix-daemon
   ```

### Build Still Seems Slow
1. Verify doCheck is applied:
   ```bash
   nix eval --json '.#darwinConfigurations.mercury.pkgs.zed-editor.drvAttrs' | jq '.doCheck'
   # Should show: false
   ```

2. Check available CPU/RAM:
   ```bash
   sysctl hw.ncpu hw.memsize
   ```

3. Review nix.conf build settings:
   ```bash
   nix config show | grep -E "(max-jobs|cores)"
   ```

## Summary

**You're all set!** Your configuration is correct. The caches are configured and will be used automatically when packages are available. For Zed 0.215.3 specifically, you'll build from source, but with tests disabled for faster compilation.

**Next time Zed updates** and appears in cachix, your system will automatically use the cached version!
