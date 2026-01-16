# VR Setup Guide (WiVRn + OpenXR + Virtual Monitors)

**Last Updated**: 2026-01-12
**System**: NixOS with WiVRn wireless VR streaming + Immersed productivity
**Headset**: Meta Quest 3

---

## Overview

This system uses:

- **WiVRn** for wireless VR gaming and experiences
- **Immersed** for VR desktop productivity with virtual monitors
- **Virtual Monitors** via hardware adapters for Wayland compatibility

The standalone system Monado service is disabled as WiVRn includes its own embedded Monado runtime optimized for streaming.

## Architecture

```
Quest Headset
    ↓ (WiFi)
WiVRn Server (with embedded Monado)
    ↓ (OpenXR)
    ├─ WayVR Desktop Overlay (auto-starts)
    └─ Steam Games (via pressure-vessel container)
```

**Key Points:**

- ✅ WiVRn handles both streaming AND the OpenXR runtime
- ✅ WayVR auto-starts when WiVRn connects (systemd service)
- ❌ Standalone Monado service is disabled (redundant and incompatible with Niri)
- ✅ OpenXR games work directly (no SteamVR needed)

### Services

| Service | Status | Purpose |
|---------|--------|---------|
| `wivrn.service` | Auto-start (enabled) | Wireless VR streaming to Quest 3 |
| `wayvr.service` | Auto-start (bound to wivrn) | Desktop overlay in VR |
| `monado.service` | Disabled | Standalone runtime (not needed with WiVRn) |

---

## Configuration

### System Config (`hosts/jupiter/default.nix`)

```nix
vr = {
  enable = true;
  monado = false;  # Not needed - WiVRn has embedded Monado
  wivrn = {
    enable = true;
    autoStart = true;
    defaultRuntime = true;  # Sets WiVRn as OpenXR runtime
    openFirewall = true;
  };
  immersed = {
    enable = true;  # VR desktop productivity
    openFirewall = true;
  };
  virtualMonitors = {
    enable = true;  # Hardware-based virtual monitors for Immersed
    method = "hardware";  # Using dummy HDMI/DP adapters
    hardwareAdapterCount = 3;  # Number of dummy adapters plugged in
    defaultResolution = "3840x1600";  # Ultra-wide for VR productivity
    diagnosticTools = true;  # Install lspci, wlr-randr
  };
  opencomposite = true;  # For OpenVR games (converts to OpenXR)
  steamvr = false;  # Not needed on Wayland
};
```

### Services Status

Check WiVRn is running:

```bash
systemctl --user status wivrn
```

Should show:

- **Active**: `active (running)`
- **Ports**: 5353 (mDNS discovery), 9757 (VR streaming)

### Environment Variables

The OpenXR runtime requires the `XR_RUNTIME_JSON` environment variable to be set. This is configured automatically in `home/nixos/apps/vr.nix`:

```nix
home.sessionVariables.XR_RUNTIME_JSON = "${pkgs.wivrn}/share/openxr/1/openxr_wivrn.json";
```

**Verify it's set:**

```bash
echo $XR_RUNTIME_JSON
# Should output: /nix/store/.../share/openxr/1/openxr_wivrn.json
```

**If not set:**

1. Rebuild your home-manager configuration
2. Log out and back in (or restart your terminal)
3. Run diagnostic: `./scripts/diagnose-xrizer.sh`

**Common Error Without XR_RUNTIME_JSON:**

```
OpenVR failed to initialize with the given error:
VRInitError_Init_InterfaceNotFound
```

This error occurs when VR apps can't locate the OpenXR runtime.

---

## Virtual Monitors for Immersed (VR Productivity)

### Overview

**Immersed** allows you to work with multiple virtual monitors in VR, creating a productive mixed-reality workspace. On **Niri/Wayland**, virtual monitors require a hardware-based solution using **dummy HDMI/DisplayPort adapters**.

### Why Hardware Adapters?

| Method | X11 Support | Wayland Support | Niri Support | Reliability |
|--------|-------------|-----------------|--------------|-------------|
| **Hardware adapters** | ✅ Excellent | ✅ Excellent | ✅ Excellent | ⭐⭐⭐⭐⭐ |
| Intel VirtualHeads | ✅ Good | ❌ X11 only | ❌ No | ⭐⭐⭐ |
| Nvidia force-connect | ✅ Fragile | ❌ X11 only | ❌ No | ⭐⭐ |
| EVDI kernel module | ⚠️ Complex | ⚠️ Buggy | ❌ No | ⭐ |
| Native Wayland protocol | N/A | ✅ Gnome only | 🔜 Future | N/A |

