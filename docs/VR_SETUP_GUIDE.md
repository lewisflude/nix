# VR Setup Guide (WiVRn + OpenXR)

**Last Updated**: 2026-01-12
**System**: NixOS with WiVRn wireless VR streaming
**Headset**: Meta Quest 3

---

## Overview

This system uses **WiVRn** for wireless VR, which includes its own embedded Monado runtime optimized for streaming. The standalone system Monado service is disabled to prevent conflicts.

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

---

## Steam VR Game Launch Options

### Why Launch Options Are Needed

Steam games run inside a **pressure-vessel container** which isolates them from the host system. By default, this container cannot:

1. See your OpenXR runtime configuration
2. Access the Monado IPC socket that WiVRn creates

### Required Launch Options

For **ALL** VR games in Steam, set these launch options:

```bash
PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1 PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/monado_comp_ipc %command%
```

#### What Each Part Does

| Variable | Purpose |
|----------|---------|
| `PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1` | Imports host OpenXR runtime into container |
| `PRESSURE_VESSEL_FILESYSTEMS_RW=...` | Mounts Monado IPC socket for communication |
| `%command%` | Placeholder for game executable |

**Without these:** Game cannot find VR runtime and crashes immediately.

### Setting Launch Options

1. **In Steam Library**: Right-click game → **Properties**
2. **Under "Launch Options"**: Paste the command above
3. **Close properties window**

### Example: Half-Life: Alyx

```
Game: Half-Life: Alyx (App ID: 546560)
Launch Options:
  PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1 PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/monado_comp_ipc %command%
```

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

```bash
PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1 PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/monado_comp_ipc %command%
```

Copy this for every VR game in Steam.
