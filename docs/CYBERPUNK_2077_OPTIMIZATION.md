# Cyberpunk 2077 Performance Optimization Guide

## System Specifications

- **CPU**: Intel i9-13900K (24 cores: 8 P-cores + 16 E-cores)
- **GPU**: NVIDIA RTX 4090 (24GB VRAM)
- **RAM**: 64GB
- **Display**: 3440x1440 @ 165Hz (Ultrawide)
- **OS**: NixOS with RT kernel

## Applied Optimizations

### 1. Lutris Configuration (`~/.local/share/lutris/games/cyberpunk-2077-*.yml`)

#### DXVK Optimizations

- **DXVK_ASYNC**: Enabled for reduced shader compilation stutter
- **DXVK_CONFIG_FILE**: Points to custom config with RTX 4090 tuning
- **DXVK_HUD**: Set to `compiler` to monitor shader compilation
- **DXVK_LOG_LEVEL**: Set to `none` for reduced overhead

#### VKD3D-Proton (DirectX 12 & Ray Tracing)

- **VKD3D_CONFIG**: `dxr11,dxr` - Enables DXR ray tracing
- **VKD3D_FEATURE_LEVEL**: `12_2` - Full DirectX 12.2 support
- **VKD3D_DEBUG**: `none` - Minimal logging overhead

#### NVIDIA RTX 4090 Specific

- **__GL_THREADED_OPTIMIZATIONS**: Enabled for better CPU utilization
- **__GL_SHADER_DISK_CACHE**: Persistent shader cache across sessions
- **__GL_SHADER_DISK_CACHE_SKIP_CLEANUP**: Prevents cache deletion
- **__GL_MaxFramesAllowed**: `1` - Minimum input latency
- **__GL_SYNC_TO_VBLANK**: `0` - Let gamescope handle VSync
- **PROTON_ENABLE_NVAPI**: Full NVIDIA API support
- **PROTON_ENABLE_NGX_UPDATER**: DLSS 3.5 support

#### CPU Optimizations

- **WINE_CPU_TOPOLOGY**: `8:0` - Binds to 8 P-cores (avoids E-cores)
- **gamemode**: Enabled - Automatic CPU governor switching

#### Memory Optimizations

- **PROTON_FORCE_LARGE_ADDRESS_AWARE**: Uses full 64GB RAM
- **WINE_HEAP_DELAY_FREE**: Better memory management

#### Audio

- **PULSE_LATENCY_MSEC**: `60` - Balanced latency for PipeWire

#### Gamescope Settings

```
-w 3440 -h 1440          # Native resolution
-W 3440 -H 1440          # Window size
-r 165 -f                # 165Hz fullscreen
--adaptive-sync          # G-SYNC/VRR support
--force-grab-cursor      # Proper cursor capture
--hdr-enabled            # Enable HDR
--hdr-itm-enable         # HDR tone mapping
```

### 2. DXVK Configuration (`~/.config/dxvk.conf`)

#### Memory Settings (RTX 4090)

- **maxDeviceMemory**: 22528 MB (22GB) - Leaves 2GB for system
- **maxSharedMemory**: 16384 MB (16GB) - Ample for texture streaming

#### Performance Settings

- **asyncPresent**: Enabled - Reduces input latency
- **useRawSsbo**: Enabled - Better NVIDIA performance
- **syncInterval**: 0 - Let gamescope handle frame pacing
- **maxFrameLatency**: 1 - Minimum latency
- **numCompilerThreads**: 8 - Uses P-cores for shader compilation

#### Caching

- **useStateCache**: Enabled - Faster subsequent launches

### 3. System-Level Optimizations

#### Already Configured in NixOS

- **RT Kernel** (6.6.30-rt30): Low-latency gaming
- **FSYNC/ESYNC**: File descriptor limit: 1,048,576
- **GameMode**: Automatic CPU governor tuning
- **Ananicy-cpp**: Process priority management
- **Graphics**: 32-bit Vulkan drivers enabled

## In-Game Settings Recommendations

### Graphics Settings (RTX 4090 @ 3440x1440)

#### Basic

- **Resolution**: 3440x1440
- **Display Mode**: Fullscreen
- **VSync**: OFF (handled by gamescope)
- **Frame Rate Limit**: 165 FPS
- **HDR**: ON (if display supports it)

#### Graphics Quality

- **Quick Preset**: Custom (RTX Overdrive)
- **Texture Quality**: High
- **Field of View**: 90-100 (preference)
- **Film Grain**: OFF (performance + clarity)
- **Chromatic Aberration**: OFF (performance + clarity)
- **Depth of Field**: ON (preference)
- **Lens Flare**: ON (preference)
- **Motion Blur**: OFF (preference)

#### Advanced

- **Contact Shadows**: ON
- **Improved Facial Lighting Geometry**: ON
- **Anisotropy**: 16x
- **Local Shadow Mesh Quality**: High
- **Local Shadow Quality**: High
- **Cascaded Shadows Range**: High
- **Cascaded Shadows Resolution**: High
- **Distant Shadows Resolution**: High
- **Volumetric Fog Resolution**: High
- **Volumetric Cloud Quality**: High
- **Max Dynamic Decals**: Ultra
- **Screen Space Reflections Quality**: High
- **Subsurface Scattering Quality**: High
- **Ambient Occlusion**: High
- **Color Precision**: High
- **Mirror Quality**: High
- **Level of Detail**: High