**Recommendation:** Hardware adapters are the **cleanest, most robust solution** for all display servers.

### Hardware Setup

#### Required Hardware

- **Dummy HDMI/DisplayPort adapters** (also called "headless ghost adapters")
- **EDID chip support** for 4K resolutions (recommended)
- **Quantity:** 2-4 adapters depending on desired virtual monitors

#### Where to Buy

Search for these terms:

- "4K headless ghost adapter"
- "HDMI dummy plug 4K"
- "DisplayPort EDID emulator"

**Popular options:**

- Headless Ghost 4K (~$15 each)
- FUERAN 4K HDMI Dummy Plug (~$12 each)
- Any EDID emulator with 3840x1600+ support

**Cost:** ~$30-60 total for 2-4 adapters

#### Physical Installation

1. **Power off your system**
2. **Plug adapters** into unused HDMI/DisplayPort outputs on your **Nvidia 4090**
3. **Boot system** - adapters will be automatically detected
4. **Verify detection** with: `vr-detect-displays`

### Software Configuration

#### Enable Virtual Monitors

In `hosts/jupiter/default.nix`:

```nix
features.vr.virtualMonitors = {
  enable = true;
  method = "hardware";
  hardwareAdapterCount = 3;  # Match number of physical adapters
  defaultResolution = "3840x1600";  # Ultra-wide recommended
  diagnosticTools = true;
};
```

#### Detection and Verification

After rebuilding, run the detection script:

```bash
vr-detect-displays
```

This will show:

- ✅ Detected GPU(s)
- ✅ Display server type (Wayland/X11)
- ✅ Connected displays and outputs
- ✅ Configuration recommendations

### Wayland Display Management

#### View Connected Displays

```bash
wlr-randr
```

Example output:

```
DP-1 "Dummy-1" (connected)
  Physical size: 600x340 mm
  Enabled: yes
  Modes:
    3840x1600 px, 59.977001 Hz (current)
    1920x1080 px, 60.000000 Hz

DP-2 "Dummy-2" (connected)
  Physical size: 600x340 mm
  Enabled: yes
  ...
```

#### Configure Display Position/Resolution

Niri uses its configuration file for display management. Virtual monitors from dummy adapters appear as regular displays and can be configured like any physical monitor.

**Note:** On Niri, display configuration is declarative via `programs.niri.config`. You can position virtual monitors relative to your main display for optimal Immersed usage.

### Immersed Setup

1. **Install Immersed** on your Quest 3 (via Meta Store)
2. **Launch Immersed** on your PC (already configured in `vr.nix`)
3. **Connect** from your Quest headset
4. **Configure virtual monitors** in Immersed settings:
   - Choose which displays to show in VR
   - Arrange monitor positions
   - Set per-monitor resolution/scale

**Pro tip:** Use ultra-wide resolutions (3840x1600) for maximum screen real estate in VR.

### Troubleshooting

#### Adapters Not Detected

```bash
# Check GPU outputs
lspci | grep -i vga

# Check display connections
wlr-randr
```

If adapters aren't showing:

- Verify they're plugged into the **Nvidia 4090** outputs (not motherboard)
- Try different ports (HDMI vs DisplayPort)
- Ensure adapters have EDID chip (cheap ones may not work)

#### Wrong Resolution

Dummy adapters typically support:

- 1920x1080 @ 60Hz (basic)
- 3840x2160 @ 30Hz (4K, EDID chip required)
- 3840x1600 @ 60Hz (ultra-wide, best for VR)

If you can't get higher resolutions, your adapter may not have an EDID chip or may be faulty.

#### Immersed Can't See Displays

1. **Check Immersed is running:** `ps aux | grep immersed`
2. **Verify firewall ports:** Ports 5230-5232 (TCP/UDP) should be open
3. **Restart Immersed:** `systemctl --user restart immersed` (if using systemd service)
4. **Check detection script:** `vr-detect-displays` should show all adapters connected

### Best Practices

1. **Label your adapters** - Know which port each adapter uses
2. **Keep adapters plugged in** - Removing/reinserting may require display reconfiguration
3. **Use matching adapters** - Same model ensures consistent EDID/resolution support
4. **Ultra-wide resolutions** - 3840x1600 provides excellent VR workspace
5. **Test before VR** - Verify displays appear in `wlr-randr` before launching Immersed

