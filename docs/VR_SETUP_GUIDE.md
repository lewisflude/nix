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
Steam Games (via pressure-vessel container)
```

**Key Points:**

- ✅ WiVRn handles both streaming AND the OpenXR runtime
- ❌ Standalone Monado service is disabled (redundant and incompatible with Niri)
- ✅ OpenXR games work directly (no SteamVR needed)

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

If SteamVR keeps opening instead of WiVRn, you can make your OpenVR paths file read-only using Home Manager. Add this to `home/nixos/apps/vr.nix`:

```nix
# Lock OpenVR paths to prevent SteamVR from overriding WiVRn
xdg.configFile."openvr/openvrpaths.vrpath" = {
  text = builtins.toJSON {
    config = [
      "${config.xdg.dataHome}/Steam/config"
    ];
    external_drivers = null;
    jsonid = "vrpathreg";
    log = [
      "${config.xdg.dataHome}/Steam/logs"
    ];
    runtime = [
      # Point to xrizer's OpenVR compatibility layer
      "${pkgs.xrizer}/lib/openxr/opencomposite"
    ];
    version = 1;
  };
  # Force read-only to prevent Steam from modifying
  force = true;
  onChange = ''
    # Make file immutable so Steam can't overwrite it
    ${pkgs.e2fsprogs}/bin/chattr +i ${config.xdg.configHome}/openvr/openvrpaths.vrpath || true
  '';
};
```

**Note:** This is optional. WiVRn typically manages this file automatically, but locking it provides extra protection against SteamVR interference.

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

### 1. Start WiVRn (Auto-starts on login)

Verify it's running:

```bash
systemctl --user status wivrn
```

### 2. Connect Quest Headset

- Put on Quest headset
- Open **WiVRn** app (installed via SideQuest)
- Select **jupiter** from server list
- Wait for "Connected" status

### 3. Launch VR Game

- Launch game from Steam
- Game should start in VR automatically

---

## Troubleshooting

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
