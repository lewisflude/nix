# Steam Gaming Guide

Comprehensive guide for getting the most out of Steam gaming on NixOS with this configuration.

## Configuration Overview

This configuration provides a high-performance gaming setup with:

- **Steam** with Proton-GE for enhanced Windows game compatibility
- **GameMode** for automatic performance optimizations when games launch
- **Ananicy-cpp** with CachyOS rules for intelligent process prioritization
- **Gamescope** for HDR, FSR, and frame limiting
- **Shader pre-compilation** optimized for multi-core CPUs
- **Performance CPU governor** to eliminate input lag
- **vm.max_map_count** set to 2147483642 for modern games

## Launch Options

Steam launch options let you customize how games start. Access them by right-clicking a game → Properties → General → Launch Options.

### Pattern Syntax

Steam uses `%command%` as a placeholder for the actual game executable:

- **Arguments only**: `-foo -bar`
- **Environment variables**: `FOO=bar %command%`
- **Wrapper command**: `gamescope -W 1920 -H 1080 -- %command%`
- **Multiple wrappers**: `gamescope -- mangohud %command%`

### Common Launch Options

#### Performance Monitoring

```bash
# MangoHud overlay (FPS, CPU, GPU, temps)
MANGOHUD=1 %command%

# MangoHud with custom config
MANGOHUD_CONFIG=preset=3 %command%

# GameMode (automatic performance boost)
# Note: Enabled by default in this config, but can force:
gamemoderun %command%
```

#### Gamescope (Wayland/HDR/FSR)

```bash
# Basic gamescope wrapper
gamescope -- %command%

# Upscaling with FSR (render at 1080p, display at 1440p)
gamescope -W 2560 -H 1440 -w 1920 -h 1080 -F fsr -- %command%

# Frame limiter (useful for reducing heat/noise)
gamescope -r 60 -- %command%

# Borderless fullscreen
gamescope -f -- %command%

# HDR on supported displays
gamescope --hdr-enabled -- %command%
```

#### Proton/Wine Tweaks

```bash
# Force specific Proton version (also available in Properties → Compatibility)
PROTON_VERSION=GE-Proton8-25 %command%

# Enable DXVK HUD (Vulkan translation layer stats)
DXVK_HUD=fps,devinfo,memory %command%

# Force Proton to use WineD3D instead of DXVK (for troubleshooting)
PROTON_USE_WINED3D=1 %command%

# Enable Proton debug logging
PROTON_LOG=1 %command%
```

#### Graphics API Selection

```bash
# Force Vulkan (some games support both DX and Vulkan)
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/your_driver.json %command%

# AMD GPU specific optimizations
AMD_VULKAN_ICD=RADV %command%
RADV_PERFTEST=sam %command%  # Enable Smart Access Memory

# NVIDIA GPU specific
__GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1 %command%  # Keep shader cache
```

#### Audio Fixes

```bash
# Force PulseAudio (if PipeWire has issues)
PULSE_LATENCY_MSEC=60 %command%

# Force specific audio device
SDL_AUDIODRIVER=pipewire %command%
```

#### Input/Controller

```bash
# Disable Steam Input (use native controller support)
# Right-click game → Properties → Controller → Disable Steam Input

# SDL controller mapping
SDL_GAMECONTROLLERCONFIG="..." %command%
```

### Game-Specific Examples

#### Star Citizen (requires high map_count - already configured)

```bash
# No special launch options needed, vm.max_map_count is set correctly
%command%
```

#### Cyberpunk 2077 (better performance with DXVK async)

```bash
DXVK_ASYNC=1 %command%
```

#### Elden Ring (better frame pacing)

```bash
gamescope -r 60 -f -- %command%
```

## Steam Input

Steam Input provides advanced controller customization and works with any controller (Xbox, PlayStation, Nintendo, etc.).

### Enabling Steam Input

1. Go to **Steam → Settings → Controller**
2. Toggle **Enable Steam Input** for your controller type
3. Per-game: Right-click game → Properties → Controller → Override

### When to Use Steam Input

**Enable for:**
- Games without native controller support (keyboard/mouse only)
- Customized button mappings (e.g., Nintendo layout on Xbox controller)
- Games requiring Steam Input API (Among Us, some indie games)
- Steam Deck UI controls