### Future: Native Wayland Support

Gnome Wayland now has **native virtual display support** in Immersed (no adapters needed). Other compositors like Niri may add this in the future via the Wayland protocol extension.

When Niri gains native support, update config:

```nix
features.vr.virtualMonitors = {
  enable = true;
  method = "auto";  # Will use native protocol when available
};
```

For now, hardware adapters remain the **most reliable solution** on Niri.

---

## Audio Setup

### Overview

WiVRn creates a **virtual audio device** that routes audio to your Quest 3 headset over the network.

**Audio Device Name:** `WiVRn` (output) and `WiVRn(microphone)` (input)

### Automatic vs Manual Audio Routing

**By default**, VR games will use your **desktop speakers** unless you redirect them.

You have two options:

#### Option 1: Manual Redirect (Recommended)

**While the VR game is running**, redirect its audio:

```bash
vr-audio-fix
```

This moves the game's audio to your Quest 3 headset without affecting desktop apps.

#### Option 2: Per-Application Assignment

Use `pavucontrol` or your desktop's audio settings to permanently assign VR games to the WiVRn device:

1. Launch `pavucontrol`
2. Go to "Playback" tab
3. Find your VR game (e.g., "hlvr", "steam")
4. Select "WiVRn" from the dropdown

This setting is remembered per-application.

#### Option 3: Set WiVRn as Default (Not Recommended)

This routes **all** audio (including desktop) to your headset:

```bash
pactl set-default-sink wivrn.sink
```

**Downside:** You won't hear desktop audio on your speakers while wearing the headset.

### Microphone Setup

1. **In your Quest 3**, go to WiVRn settings
2. **Enable microphone**
3. **Grant permission** when prompted
4. The microphone appears as **"WiVRn(microphone)"** in your audio settings
5. **Assign applications** to use it (same process as output device)

### Audio Status Check

```bash
vr-audio-status  # Check if WiVRn audio device exists
pactl list sinks short  # List all audio output devices
pactl list sources short  # List all audio input devices (including mic)
```

---

## Steam VR Game Launch Options (2026 Update)

### Why Launch Options Are Needed

Steam games run inside a **pressure-vessel container** which isolates them from the host system. By default, this container cannot access the WiVRn IPC socket that enables VR communication with your Quest 3.

### Required Launch Options

For **ALL** VR games in Steam, set these launch options:

```bash
PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc %command%
```

#### What Each Part Does

| Variable | Purpose |
|----------|---------|
| `PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc` | Mounts WiVRn IPC socket for VR communication |
| `%command%` | Placeholder for game executable |

**Note:** `PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1` is automatically handled by `services.wivrn.steam.importOXRRuntimes = true` in your configuration, so you don't need to include it manually.

**Without this variable:** Game will launch in "Desktop Mode" or fail to find the headset entirely, even if WiVRn says "Connection Ready."

### Setting Launch Options

1. **In Steam Library**: Right-click game → **Properties**
2. **Under "Launch Options"**: Paste the command above
3. **Close properties window**

### Example: Half-Life: Alyx

```
Game: Half-Life: Alyx (App ID: 546560)
Launch Options:
  PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc %command%
```

### Using xrizer for SteamVR Games

For games that use **SteamVR** (OpenVR API), you can translate them to OpenXR using **xrizer**:

```bash
xrizer PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc %command%
```

**xrizer** is the modern replacement for OpenComposite and provides:

- Lower overhead for Quest 3's high resolutions
- Better Wayland/Nvidia compatibility with explicit sync
- Automatic OpenVR path management (prevents SteamVR hijacking)

Your system is configured to use xrizer by default (`opencomposite = false`).

---

## xrizer: Modern OpenVR-to-OpenXR Translation (2026)

### Why xrizer Instead of OpenComposite?

In 2026, **xrizer** has become the preferred choice for translating SteamVR (OpenVR) games to OpenXR on Linux:

**Performance Benefits:**

- Lower overhead translating OpenVR calls to OpenXR
- Crucial for Quest 3's higher resolutions (up to 2064x2208 per eye)
- Reduces encoding load on your RTX 4090

**Wayland/Nvidia Compatibility:**

