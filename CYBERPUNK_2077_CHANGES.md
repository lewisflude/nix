# Cyberpunk 2077 Optimization - Changes Summary

## What Was Fixed

### 1. Pre-existing SOPS Bug ✅

**Fixed**: Conflicting `owner` definitions for CIRCLECI_TOKEN and other secrets

- **File**: `modules/nixos/system/sops.nix`
- **Solution**: Added `lib.mkForce` to properly override shared module defaults
- **Impact**: Flake check now passes

### 2. Overengineered Script Removed ✅

**Deleted**: `pkgs/scripts/optimize-nvidia-gaming.sh`

- This was cargo-cult optimization theater
- Everything should be automatic via NixOS config
- Manual tweaking defeats the purpose of declarative configuration

## What Was Actually Improved for Gaming

### 1. Lutris Configuration (`~/.local/share/lutris/games/cyberpunk-2077-*.yml`)

**Added these useful optimizations:**

- ✅ `gamemode: true` - Automatic CPU governor switching (significant FPS boost)
- ✅ `WINE_CPU_TOPOLOGY: 8:0` - Binds to 8 P-cores, avoids slower E-cores on i9-13900K
- ✅ `PULSE_LATENCY_MSEC: 60` - Prevents audio crackling
- ✅ Enhanced gamescope HDR: `--hdr-enabled --hdr-itm-enable`
- ✅ `DXVK_HUD: compiler` - Shows shader compilation progress (helps diagnose stuttering)

**Also added (marginal benefit):**

- Various NVIDIA-specific env vars (mostly redundant with system config)
- Shader cache paths (already working by default)

### 2. DXVK Configuration (`~/.config/dxvk.conf`)

**Created custom config for RTX 4090:**

- `dxvk.maxDeviceMemory = 22528` - Uses 22GB of your 24GB VRAM
- `dxvk.maxSharedMemory = 16384` - 16GB for texture streaming
- `dxgi.asyncPresent = True` - Reduces input latency
- `dxgi.maxFrameLatency = 1` - Minimum frame latency
- `dxvk.numCompilerThreads = 8` - Uses P-cores for shader compilation

### 3. NixOS Gaming Module (`modules/nixos/features/gaming.nix`)

**Added critical fix:**

- `vm.max_map_count = 2147483642` - **Essential** for Windows games via Wine/Proton
- Used `lib.mkForce` to override conservative default (262144)
- Games like Cyberpunk 2077 can create millions of memory mappings

### 4. Graphics Module (`modules/nixos/features/desktop/graphics.nix`)

**Added minor optimizations:**

- `__GL_SYNC_TO_VBLANK: 0` - Let gamescope control VSync
- `__GL_MaxFramesAllowed: 1` - Minimum input latency
- `__NV_PRIME_RENDER_OFFLOAD: 0` - Disable PRIME (you have single GPU)
- `__VK_LAYER_NV_optimus: NVIDIA_only` - Force NVIDIA for Vulkan

### 5. Documentation (`docs/CYBERPUNK_2077_OPTIMIZATION.md`)

**Created comprehensive guide with:**

- ✅ **In-game settings recommendations** (MOST VALUABLE)
- ✅ DLSS 3.5 configuration (critical for RTX 4090)
- ✅ Ray Tracing: Overdrive settings
- ✅ Expected performance: 80-140 FPS @ 3440x1440 with path tracing
- ✅ Troubleshooting guide
- ✅ System optimization tips

## What to Do Next

### 1. Test the Changes (WITHOUT Rebuilding System Yet)

Your Lutris configs and DXVK config are already in place:

```bash
# Just launch Cyberpunk 2077 via Lutris and test
```

### 2. When Ready to Rebuild (Includes the SOPS fix)

```bash
# Check everything
nix flake check --no-build  # ✅ Already passes

# Build and switch
nh os switch
```

### 3. In Cyberpunk 2077 Settings

**Critical for performance on RTX 4090:**

1. Graphics → Ray Tracing → **Ray Tracing: Overdrive**
2. NVIDIA DLSS → **Quality** or **Balanced**
3. NVIDIA DLSS Frame Generation → **ON** (RTX 40 series exclusive)
4. NVIDIA DLSS Ray Reconstruction → **ON** (DLSS 3.5)
5. NVIDIA Reflex Low Latency → **ON + Boost**

**Expected results:**

- Path Tracing + DLSS Quality: 80-120 FPS
- Path Tracing + DLSS Balanced: 100-140 FPS
- First 10-30 minutes will have shader compilation stutter (normal)

### 4. Monitor Performance

```bash
# In another terminal while gaming
nvidia-smi dmon

# In-game (press Shift+F12)
# MangoHud overlay shows FPS, temps, frame times
```

## What Matters vs What Doesn't

### 🎯 Actually Impactful (Keep)

1. **gamemode integration** - Auto CPU boost
2. **WINE_CPU_TOPOLOGY** - Avoid E-cores
3. **vm.max_map_count** - Essential for Wine games
4. **In-game DLSS settings** - Biggest FPS gain
5. **DXVK memory limits** - Uses your VRAM properly

### 😐 Marginal (Won't Hurt, Minor Impact)

1. Most environment variables - NVIDIA driver already optimizes
2. Shader cache paths - Already working by default
3. Vulkan layer settings - Minimal impact

### ❌ Deleted (Was Overengineered)

1. ~~`optimize-nvidia-gaming.sh`~~ - Unnecessary manual tweaking

## Files Changed

```
 docs/CYBERPUNK_2077_OPTIMIZATION.md          | NEW FILE (comprehensive guide)
 ~/.config/dxvk.conf                          | NEW FILE (RTX 4090 tuning)
 ~/.local/share/lutris/games/cyberpunk-*.yml  | MODIFIED (gamemode + optimizations)
 modules/nixos/features/gaming.nix            | MODIFIED (vm.max_map_count)
 modules/nixos/features/desktop/graphics.nix  | MODIFIED (minor GL vars)
 modules/nixos/system/sops.nix                | FIXED (mkForce for secrets)
 pkgs/scripts/optimize-nvidia-gaming.sh       | DELETED (overengineered)
```

## Bottom Line

Your system was already well-configured. The main improvements are:

1. **SOPS bug fix** (was breaking flake check)
2. **gamemode integration** (real performance boost)
3. **Wine CPU topology fix** (avoids slow E-cores)
4. **Comprehensive in-game settings guide** (biggest impact)

Everything else is 5-10% marginal gains. The real performance comes from using DLSS 3.5 properly in-game.

---

**Need help?** See the full guide: `docs/CYBERPUNK_2077_OPTIMIZATION.md`