**Disable for:**
- Games with excellent native controller support
- Competitive games where input lag matters
- Third-party launchers that don't recognize Steam controllers

### Configuration

Access configurator: Right-click game → Manage → Controller Configuration

**Features:**
- Button remapping and custom layouts
- Action sets (switch layouts based on context)
- Gyro aiming support
- Radial menus for complex inputs
- Per-game profiles with cloud sync

### Desktop Profile Issue

**Problem:** Steam Input creates an Xbox 360 controller that takes precedence, breaking non-Steam games.

**Solution:** Configure desktop profile to pass through inputs:
1. Steam → Settings → Controller → Desktop Layout
2. Select "Gamepad" template
3. Or create action set that activates on Start button hold

## Proton and Windows Games

### Proton Versions

This config includes:
- **Proton (official)** - Valve's maintained version
- **Proton-GE** - Community version with more codecs and game fixes

### Forcing Proton Version

Right-click game → Properties → Compatibility → "Force the use of a specific Steam Play compatibility tool"

### Proton Compatibility Database

Check game compatibility at [ProtonDB](https://www.protondb.com/)

### Installing Media Foundation Codecs

Some games need Windows media codecs for videos:

```bash
# Use the included helper script
install-mf-codecs <STEAM_APP_ID>

# Find App ID: right-click game → Properties, or check steamapps/
```

### Protontricks

Install Windows software into game prefixes:

```bash
# Install DirectX runtime
protontricks 271590 d3dx9

# Install .NET Framework
protontricks 271590 dotnet48

# Launch winetricks GUI
protontricks 271590 --gui
```

## Directory Structure

### Steam Installation

- **Steam root**: `~/.local/share/Steam` (also symlinked at `~/.steam/root`)
- **Games**: `~/.steam/root/steamapps/common/`
- **Game configs**: `~/.steam/root/steamapps/compatdata/<AppID>/pfx/`
- **Proton versions**: `~/.steam/root/steamapps/common/Proton*`

### Library Folders

Add additional drives: Steam → Settings → Storage → (+) Add Drive

**Supported filesystems:**
- **Ext4** - Best for Linux (recommended)
- **Btrfs** - Good, but shared libraries between Windows/Linux can cause issues
- **XFS** - Good performance
- **NTFS** - Works but discouraged (corruption issues, case sensitivity problems)
- **exFAT** - Case-insensitive issues
- **UDF (rev 2.01)** - Cross-platform compatible

## Performance Optimizations

### Already Configured

✅ **Shader pre-compilation** uses all 16 CPU cores (Jupiter)
✅ **HTTP2 disabled** for potentially faster downloads
✅ **GameMode** automatically boosts performance
✅ **Ananicy-cpp** prioritizes game processes
✅ **Performance CPU governor** for lowest latency
✅ **vm.max_map_count** set to 2147483642
✅ **High file descriptor limit** for ESYNC
✅ **irqbalance disabled** (causes stuttering)

### Additional Optimizations

#### Disable Overlays

Overlays can impact performance:
- Steam → Settings → In-Game → Disable Steam Overlay (per-game basis)
- Discord hardware acceleration

#### Shader Cache Location

Keep shader cache on fast SSD (default):
```
~/.steam/root/steamapps/shadercache/
```

#### Frame Time Consistency

Use MangoHud to check 1% and 0.1% lows, not just average FPS.

## Troubleshooting

### Diagnostic Script

Run the comprehensive gaming setup diagnostic:

```bash
./scripts/diagnostics/check-gaming-setup.sh
```

This checks:
- Steam installation and configuration
- Kernel parameters (vm.max_map_count)
- CPU governor and performance settings
- GameMode and Ananicy-cpp status
- Vulkan and graphics drivers
- Proton-GE installation
- Steam Input and uinput access
- Network optimizations
- Security settings that may break games

### Game Won't Launch

1. **Check ProtonDB** for known issues and workarounds
2. **Try different Proton version** (Proton-GE often fixes issues)
3. **Check logs**: `~/.steam/root/logs/`
4. **Verify game files**: Right-click → Properties → Local Files → Verify

### Poor Performance

1. **Enable GameMode**: Should activate automatically
2. **Check CPU governor**: Should be "performance"
   ```bash
   cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
   ```
3. **Monitor with MangoHud**: `MANGOHUD=1 %command%`
4. **Check for thermal throttling**: `sensors` or `htop`

### Controller Not Working

1. **Check Steam Input settings**: Steam → Settings → Controller
2. **Try toggling Steam Input** for the game (Properties → Controller)
3. **Check udev rules**: User should be in `steam` group
   ```bash
   groups $USER | grep steam
   ```

### Audio Issues

1. **Check PipeWire status**: `systemctl --user status pipewire`
2. **Try PulseAudio compatibility**: `PULSE_LATENCY_MSEC=60 %command%`
3. **Check game audio settings** in-game

### Crash on Launch with Easy Anti-Cheat

Some EAC games require:
- Developer must enable Proton EAC support
- Ensure `hidepid` is not set (breaks EAC)
- Check [AreWeAntiCheatYet](https://areweanticheatyet.com/)

## VR Gaming

This config includes comprehensive VR support for Quest 3 via WiVRn.

See:
- `docs/VR_SETUP_GUIDE.md` - Complete VR setup
- `modules/nixos/features/vr/` - VR configuration modules

### Steam VR

The gaming module includes a patched bubblewrap that grants capabilities needed for VR. This removes some sandboxing security.

## Advanced Performance Optimizations

### Immediate Symbol Resolution (LD_BIND_NOW)

Loading shared objects immediately improves first-call latency by avoiding runtime symbol resolution.

**Steam Launch Option:**
```bash
env LD_BIND_NOW=1 %command%
```

**Benefits:**
- Eliminates delay when a function is called for the first time
- More consistent frame times during gameplay
- Particularly helpful for games with lots of dynamically loaded libraries

**Caveats:**
- Slightly longer initial startup time
- May cause crashes if the game links non-existent libraries (rare, usually only affects broken packages)
- Most games packaged correctly will benefit from this

### Disable VSync at Driver Level (DRI vblank)

Disabling vsync at the DRI level reduces input latency for games that don't expose vsync controls.

**Configuration:**

Create or edit `~/.drirc`:

```xml
<driconf>
  <device>
    <application name="Default">
      <option name="vblank_mode" value="0" />
    </application>
  </device>
</driconf>
```

**What this does:**
- Disables synchronization to vertical blank at the OpenGL/Vulkan driver level
- Reduces input latency by allowing immediate frame presentation
- Applies to all DRI-based graphics (Mesa, Nouveau, etc.)

**When to use:**
- Competitive gaming where input latency matters more than screen tearing
- When you use an external frame limiter (gamescope, MangoHud, in-game cap)
- High refresh rate monitors (120Hz+) where tearing is less noticeable

**Alternative per-game method:**

```bash
# Disable vblank for specific game
vblank_mode=0 %command%
```

### Combined Example

For maximum performance:

```bash
env LD_BIND_NOW=1 vblank_mode=0 MANGOHUD=1 gamemoderun %command%
```

This combines:
- Immediate symbol resolution
- Disabled VSync
- Performance monitoring
- Automatic CPU/GPU performance boost

## Additional Tools

### Included

- **steamcmd** - Command-line Steam client
- **steam-run** - Run non-Steam games in Steam runtime
- **protonup-qt** - GUI for installing compatibility tools (Luxtorpeda, Boxtron, etc.)

### Installing Additional Compatibility Tools

```bash
# Open protonup-qt
protonup-qt

# Install Luxtorpeda (native Linux engines)
# Install Boxtron (native DOSBox)
# Install other Proton-GE versions
```

Then select in game properties → Compatibility.

## Security Considerations

### Bubblewrap Patch

**Warning:** This config patches bubblewrap to grant ALL capabilities for VR support. This removes security sandboxing.

- Required for WiVRn and SteamVR
- Affects all Steam games
- Consider implications for untrusted games

### uinput Access

Steam Input requires `/dev/uinput` access. This config restricts it to the `steam` group instead of all logged-in users.

**Why:** Default udev rules grant access to all logged-in users, which can allow sandbox escape.

## References

- [Arch Wiki: Steam](https://wiki.archlinux.org/title/Steam)
- [ProtonDB](https://www.protondb.com/) - Game compatibility database
- [AreWeAntiCheatYet](https://areweanticheatyet.com/) - Anti-cheat compatibility
- [PCGamingWiki](https://www.pcgamingwiki.com/) - Game-specific fixes
- [Steam Input Documentation](https://partner.steamgames.com/doc/features/steam_controller)