- Better handling of explicit sync in modern Wayland compositors
- Works seamlessly with Nvidia's proprietary drivers
- Supports buffer sharing requirements of Plasma 6+ and Niri

**Automatic Path Management:**

- WiVRn configures `~/.config/openvr/openvrpaths.vrpath` automatically
- Prevents SteamVR from hijacking the OpenXR runtime
- No manual configuration needed

### Configuration Status

Your system is already configured to use xrizer:

```nix
# hosts/jupiter/default.nix
opencomposite = false;  # Uses xrizer by default

# modules/nixos/features/vr/wivrn.nix
openvr-compat-path = "${pkgs.xrizer}";  # Set automatically
```

### Locking OpenVR Paths (Preventing SteamVR Override)

**UPDATE:** This is now configured automatically in `home/nixos/apps/vr.nix`.

WiVRn configures `~/.config/openvr/openvrpaths.vrpath` to use xrizer, but **SteamVR can override this file** when it launches, breaking VR games.

The configuration now **locks the OpenVR paths** to ensure xrizer is always used:

```nix
# In home/nixos/apps/vr.nix (already configured)
xdg.configFile."openvr/openvrpaths.vrpath" = {
  text = builtins.toJSON {
    runtime = [
      "${pkgs.xrizer}/lib/xrizer"  # xrizer FIRST
      # SteamVR intentionally omitted
    ];
  };
  force = true;  # Prevent Steam from modifying
};
```

**Why this matters:**

- Without this, SteamVR appears first in the runtime list
- Wine/Proton games probe for OpenVR at startup
- They find SteamVR and try to use it instead of xrizer
- Result: Games fail to start or show "No headset detected"

**After rebuilding home-manager**, your `openvrpaths.vrpath` will **only** contain xrizer, forcing all OpenVR games to use OpenXR via WiVRn.

### Troubleshooting xrizer

**SteamVR Opens Instead of WiVRn:**

1. Check `~/.config/openvr/openvrpaths.vrpath` points to xrizer
2. Verify WiVRn is running: `systemctl --user status wivrn`
3. Try the locked Home Manager configuration above

**Game Crashes with xrizer:**

