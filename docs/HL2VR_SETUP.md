# Half-Life 2: VR Mod - Complete Setup Guide for NixOS

**Last Updated**: 2026-01-21
**System**: NixOS with WiVRn + SteamVR hybrid setup
**Headset**: Meta Quest 3
**Issue Reference**: [nixpkgs-xr #569](https://github.com/nix-community/nixpkgs-xr/issues/569)

---

## Overview

Half-Life 2: VR Mod is a **32-bit application** that requires special configuration on NixOS. This guide explains why and how to set it up correctly.

### The 32-bit Problem

**WiVRn's embedded Monado runtime does not support 32-bit executables.** This is a known limitation of the OpenXR ecosystem on Linux. Half-Life 2 VR, being based on the original Source engine, is a 32-bit application.

### The Solution

Use a **hybrid setup**:
- **SteamVR**: Handles 32-bit game execution and OpenVR calls
- **WiVRn**: Receives frames from SteamVR and streams wirelessly to Quest 3
- **Result**: Wireless VR with 32-bit game support!

```
[HL2VR (32-bit)] → [SteamVR Runtime] → [WiVRn Streaming] → [Quest 3]
```

---

## System Configuration

### 1. Enable SteamVR Feature

In your host configuration (`hosts/jupiter/default.nix`):

```nix
features.vr = {
  enable = true;
  wivrn = {
    enable = true;
    autoStart = true;
    defaultRuntime = true;
  };
  steamvr = true; # ← Required for 32-bit games
  performance = true;
};
```

### 2. Ensure 32-bit Graphics Support

This should already be configured in `modules/nixos/features/desktop/graphics.nix`:

```nix
hardware.graphics = {
  enable = true;
  enable32Bit = true; # ← Required for 32-bit games
};
```

### 3. Rebuild System

```bash
nh os switch
```

---

## Installation Steps

### 1. Install SteamVR

1. Open Steam
2. Go to **Library** → **Tools**
3. Find and install **SteamVR**

### 2. Install Half-Life 2: VR Mod

1. Search for "**Half-Life 2: VR Mod**" in Steam
2. Install it

**Important**: You must **own Half-Life 2** on Steam. Family sharing does NOT work for this mod.

### 3. Configure Launch Options

1. Right-click "**Half-Life 2: VR Mod**" in Steam
2. Select **Properties**
3. Under **Launch Options**, enter:

```
%command%
```

That's it! No additional environment variables needed.

---

## Usage Workflow

### Step-by-Step Launch Process

1. **Verify WiVRn is Running**
   ```bash
   systemctl --user status wivrn
   ```
   Should show `active (running)`.

2. **Connect Quest 3 to WiVRn**
   - Put on your Quest 3 headset
   - Open the **WiVRn** app
   - Select **jupiter** from the server list
   - Wait for "**Connected**" status

3. **Launch SteamVR**
   - Open Steam on your PC
   - Launch **SteamVR** from Library → Tools
   - SteamVR should detect your headset via WiVRn

4. **Launch Half-Life 2: VR Mod**
   - In Steam, launch "**Half-Life 2: VR Mod**"
   - Game should start in VR mode
   - Enjoy!

### Audio Setup

By default, game audio goes to your desktop speakers. To route it to your Quest 3:

```bash
vr-audio-fix
```

Or use `pavucontrol` to permanently assign the game to the "WiVRn" audio device.

---

## Diagnostic Tools

### Quick Setup Check

Run the diagnostic script to verify your configuration:

```bash
./scripts/diagnose-hl2vr.sh
```

This checks:
- ✓ 32-bit graphics drivers enabled
- ✓ WiVRn service running
- ✓ OpenXR runtime configured
- ✓ Steam and SteamVR installed
- ✓ Half-Life 2 and HL2VR mod installed
- ✓ SteamVR feature enabled in config

### Manual Checks

**Check WiVRn status:**
```bash
systemctl --user status wivrn
```

**Check OpenXR runtime:**
```bash
cat ~/.config/openxr/1/active_runtime.json
```

**Check 32-bit graphics support:**
```bash
nix eval .#nixosConfigurations.jupiter.config.hardware.graphics.enable32Bit
```

**List Steam VR games:**
```bash
ls -la ~/.local/share/Steam/steamapps/common/ | grep -i "half\|hlvr"
```

---

## Troubleshooting

### Game Won't Launch

**Symptom**: Game starts but immediately closes or shows black screen.

**Solutions**:
1. Verify you **own** Half-Life 2 (not family shared)
2. Check SteamVR is installed: `ls ~/.local/share/Steam/steamapps/common/SteamVR`
3. Ensure Quest 3 is connected to WiVRn **before** launching
4. Check launch options are exactly: `%command%`
5. Try different Proton version (Proton Experimental recommended)

### No Audio in Headset

**Symptom**: Game audio plays on desktop speakers, not in Quest 3.

**Solution**:
```bash
vr-audio-fix  # Redirect game audio to Quest 3
```

Or permanently assign via `pavucontrol`:
1. Launch `pavucontrol`
2. Go to "Playback" tab
3. Find "hlvr" or "Half-Life 2"
4. Select "WiVRn" from dropdown

### SteamVR Says "No Headset Detected"

**Symptom**: SteamVR can't find your Quest 3.

**Solutions**:
1. Make sure WiVRn is running: `systemctl --user status wivrn`
2. Connect Quest 3 to WiVRn **first**, then launch SteamVR
3. Check OpenXR runtime points to WiVRn:
   ```bash
   cat ~/.config/openxr/1/active_runtime.json | grep wivrn
   ```
4. Restart WiVRn: `systemctl --user restart wivrn`

### Game Crashes Immediately

**Symptom**: Game crashes on startup with error message.

**Solutions**:
1. Verify 32-bit graphics drivers:
   ```bash
   nix eval .#nixosConfigurations.jupiter.config.hardware.graphics.enable32Bit
   ```
   Should return `true`.

2. Check Steam Proton version:
   - Right-click game → Properties → Compatibility
   - Try **Proton Experimental** or **Proton 9.0**

3. Disable Steam Overlay:
   - Right-click game → Properties
   - Uncheck "Enable Steam Overlay"

4. Verify game files:
   - Right-click game → Properties → Local Files
   - Click "Verify integrity of game files"

### Performance Issues

**Symptom**: Low FPS, stuttering, or lag.

**Solutions**:
1. **Lower WiVRn bitrate** (in `hosts/jupiter/default.nix`):
   ```nix
   services.wivrn.config.json.bitrate = 50000000; # 50 Mbps
   ```

2. **Disable water reflections** in HL2 graphics settings:
   - In-game → Options → Video → Advanced
   - Set "Reflect World" to "Off"

3. **Check GPU usage**:
   ```bash
   nvidia-smi
   ```
   GPU should be at high utilization during gameplay.

4. **Verify network quality** (WiFi 6 recommended):
   ```bash
   ping -c 10 <quest-3-ip>
   ```
   Should have <5ms latency.

### WiVRn Not Streaming SteamVR

**Symptom**: SteamVR works but nothing appears in headset.

**Solutions**:
1. Check WiVRn logs:
   ```bash
   journalctl --user -u wivrn -f
   ```

2. Verify OpenXR runtime is WiVRn:
   ```bash
   cat ~/.config/openxr/1/active_runtime.json
   ```

3. Restart both services:
   ```bash
   systemctl --user restart wivrn
   # Then relaunch SteamVR
   ```

---

## How It Works

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│ PC (NixOS)                                              │
│                                                         │
│  ┌─────────────────┐                                   │
│  │ Half-Life 2 VR  │ (32-bit executable)               │
│  │   (Source 1)    │                                   │
│  └────────┬────────┘                                   │
│           │ OpenVR calls                               │
│           ▼                                            │
│  ┌─────────────────┐                                   │
│  │    SteamVR      │ (32-bit OpenVR runtime)           │
│  │   Runtime       │                                   │
│  └────────┬────────┘                                   │
│           │ Frames                                     │
│           ▼                                            │
│  ┌─────────────────┐                                   │
│  │     WiVRn       │ (Wireless VR streaming)           │
│  │   (Monado)      │                                   │
│  └────────┬────────┘                                   │
│           │ WiFi 6                                     │
└───────────┼─────────────────────────────────────────────┘
            │
            │ Compressed video stream (H.264/H.265/AV1)
            │ Head tracking data
            │ Controller input
            ▼
┌─────────────────────┐
│   Meta Quest 3      │
│   (WiVRn client)    │
└─────────────────────┘
```

### Why This Works

1. **SteamVR provides 32-bit support**: SteamVR's runtime can execute 32-bit OpenVR applications
2. **WiVRn streams any OpenXR/OpenVR output**: WiVRn doesn't care if the source is 32-bit or 64-bit—it just streams frames
3. **Hybrid approach**: Best of both worlds—32-bit compatibility + wireless streaming

### Comparison with Other VR Games

| Game Type | Runtime | Works with WiVRn Alone? | Setup |
|-----------|---------|-------------------------|-------|
| **Native OpenXR (64-bit)** | WiVRn/Monado | ✅ Yes | Direct launch |
| **OpenVR (64-bit)** | xrizer + WiVRn | ✅ Yes | Use xrizer launch option |
| **OpenVR (32-bit)** | SteamVR + WiVRn | ❌ No | Requires SteamVR (this guide) |

Examples:
- **Half-Life: Alyx**: Native OpenXR (64-bit) → Works directly with WiVRn
- **Beat Saber**: OpenVR (64-bit) → Use xrizer with WiVRn
- **Half-Life 2 VR**: OpenVR (32-bit) → Requires SteamVR + WiVRn

---

## Quick Reference

### Helper Commands

```bash
# Setup instructions
setup-hl2vr

# Full diagnostic
./scripts/diagnose-hl2vr.sh

# Check WiVRn
systemctl --user status wivrn

# Fix audio
vr-audio-fix

# WiVRn logs
journalctl --user -u wivrn -f
```

### Launch Options Summary

**Half-Life 2: VR Mod (32-bit):**
```
%command%
```

**Other 64-bit OpenXR games:**
```
PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc %command%
```

**Other 64-bit OpenVR games:**
```
xrizer PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc %command%
```

---

## Related Documentation

- [VR Setup Guide](VR_SETUP_GUIDE.md) - Complete VR system documentation
- [nixpkgs-xr #569](https://github.com/nix-community/nixpkgs-xr/issues/569) - Original issue report
- [WiVRn #631](https://github.com/WiVRn/WiVRn/issues/631) - 32-bit support discussion

---

## FAQ

### Q: Why can't WiVRn support 32-bit games directly?

**A**: WiVRn's embedded Monado runtime is built for 64-bit systems. Supporting 32-bit would require maintaining separate 32-bit builds of Monado and all its dependencies, which is not practical given the declining use of 32-bit applications.

### Q: Will this work for other 32-bit VR games?

**A**: Yes! Any 32-bit VR game can use this same setup—SteamVR for execution, WiVRn for streaming.

### Q: Does this reduce performance?

**A**: Minimal impact. SteamVR adds a small overhead, but WiVRn's efficient streaming compensates. Most users report smooth 90 FPS gameplay.

### Q: Can I use ALVR instead of WiVRn?

**A**: ALVR also doesn't support 32-bit games directly. You'd still need SteamVR. WiVRn is recommended for better Wayland/Niri integration.

### Q: What about OpenComposite or xrizer?

**A**: Neither supports 32-bit games. They only work with 64-bit OpenVR applications. For 32-bit, SteamVR is currently the only option.

### Q: Do I need to keep SteamVR running for other games?

**A**: No! For 64-bit VR games, you can use WiVRn directly (OpenXR) or xrizer (OpenVR). SteamVR is only needed for 32-bit games.

---

## Contributing

Found an issue or improvement? Please update this guide or open an issue in the repository.

**Last tested**: 2026-01-21 with:
- NixOS 25.05
- WiVRn 25.12
- SteamVR (latest from Steam)
- Half-Life 2: VR Mod (latest)
- Meta Quest 3
