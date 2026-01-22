# Chrome/Chromium Optimization Guide

This guide documents Chrome/Chromium performance optimizations implemented in this NixOS configuration, based on [Arch Wiki - Chromium](https://wiki.archlinux.org/title/Chromium).

## Configuration Location

Chrome flags are configured in `home/nixos/browser.nix` and deployed to `~/.config/chrome-flags.conf`.

## Active Optimizations

### Hardware Video Acceleration (VA-API)

**Flags:**
```
--enable-features=AcceleratedVideoDecodeLinuxGL,AcceleratedVideoEncoder,VaapiOnNvidiaGPUs
```

**Purpose:** Enable GPU-accelerated video decoding and encoding for reduced CPU usage during video playback.

**NVIDIA-Specific:** Jupiter uses an RTX 4090, which requires:
- The `VaapiOnNvidiaGPUs` feature flag
- The `nvidia-vaapi-driver` package (already configured in `modules/nixos/features/desktop/graphics.nix`)
- The `libva-vdpau-driver` for fallback support

**Verify it's working:**
1. Visit `chrome://gpu/` 
2. Check "Video Acceleration Information" section
3. Look for "Decode" entries showing hardware acceleration

**Test with video:**
1. Play a YouTube video (720p or higher)
2. Press `Shift+ESC` to open Chrome Task Manager
3. Open DevTools (`Ctrl+Shift+I`) → Media tab
4. Verify "Hardware video decoder" is active

**Note:** Chrome only accelerates videos larger than 720p by default.

### GPU Acceleration

**Flags:**
```
--ignore-gpu-blocklist
--enable-zero-copy
--enable-gpu-rasterization
```

**Purpose:** Force GPU acceleration even if your hardware is blocklisted, reduce memory copies, and use GPU for page rendering.

**Verify:**
- Visit `chrome://gpu/`
- Graphics Feature Status should show "Hardware accelerated" (green)

**Warning:** `--ignore-gpu-blocklist` may cause instability on some systems. If you experience crashes, remove this flag.

### Wayland Support

**Flags:**
```
--ozone-platform-hint=auto
--enable-wayland-ime
```

**Purpose:** Use native Wayland when available, falling back to Xorg automatically. Enables proper input method support.

**Verify:**
- On Wayland session: `chrome://version/` should show `--ozone-platform=wayland`
- On Xorg session: Should show X11

### High Refresh Rate Support

**Flags:**
```
--use-gl=egl
```

**Purpose:** Essential for proper high refresh rate display support, especially with mixed refresh rates (e.g., 60Hz + 144Hz).

**For Jupiter gaming setup:** This ensures Chrome renders at your monitor's full refresh rate, not locked to 60 FPS.

**Test:**
- Visit [testufo.com](https://www.testufo.com/)
- Verify smooth animation at your display's refresh rate

### Performance Optimizations

**Flags:**
```
--enable-parallel-downloading
--disk-cache-dir=/run/user/1000/chrome-cache
```

**Purpose:**
- Parallel downloading: Split downloads into multiple connections for faster speeds
- tmpfs cache: Store cache in RAM (`/run/user/1000/` is tmpfs) to reduce disk I/O and improve responsiveness

**Benefits for gaming:**
- Faster game-related downloads (patches, mods, guides)
- Reduced SSD wear from constant cache writes
- No cache buildup (cleared on reboot)

### Password Store Consistency

**Flag:**
```
--password-store=gnome-libsecret
```

**Purpose:** Force Chrome to use GNOME Keyring via libsecret, preventing password loss when switching desktop environments or window managers.

**Related error:** `Failed to decrypt token for service AccountId-*`

## Verification Commands

### Check if flags are loaded
```bash
cat ~/.config/chrome-flags.conf
```

### Check Chrome's active command line
```bash
chrome://version/
```
Look at the "Command Line" section - your flags should be listed there.

### Check GPU status
```bash
chrome://gpu/
```

### Monitor video acceleration
```bash
# Watch for VA-API usage
watch -n 1 'grep -E "VaAPI|vaapi" /proc/$(pidof chrome)/maps | wc -l'
```

### Check hardware video decode in use
```bash
# Play a 1080p YouTube video, then:
intel_gpu_top  # For Intel GPUs
radeontop      # For AMD GPUs
nvidia-smi -l 1  # For NVIDIA GPUs
```
You should see Video Engine usage increase during playback.

## Gaming-Specific Benefits

### Reduced CPU Usage
- Hardware video decoding frees up CPU for games
- Important when watching streams/videos while gaming

### Faster Downloads
- Parallel downloading speeds up game-related content
- Mods, patches, guides, etc.

### Better Multi-Monitor Experience
- High refresh rate support for mixed refresh rate setups
- Proper rendering on gaming monitor (144Hz) vs secondary (60Hz)

### Memory Efficiency
- tmpfs cache reduces memory pressure from disk I/O
- Cache auto-cleared on reboot (no bloat)

## Troubleshooting

### Chrome crashes after enabling GPU acceleration

**Solution:** Remove `--ignore-gpu-blocklist` flag:

```nix
# In home/nixos/browser.nix, comment out:
# "--ignore-gpu-blocklist"
```

### Video acceleration not working

**Check VA-API driver:**
```bash
vainfo
```

Should show supported profiles. If not, ensure you have the correct VA-API driver:
- AMD: `mesa` (included by default)
- Intel (newer): `intel-media-driver` 
- Intel (older): `libva-intel-driver`
- NVIDIA: `nvidia-vaapi-driver` (configured for Jupiter)

**For NVIDIA on Jupiter (RTX 4090):**
```bash
# Verify NVIDIA driver is loaded
nvidia-smi

# Check VA-API support
vainfo
# Should show: "VA-API version: X.X.X (libva X.X.X)"
# And profiles for H264, HEVC, etc.

# Verify Chrome is using NVIDIA GPU
nvidia-smi dmon -s u
# Run this while playing a video - you should see decode (dec) usage
```

**Expected vainfo output with NVIDIA:**
```
VAProfileH264Main               : VAEntrypointVLD
VAProfileH264High               : VAEntrypointVLD
VAProfileHEVCMain               : VAEntrypointVLD
VAProfileHEVCMain10             : VAEntrypointVLD
```

### Wayland input methods not working

**Try alternative flag combination:**
```nix
# Replace --enable-wayland-ime with:
"--gtk-version=4"
```

Or for fcitx5 users:
```nix
"--enable-wayland-ime"
"--wayland-text-input-version=3"
```

### High DPI/scaling issues on Wayland

**Add scaling flags:**
```nix
"--force-device-scale-factor=1.5"  # Adjust value as needed
"--enable-features=WaylandPerSurfaceScale,WaylandUiScale"
```

### AltGr/Compose key not working

**Add workaround:**
```nix
"--disable-gtk-ime"
```

### Chrome not rendering at full refresh rate

**Verify flags are active:**
1. Check `chrome://gpu/` shows hardware acceleration
2. Ensure compositor (Niri) is also at high refresh rate:
   ```bash
   # Check current refresh rate
   niri msg outputs
   ```

**Additional flags for mixed refresh rates:**
```nix
"--ignore-gpu-blocklist"
"--enable-gpu-rasterization"
```

## Additional Optimizations (Optional)

### Reduce memory usage

**Process model optimization:**
```nix
# Share one process per site (instead of per-tab)
"--process-per-site"
```

**Warning:** Reduces isolation between tabs. Not recommended for security-sensitive usage.

### Extensions for memory management
- Tab Suspender - Auto-suspend inactive tabs
- OneTab - Store tabs in list format

### Disable JIT for security (performance cost)

```nix
"--js-flags=--jitless"
```

Disables JavaScript JIT compilation, eliminating ~50% of JS engine vulnerabilities at the cost of slower JavaScript execution.

### Canvas fingerprinting protection

```nix
"--disable-reading-from-canvas"
```

**Warning:** May break some sites (YouTube player, Google Maps).

### Force specific GPU (multi-GPU systems)

```bash
# Find GPU PCI addresses
ls -l /dev/dri/by-path/

# Then add flag:
"--render-node-override=/dev/dri/by-path/pci-0000:01:00.0-render"
```

Useful if Chrome picks the wrong GPU (e.g., iGPU instead of dGPU).

## Testing Methodology

### Video Acceleration Test
1. Open YouTube in Chrome
2. Play 1080p video
3. Open DevTools → Media tab
4. Verify "Hardware video decoder" is "true"
5. Check CPU usage in `htop` - should be minimal

### Download Speed Test
1. Download a large file (e.g., Linux ISO)
2. Watch network usage in Chrome Task Manager
3. Should see multiple connections in use

### Refresh Rate Test
1. Visit [testufo.com](https://www.testufo.com/)
2. Should show smooth animation at your display's Hz
3. No judder or tearing

## References

- [Arch Wiki - Chromium](https://wiki.archlinux.org/title/Chromium)
- [Chromium Command Line Switches](https://peter.sh/experiments/chromium-command-line-switches/)
- [Chromium VA-API Documentation](https://chromium.googlesource.com/chromium/src/+/master/docs/gpu/vaapi.md)
- [Hardware Video Acceleration (Arch Wiki)](https://wiki.archlinux.org/title/Hardware_video_acceleration)

## Integration with This Config

Chrome configuration integrates with:
- **GNOME Keyring** (`modules/shared/features/gnome-keyring.nix`) - Password storage
- **Mesa/VA-API** (`modules/nixos/features/desktop/graphics.nix`) - Hardware acceleration
- **Gaming optimizations** (`modules/nixos/features/gaming.nix`) - System-level GPU setup
- **Niri compositor** (`home/nixos/niri/`) - Wayland environment

All optimizations are automatically applied on system rebuild.
