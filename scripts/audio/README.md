# Audio Diagnostic Scripts

Scripts for diagnosing and monitoring audio configuration on NixOS with PipeWire.

## Scripts

### `diagnose-audio-config.sh`

Comprehensive audio configuration diagnostic tool.

**Features:**

- Checks PipeWire/WirePlumber service status
- Reports current quantum/latency settings
- Lists active audio devices (sinks/sources)
- Detects Apogee Symphony Desktop interface
- Verifies gaming bridge and Sunshine virtual sink
- Checks CPU frequency governor
- Validates USB power management for audio devices
- Verifies ALSA sequencer module blacklist
- Reports real-time priorities
- Scans recent journal for audio errors

**Usage:**

```bash
./scripts/audio/diagnose-audio-config.sh
```

**When to Run:**

- After NixOS rebuild
- When experiencing audio dropouts or crackling
- When games fail to output audio
- Before and after changing audio configuration
- When debugging Apogee connectivity issues

## Configuration Files

The audio configuration is split across multiple modules:

- `modules/nixos/features/desktop/audio/` - Main audio configuration
  - `pipewire.nix` - Core PipeWire settings
  - `wireplumber.nix` - Session manager and device routing
  - `gaming.nix` - Gaming bridge and Sunshine integration
  - `bluetooth.nix` - Bluetooth audio codecs and priorities
  - `hdmi.nix` - HDMI audio device configuration
  - `processing.nix` - Audio effects (noise/echo cancellation)
  - `usb.nix` - USB audio interface optimizations
  - `kernel.nix` - Kernel-level audio configuration

## Troubleshooting

### Audio Dropouts/Crackling

**Symptoms:** Intermittent audio glitches, pops, or dropouts

**Common Causes:**

1. **Quantum too low for non-RT kernel**
   - Solution: Set `ultraLowLatency = false` in host config (uses 256 frames)
   - Ultra-low latency (64 frames) requires `realtime = true` with RT kernel

2. **USB autosuspend enabled**
   - Solution: Run diagnostic script to verify udev rules are working
   - Check: `/sys/bus/usb/devices/*/power/control` should be "on" for Apogee

3. **CPU governor too conservative**
   - Solution: Use "schedutil" or "performance" governor
   - Check: `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`

### Games Have No Audio

**Symptoms:** Games launch but produce no sound

**Common Causes:**

1. **Gaming bridge not active**
   - Check: Run diagnostic script to verify bridge status
   - Solution: Ensure Apogee is connected and recognized

2. **Games routing to wrong sink**
   - Check: `wpctl status` to see active sinks
   - Solution: Games should auto-route to Sunshine sink when streaming, bridge otherwise

3. **Apogee disconnected**
   - Solution: Check USB connection, run `lsusb | grep Apogee`

### System Performance Issues

**Symptoms:** High CPU usage, excessive power consumption, system heat

**Common Causes:**

1. **Performance governor on all cores**
   - Solution: Use "schedutil" for non-RT workloads
   - Only use "performance" with `realtime = true`

2. **Ultra-low latency when not needed**
   - Solution: Set `ultraLowLatency = false` for daily use
   - Only enable for actual recording sessions

## Audio Modes

### Daily Use (Gaming + VR Streaming)

```nix
features.media.audio = {
  realtime = false;           # Use XanMod kernel
  ultraLowLatency = false;    # 256 frames (~5.3ms)
};
```

### Professional Recording

```nix
features.media.audio = {
  realtime = true;            # Use RT kernel (musnix)
  ultraLowLatency = true;     # 64 frames (~1.3ms)
};
```

## Device Priorities

Current priority hierarchy (session.priority):

| Device | Priority | Auto-Select |
|--------|----------|-------------|
| Sunshine Virtual Sink | 150 | When streaming games |
| Apogee Symphony Direct | 100 | Default output |
| Bluetooth Headphones | 80 | Manual selection |
| Gaming Bridge (Fallback) | 50 | Local gaming only |
| NVIDIA HDMI | 30 | Display audio |
| Intel PCH | 10 | Emergency fallback |

## Further Reading

- [PipeWire Documentation](https://docs.pipewire.org/)
- [WirePlumber Documentation](https://pipewire.pages.freedesktop.org/wireplumber/)
- [Arch Wiki: PipeWire](https://wiki.archlinux.org/title/PipeWire)
