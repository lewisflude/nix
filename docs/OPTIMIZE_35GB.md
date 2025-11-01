# Further Optimization Guide for 35.4GB Store

## Current Status ✅

- **Store size:** 35.4GB (down from 60GB!)
- **All services:** Running and in use
- **Cleanup:** Already done

## What's Taking Up Space (35.4GB Breakdown)

### Services (~4.5GB) - All in use

- Media management: ~2GB (Jellyfin, Jellyseerr, Radarr, Sonarr, etc.)
- AI tools: ~2.2GB (Ollama + Open WebUI)
- Home Assistant: ~350MB
- Cal.com: ~300MB

### System Packages (~2.5GB)

- Linux firmware: ~700MB
- NVIDIA drivers: ~400MB
- CUDA libraries: ~1.3GB (needed for Ollama GPU)

### User Packages (~28GB)

- LibreOffice: ~1.3GB
- Development tools: ~2GB
- Other packages: ~25GB

## Additional Optimization Options

### 1. More Aggressive GC (Saves ~1-2GB)

Edit `modules/nixos/system/nix/nix-optimization.nix`:

```nix
nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 3d";  # Changed from 7d to 3d
};
```

**Savings:** ~1-2GB by keeping fewer generations

### 2. Limit System Generations (Saves ~500MB-1GB)

Add to your host configuration:

```nix
boot.loader.systemd-boot.configurationLimit = 5;  # Keep only 5 generations
```

**Savings:** ~500MB-1GB per extra generation

### 3. Disable Keep Outputs/Derivations (Saves ~2-3GB)

Only if you **never rebuild from source**:

```nix
nix.settings.keep-outputs = false;
nix.settings.keep-derivations = false;
```

**Warning:** Makes rebuilds slower, but saves space

### 4. Remove LibreOffice if Not Needed (Saves ~1.3GB)

In `hosts/jupiter/default.nix`:

```nix
productivity = {
  enable = true;
  office = false;  # Disable LibreOffice
};
```

### 5. Use Minimal JRE Instead of Full JDK (Saves ~400MB)

If you have Java installed, check if you need full JDK or can use minimal JRE.

### 6. Review Development Tools

Your dev tools are already in devShells (good!), but check if you have global installs:

- Rust toolchain: ~800MB (if global, use rustup instead)
- LLVM/Clang: ~1.5GB (if multiple versions)

### 7. Remove Debug Packages (Saves ~750MB)

The cleanup script should handle this, but verify:

```bash
du -sh /nix/store/*debug* 2>/dev/null | wc -l
```

## Recommended Optimizations (Safe)

### Priority 1: Quick Wins

1. ✅ **Limit system generations** - Safe, saves ~500MB-1GB
2. ✅ **More aggressive GC** - Safe, saves ~1-2GB
3. ✅ **Remove LibreOffice if unused** - Safe, saves ~1.3GB

**Total:** ~3-4GB savings → **~31-32GB**

### Priority 2: Advanced (Only if Needed)

4. ⚠️ **Disable keep-outputs** - Makes rebuilds slower
5. ⚠️ **Review development tools** - Only if not actively using

## Configuration Changes

### Option 1: Limit Generations + Aggressive GC

```nix
# In hosts/jupiter/configuration.nix or host config
boot.loader.systemd-boot.configurationLimit = 5;

# In modules/nixos/system/nix/nix-optimization.nix
nix.gc.options = "--delete-older-than 3d";
```

### Option 2: Disable LibreOffice

```nix
# In hosts/jupiter/default.nix
productivity = {
  enable = true;
  office = false;
};
```

## Expected Results

**Current:** 35.4GB

**After Priority 1 optimizations:**

- Limit generations: -500MB to -1GB
- Aggressive GC: -1GB to -2GB
- Remove LibreOffice: -1.3GB (if not needed)

**Target:** ~31-32GB (**3-4GB savings**)

## What NOT to Do

❌ Don't disable services you're using (they're all running!)
❌ Don't disable CUDA libraries (needed for Ollama GPU)
❌ Don't disable keep-outputs if you rebuild from source

## Monitoring

Use the analyzer script to check regularly:

```bash
bash ~/.config/nix/scripts/analyze-services.sh
```

## Summary

At 35.4GB, you're already well-optimized! The remaining space is mostly:

- Services you're actively using (~4.5GB)
- System packages (~2.5GB)
- User packages (~28GB)

Further reductions would require:

- Disabling services (not recommended - you're using them)
- More aggressive GC (can do safely)
- Removing optional packages (LibreOffice, etc.)

**Bottom line:** 35.4GB is reasonable for a system with media server, AI tools, and development environment!
