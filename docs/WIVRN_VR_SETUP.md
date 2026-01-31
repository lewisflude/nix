# WiVRn VR Setup Guide

## Overview

This system uses WiVRn as the single VR runtime, following LVRA (Linux VR Adventures) best practices for Quest 3 + RTX 4090. WiVRn provides wireless PCVR streaming with embedded Monado OpenXR runtime.

## Quick Start

1. **Start WiVRn** (if not auto-started):
   ```bash
   systemctl --user start wivrn
   ```

2. **Connect Quest headset**:
   - Install WiVRn client on Quest 3 from SideQuest
   - Open WiVRn client app on headset
   - Select your PC from the list
   - WayVR should auto-launch (desktop overlay in VR)

3. **Launch VR games**:
   - Most games: Just click "Play" in Steam (no special launch options needed)
   - See "Launch Options" section below for special cases

## Architecture

```
WiVRn (Single Runtime)
├── Embedded Monado OpenXR runtime (auto-detected)
├── NVENC + AV1 encoding (RTX 4090, auto-detected)
├── xrizer OpenVR translation (for OpenVR games)
├── NVIDIA latency optimizations
└── Steam integration (automatic)
```

## Hardware Auto-Detection

WiVRn automatically detects and optimizes for your hardware:

- **GPU**: RTX 4090 → Uses NVENC hardware encoding
- **Codec**: AV1 (Quest 3 native support)
- **Bit Depth**: 10-bit (for better color)
- **Headset**: Quest 3 → Optimized streaming parameters

No manual configuration needed - WiVRn chooses optimal settings.

## Launch Options

### OpenXR Games (Most Modern VR Games)

**No launch options needed** - just click Play:
- Half-Life: Alyx
- Boneworks
- Into the Radius
- Most Unity/Unreal VR games

### OpenVR Games (via xrizer)

**No launch options needed** - xrizer automatically translates:
- Beat Saber
- Pavlov VR
- H3VR (Hotdogs, Horseshoes & Hand Grenades)

### 32-bit Games (Half-Life 2 VR)

**May need special launch option**:
```
PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn %command%
```

If WiVRn socket isn't accessible, use this to expose it to the Steam container.

## Diagnostic Commands

Check runtime status:
```bash
vr-which-runtime         # Show current OpenXR runtime config
systemctl --user status wivrn  # Check WiVRn service status
```

Verify SteamVR installation (for 32-bit games):
```bash
vr-fix-steamvr          # Diagnose and fix SteamVR issues
```

Check configuration files:
```bash
cat ~/.config/openxr/1/active_runtime.json        # 64-bit runtime
cat ~/.config/openxr/1/active_runtime.i686.json   # 32-bit runtime
cat ~/.config/openvr/openvrpaths.vrpath           # OpenVR (xrizer)
```

Check WiVRn service:
```bash
journalctl --user -u wivrn -f  # Watch WiVRn logs
```

## Troubleshooting

### Game Won't Start in VR

1. **Check runtime**:
   ```bash
   vr-which-runtime
   ```
   Should show WiVRn for both 64-bit and 32-bit runtimes.

2. **Restart WiVRn**:
   ```bash
   systemctl --user restart wivrn
   ```

3. **Reconnect headset** in WiVRn client app.

### WayVR Won't Launch

If WayVR doesn't auto-launch when headset connects:

```bash
rm -rf ~/.config/wayvr
systemctl --user restart wivrn
```

Then reconnect headset.

### Performance Issues

WiVRn auto-tunes for your hardware. If experiencing issues:

1. **Check NVIDIA drivers**: Ensure driver 565+ is installed
2. **Check network**: Use 5GHz WiFi or WiFi 6E for best performance
3. **Check logs**: `journalctl --user -u wivrn -f`

The system includes NVIDIA latency fixes:
- `XRT_COMPOSITOR_USE_PRESENT_WAIT=1`
- `U_PACING_COMP_TIME_FRACTION_PERCENT=90`

### 32-bit Games Not Working

Verify SteamVR is installed:
```bash
vr-fix-steamvr
```

This checks for:
- Steam installation
- SteamVR installation
- Linux runtime files
- Required binaries

### Firewall Issues

WiVRn ports are automatically opened (TCP/UDP 9757). Verify with:
```bash
sudo nft list ruleset | grep 9757
```

## Configuration

VR configuration is in `hosts/jupiter/default.nix`:

```nix
vr = {
  enable = true;
  wivrn = {
    enable = true;
    autoStart = true;
    defaultRuntime = true;
    openFirewall = true;
  };
  immersed = {
    enable = true;
    openFirewall = true;
  };
  steamvr = true;      # For 32-bit games
  performance = true;  # NVIDIA optimizations
};
```

## Technical Details

### OpenXR Runtime Paths

- **64-bit**: `~/.config/openxr/1/active_runtime.json` → WiVRn
- **32-bit**: `~/.config/openxr/1/active_runtime.i686.json` → WiVRn (custom JSON)

### OpenVR Translation

- **Path**: `~/.config/openvr/openvrpaths.vrpath`
- **Runtime**: xrizer-multilib (OpenVR → OpenXR translation)
- **Purpose**: Allows OpenVR games to work with WiVRn's OpenXR runtime

### Steam Integration

WiVRn is automatically configured for Steam via:
- `services.wivrn.steam.importOXRRuntimes = true`
- Pressure-vessel containers can access runtime
- No manual LD_LIBRARY_PATH needed

## Additional Tools

- **wayvr**: Desktop overlay in VR (auto-launches with headset)
- **android-tools**: ADB for wired VR fallback/debugging
- **xrizer-multilib**: OpenVR to OpenXR translation (automatic)

## References

- [WiVRn GitHub](https://github.com/WiVRn/WiVRn)
- [WiVRn Configuration Docs](https://github.com/WiVRn/WiVRn/blob/master/docs/configuration.md)
- [LVRA Hardware Guide](https://lvra.gitlab.io/docs/hardware/)
- [Monado OpenXR Runtime](https://monado.freedesktop.org/)