1. Check if the game has native OpenXR support (don't use xrizer)
2. Verify launch options: `xrizer PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc %command%`
3. Check WiVRn logs: `journalctl --user -u wivrn -f`

**Performance Issues:**

1. Verify AV1 codec is enabled in WiVRn dashboard (RTX 40-series)
2. Use H.265 if you have RTX 30-series or older
3. Check explicit sync is working: Look for warnings in compositor logs

---

## Usage Workflow

**Quick Start:**

1. ✅ WiVRn auto-starts on login
2. ✅ Connect Quest 3 to WiVRn
3. ✅ WayVR overlay auto-starts when connected
4. ✅ Put on headset and double-tap B/Y to show desktop

**Everything is automatic!** Just connect your headset and WayVR will be waiting for you.

---

### 1. Start WiVRn (Auto-starts on login)

Verify it's running:

```bash
systemctl --user status wivrn
```

### 2. Connect Quest Headset

**Wireless (Recommended):**

- Put on Quest headset
- Open **WiVRn** app (installed via SideQuest)
- Select **jupiter** from server list
- Wait for "Connected" status

**Wired (USB Fallback):**

If WiFi is unavailable or unstable, you can use a wired USB connection:

1. **Connect Quest to PC via USB-C cable**
2. **Enable USB debugging** on Quest:
   - Go to Settings → System → Developer → Enable USB debugging
3. **Allow USB debugging** when prompted on headset
4. **Verify ADB connection**:
   ```bash
   adb devices
   # Should show your Quest device
   ```
5. **Open WiVRn app** on Quest and connect as normal

The connection will automatically use USB instead of WiFi for lower latency and more stable performance.

**ADB Support:**

ADB (Android Debug Bridge) is automatically available for wired VR support. Modern systemd (258+) handles USB device access automatically, so no special group membership is needed.

### 3. WayVR Desktop Overlay (Auto-starts)

**WayVR automatically starts when WiVRn connects!** It runs in OpenXR mode with a home environment.

**Service Status:**

```bash
wayvr-status  # Check if WayVR is running
wayvr-log     # View real-time logs
```

**Service Control:**

```bash
wayvr-start   # Manually start WayVR
wayvr-stop    # Stop WayVR overlay
wayvr-restart # Restart WayVR
```

**First-time setup:**

- When WayVR starts, a screen selection dialog will appear
- Check your **notifications** or terminal for the correct screen order
- Select screens in the order requested
- If you select wrong: In VR, go to Settings → "Clear PipeWire tokens" → "Restart software"

**Controls in VR:**

- **Double-tap B or Y** (left controller): Show/hide desktop overlays
- **Check left wrist**: Watch interface for controls
- **Blue laser**: Left-click
- **Orange laser**: Right-click (squeeze grip while pointing)
- **Purple laser**: Middle-click
- **Analog stick up/down**: Scroll wheel

**Home Environment:**
WayVR shows a home environment with headset passthrough by default. You can customize the background via Settings or check the [OpenXR Skybox wiki](https://github.com/wlx-team/wayvr/wiki/OpenXR-Skybox).

**Optional Management Dashboard:**

```bash
vr-dashboard
```

**Note:** The dashboard is a companion GUI that connects to the main WayVR overlay. Most users won't need it—just use the in-VR watch interface.

**Manual Launch (if service disabled):**

```bash
vr-desktop          # Launch WayVR in basic mode
vr-desktop-openxr   # Launch WayVR with OpenXR home environment
```

### 4. Launch VR Games

- Launch game from Steam (with proper launch options)
- Game should start in VR automatically

---

## Troubleshooting

### No Audio in VR Games

**Problem:** Game is running but you don't hear audio in your Quest 3 headset.

**Cause:** The game is outputting to your desktop speakers instead of the WiVRn virtual audio device.

**Quick Fix (while game is running):**

```bash
vr-audio-fix
```

This redirects the game's audio to your Quest 3.

**Permanent Fix - Using pavucontrol:**

1. **Install pavucontrol** (if not already installed):

   ```bash
   nix-shell -p pavucontrol --run pavucontrol
   ```

2. **Switch to "Playback" tab**

3. **Find your VR game** (e.g., "hlvr" for Half-Life: Alyx)

4. **Click the dropdown next to the game** and select **"WiVRn"**

**Alternative - Set WiVRn as Default:**

This makes **all** audio go to your Quest 3 (not recommended for desktop use):

```bash
pactl set-default-sink wivrn.sink
```

To revert:

```bash
pactl set-default-sink @DEFAULT_SINK@
```

**Pro Tip:** Most audio control panels (pavucontrol, your DE's audio settings) let you assign specific applications to specific output devices. Set your VR games to always use "WiVRn" and desktop apps to use your speakers.

### WayVR Dashboard Shows "Connection Refused"

**Error:**

```
WARN: Failed to connect to the WayVR IPC: Connection refused (os error 111)
```

**Solution:** Run the main WayVR overlay first:

```bash
vr-desktop  # Start this first!
```

Then in another terminal:

```bash
vr-dashboard  # This will now connect
```

**Why:** `vr-dashboard` is a management GUI that connects to `wlx-overlay-s`. You must run the main overlay before the dashboard can connect.

**Note:** Most users don't need the dashboard—you can control everything in VR using the watch on your left wrist.

### WayVR Not Visible in Headset

**Checklist:**

1. **Is WiVRn connected?**

   ```bash
   systemctl --user status wivrn
   # Should show "active (running)" with client connected
   ```

2. **Is WayVR running?**

   ```bash
   wayvr-status
   # Should show "active (running)"
   ```

3. **Did you select screens when prompted?**
   - Check terminal output or notifications
   - Select screens in the order requested
   - If you missed it, restart: `wayvr-restart`

4. **Are overlays hidden?**
   - Double-tap B or Y on left controller to show/hide

5. **Check WayVR logs:**

   ```bash
   wayvr-log  # Real-time systemd journal
   # Or check legacy log:
   tail -f /tmp/wayvr.log
   ```

**If WayVR service failed to start:**

```bash
# Check the error
journalctl --user -u wayvr -n 50

# Common fixes:
wayvr-restart              # Restart the service
systemctl --user reset-failed wayvr  # Clear failed state
```

### Disabling WayVR Auto-Start

If you prefer to launch WayVR manually instead of auto-starting:

```nix
# In home/nixos/apps/vr.nix, disable the systemd service
systemd.user.services.wayvr.Install.WantedBy = lib.mkForce [ ];
```

Then rebuild home-manager:

```bash
nh home switch
```

Now WayVR won't auto-start. Launch manually with:

```bash
vr-desktop-openxr  # Launch with OpenXR home environment
```

### Mouse Not Aligned with Laser Pointer

**Screens selected in wrong order:**

1. In VR settings, press "Clear PipeWire tokens"
2. Press "Restart software"
3. Check **notifications** or terminal for correct screen order
4. Select screens in the requested order

**Or restart the service:**

```bash
wayvr-restart
# Then select screens when prompted
```

### Game Crashes Immediately

**Check OpenXR runtime:**

```bash
cat ~/.config/openxr/1/active_runtime.json
```

Should point to WiVRn:

```json
{
    "file_format_version": "1.0.0",
    "runtime": {
        "name": "Monado",
        "library_path": "/nix/store/.../lib/wivrn/libopenxr_wivrn.so",
        "MND_libmonado_path": "/nix/store/.../lib/wivrn/libmonado_wivrn.so"
    }
}
```

**Check launch options are set correctly** in Steam game properties.

### Quest Can't Find Server

**Check firewall ports:**

```bash
ss -tulpn | grep -E '(9757|5353)'
```

Should show:

- Port 5353: mDNS discovery (UDP)
- Port 9757: VR streaming (TCP)

**Check WiVRn logs:**

```bash
journalctl --user -u wivrn -f
```

### "Headset Not Found" Error

**Verify Quest is connected to WiVRn** before launching game.

**Check IPC socket exists after game launch:**

```bash
ls -la $XDG_RUNTIME_DIR/monado_comp_ipc
```

Should be created when VR app starts.

### Wired VR Connection Issues

**ADB Device Not Found:**

Check if the Quest is detected:

```bash
adb devices
```

**Expected output:**
```
List of devices attached
1234567890ABCDEF    device
```

**If no devices shown:**

1. **Enable USB debugging** on Quest:
   - Settings → System → Developer → Enable USB debugging
2. **Check USB cable** - Some cables are charge-only, not data cables
3. **Try different USB port** - Use USB 3.0/3.1 ports for best performance
4. **Restart ADB server**:
   ```bash
   adb kill-server
   adb start-server
   ```

**If device shows "unauthorized":**

1. Put on the Quest headset
2. Look for the USB debugging authorization prompt
3. Check "Always allow from this computer"
4. Click "OK"

**Performance Issues on Wired:**

1. **Use USB 3.0 or higher** - USB 2.0 will bottleneck video streaming
2. **Check cable quality** - Use official Oculus Link cable or equivalent
3. **Verify USB mode**:
   ```bash
   adb shell getprop sys.usb.config
   # Should show: mtp,adb or similar
   ```

**Permissions Issues:**

Modern systemd (258+) automatically grants USB device access through uaccess rules. If you encounter permission issues:

1. **Verify udev rules are loaded**:
   ```bash
   udevadm control --reload-rules
   udevadm trigger
   ```

2. **Check device permissions**:
   ```bash
   ls -la /dev/bus/usb/*/  # Find your Quest device
   # Should show your user has read/write access
   ```

---

## Known Working Games

### Native OpenXR (Best Performance)

- Half-Life: Alyx ✅
- Bonelab ✅
- Any game with "OpenXR" badge in Steam

### OpenVR (via OpenComposite)

Games that use SteamVR can work via OpenComposite translation layer:

- Beat Saber
- Pavlov VR
- VRChat

**Note**: Some OpenVR games may have compatibility issues. Check [OpenComposite compatibility list](https://gitlab.com/znixian/OpenOVR/-/wikis/Compatibility).

---

## References

- [WiVRn Documentation](https://github.com/WiVRn/WiVRn)
- [Monado Documentation](https://monado.freedesktop.org/)
- [NixOS VR Wiki](https://wiki.nixos.org/wiki/VR)
- [NixOS GitHub Issue #258196](https://github.com/NixOS/nixpkgs/issues/258196) - Steam + Monado setup

---

## Quick Reference

### Start/Stop WiVRn

```bash
# Status
systemctl --user status wivrn

# Restart (if needed)
systemctl --user restart wivrn

# Logs
journalctl --user -u wivrn -f
```

### Test OpenXR

```bash
# Install test app
nix-shell -p openxr-loader --run "hello_xr -g Vulkan"
```

### Steam Launch Options Template

**For Native OpenXR Games:**

```bash
PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc %command%
```

**For SteamVR (OpenVR) Games:**

```bash
xrizer PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc %command%
```

Copy the appropriate command for each VR game in Steam.