#### Ray Tracing (RTX Path Tracing)

- **Ray Tracing**: ON
- **Ray Tracing Mode**: Ray Tracing: Overdrive
- **Ray-Traced Lighting**: ON
- **Ray-Traced Reflections**: ON
- **Ray-Traced Sun Shadows**: ON
- **Ray-Traced Local Shadows**: ON

#### DLSS 3.5 (CRITICAL FOR PERFORMANCE)

- **NVIDIA DLSS**: Quality or Balanced
- **DLSS Frame Generation**: ON (RTX 40 series exclusive)
- **DLSS Ray Reconstruction**: ON (DLSS 3.5 feature)
- **Reflex Low Latency**: ON + Boost

### Expected Performance

With these settings, you should achieve:

- **Path Tracing + DLSS Quality**: 80-120 FPS
- **Path Tracing + DLSS Balanced**: 100-140 FPS
- **Path Tracing + DLSS Performance**: 120-165 FPS

## Troubleshooting

### Shader Compilation Stuttering

If you experience stuttering during the first 10-30 minutes:

1. This is normal - DXVK is compiling shaders asynchronously
2. Monitor with `DXVK_HUD=compiler` (already enabled)
3. After first playthrough, shader cache is built
4. Consider pre-compiling by visiting diverse game areas

### Performance Drops

1. Check if gamemode is active: `gamemoded -s`
2. Verify CPU frequency: `watch -n1 "cat /proc/cpuinfo | grep MHz"`
3. Check GPU usage: `nvidia-smi dmon`
4. Monitor with MangoHud (already enabled)

### DLSS Not Available

1. Ensure game is fully updated to 2.1+
2. Verify `PROTON_ENABLE_NGX_UPDATER=1` is set
3. Check NVIDIA driver version: `nvidia-smi` (should be 545.29.02+)
4. Try toggling DLSS off and on in-game

### Audio Crackling

1. Adjust `PULSE_LATENCY_MSEC` in config (currently 60)
2. Lower values = more responsive, higher values = more stable
3. Try: 30, 60, 90, 120

### HDR Issues

1. Ensure monitor supports HDR
2. Verify gamescope HDR flags are present
3. Check `ENABLE_HDR_WSI=1` is set
4. Some HDR monitors need manual calibration in-game

## Additional Performance Tips

### 1. Storage Optimization

- Install game on NVMe SSD (fastest load times)
- ZFS users: Consider disabling compression for game directory

  ```bash
  sudo zfs set compression=off pool/path/to/games
  ```

### 2. NVIDIA Driver Settings

The following are already optimized via system config, but for reference:

- Power Management Mode: Prefer Maximum Performance
- Threaded Optimization: On
- Shader Cache Size: Unlimited

### 3. Wine/Proton Version

Recommended runners in Lutris:

1. **GE-Proton** (Latest) - Best compatibility and performance
2. **Proton Experimental** - Bleeding edge features
3. **Wine-GE** - Alternative for GOG version

To install in Lutris:

1. Open Lutris
2. Click hamburger menu → Manage runners
3. Install "Wine-GE" or "Proton-GE"
4. Right-click Cyberpunk 2077 → Configure → Runner options
5. Select newest GE-Proton runner

### 4. Monitor Game Performance

Enable MangoHud (already configured):

- Press `Shift+F12` in-game to toggle overlay
- Shows FPS, GPU/CPU usage, temperatures, frame times

Custom MangoHud config (optional):

```bash
# ~/.config/MangoHud/MangoHud.conf
fps_limit=165
vsync=0
fps
gpu_stats
cpu_stats
vram
ram
frame_timing=1
engine_version
vulkan_driver
```

### 5. Pre-Game Launch

For maximum performance:

```bash
# Close unnecessary applications
# Ensure gamemode is installed (already is via NixOS config)
# Launch via Lutris desktop entry (uses systemd wrapper with proper limits)
```

## Maintenance

### Clear Shader Caches (if experiencing issues)

```bash
rm -rf ~/.cache/dxvk/*
rm -rf ~/.cache/vkd3d-proton/*
rm -rf ~/.cache/nvidia-shader/*
```

### Update Wine/Proton Runner

Regularly check for updates in Lutris:

```bash
# In Lutris GUI
Hamburger menu → Manage runners → Check for updates
```

### Verify File Integrity (GOG)

If game crashes or has visual artifacts:

```bash
# In GOG Galaxy or via Lutris installer
# Run "Verify/Repair" option
```

## References

- [DXVK Documentation](https://github.com/doitsujin/dxvk)
- [VKD3D-Proton](https://github.com/HansKristian-Work/vkd3d-proton)
- [Lutris Wiki](https://github.com/lutris/docs)
- [ProtonDB - Cyberpunk 2077](https://www.protondb.com/app/1091500)

## Changelog

- **2025-12-11**: Initial optimization for RTX 4090 + i9-13900K system
  - Added DXVK config with memory tuning
  - Enabled gamemode integration
  - Configured CPU P-core affinity
  - Added NVIDIA-specific optimizations
  - Enhanced gamescope HDR configuration
