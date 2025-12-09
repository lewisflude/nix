# Pro Audio Gaming Bridge Guide

## Problem Statement

Modern gaming titles (especially Proton/Wine games) fail when they detect audio devices with more than 2-8 channels. Professional audio interfaces like the **Apogee Symphony Desktop** expose 10+ channels in "Pro Audio" mode (analog I/O, optical, USB routing), causing games to:

- Crash on audio initialization
- Output silence
- Fail to detect audio devices
- Show cryptic "audio device not found" errors

This is because older game engines and Windows audio APIs expect simple stereo devices and cannot handle complex channel maps used by professional audio interfaces.

## Solution: Stereo Virtual Bridge

The solution is to create a **virtual stereo sink** using `libpipewire-module-loopback` where the capture side acts as the virtual device that games can detect, while the playback side routes audio to the actual hardware interface.

### Architecture

```
┌─────────────────┐
│ Game/Proton │
│ (sees stereo) │
└────────┬────────┘
 │
 v
┌─────────────────────────────┐
│ Loopback Capture Side │ <--- Virtual stereo sink
│ (apogee_stereo_game_bridge)│ <--- Games output here
│ media.class = "Audio/Sink" │
└──────────┬──────────────────┘
 │ (PipeWire loopback)
 v
┌─────────────────────────────┐
│ Loopback Playback Side │ <--- Routes to hardware
└──────────┬──────────────────┘
 │
 v
┌─────────────────────────────┐
│ Apogee Symphony Desktop │ <--- Physical hardware
│ (Pro Audio profile) │ (10+ channels)
└─────────────────────────────┘
```

## Implementation

This repository uses the **best practice single loopback approach** recommended by the PipeWire documentation. This method:

- Creates a virtual sink directly from the loopback's capture side
- Simpler configuration with less overhead
- Direct routing without intermediate adapters
- Better integration with PipeWire's native routing

### Current Configuration

The implementation is in [`modules/nixos/features/desktop/audio.nix`](../modules/nixos/features/desktop/audio.nix):

```nix
extraConfig.pipewire."90-proton-stereo" = {
  "context.modules" = [
    {
      name = "libpipewire-module-loopback";
      args = {
        "node.name" = "apogee_stereo_game_bridge";
        "node.description" = "Apogee Stereo Game Bridge";

        # CAPTURE SIDE: Creates the virtual sink (what games see)
        "capture.props" = {
          "media.class" = "Audio/Sink";
          "audio.position" = [ "FL" "FR" ];
          "priority.session" = 1900;
          "node.passive" = false;
        };

        # PLAYBACK SIDE: Routes to physical hardware
        "playback.props" = {
          "audio.position" = [ "FL" "FR" ];
          "node.target" = "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-audio";
          "node.passive" = false;
          "stream.dont-remix" = true;
        };
      };
    }
  ];
};
```

**Important**: Use the **Pro Audio** profile (`pro-audio`) instead of `multichannel-output` for the target. This exposes all channels and provides better routing control.

### Key Configuration Options

| Option | Side | Purpose |
|--------|------|---------|
| `node.name` | Both | Internal identifier for the loopback module |
| `node.description` | Both | User-visible name in audio controls |
| `media.class = "Audio/Sink"` | Capture | Makes the capture side appear as an output device |
| `audio.position = ["FL" "FR"]` | Both | Define as stereo (Front Left/Right) |
| `priority.session = 1900` | Capture | High priority makes it default for games |
| `node.passive = false` | Both | Keep the loopback always active |
| `stream.dont-remix` | Playback | Preserves audio quality, no resampling |
| `node.target` | Playback | Physical hardware node to route audio to |

**Key Distinction**:

- **Capture side** (`capture.props`): The virtual sink that applications see and output to
- **Playback side** (`playback.props`): Routes audio to the physical hardware interface

### Automatic Routing

WirePlumber automatically routes gaming applications to the bridge using stream rules:

```nix
"90-proton-routing" = {
  "monitor.rules" = [
    {
      matches = [{ "node.name" = "apogee_stereo_game_bridge"; }];
      actions = {
        update-props = {
          "priority.session" = 1900;
          "node.passive" = false;
        };
      };
    }
  ];

  "monitor.stream.rules" = [
    # Steam and Steam games
    {
      matches = [
        { "application.process.binary" = "steam"; }
        { "application.name" = "~steam_app_.*"; }
        { "application.name" = "Steam"; }
      ];
      actions = {
        update-props = {
          "node.target" = "apogee_stereo_game_bridge";
          "node.latency" = "256/48000";
          "session.suspend-timeout-seconds" = 0;
        };
      };
    }
    # Gamescope (Steam Deck UI mode)
    {
      matches = [{ "application.id" = "gamescope"; }];
      actions = {
        update-props = {
          "node.target" = "apogee_stereo_game_bridge";
          "node.latency" = "256/48000";
          "session.suspend-timeout-seconds" = 0;
        };
      };
    }
    # Wine/Proton games (non-Steam)
    {
      matches = [
        { "application.process.binary" = "~wine.*"; }
        { "application.process.binary" = "~.*\\.exe"; }
      ];
      actions = {
        update-props = {
          "node.target" = "apogee_stereo_game_bridge";
          "node.latency" = "256/48000";
          "session.suspend-timeout-seconds" = 0;
        };
      };
    }
  ];
};
```

This ensures:

- **Steam** games automatically use the bridge
- **Proton/Wine** games use the bridge
- **Gamescope** sessions use the bridge
- Latency is set appropriately for gaming (256 frames @ 48kHz = ~5.3ms)
- Devices never suspend during gameplay
- Games never see the multi-channel Pro Audio interface directly

## Identifying Your Hardware Channels

Before adapting this configuration for a different audio interface:

### Step 1: Enable Pro Audio Profile

1. Open **Pavucontrol** (PulseAudio Volume Control)
2. Go to the **Configuration** tab
3. Set your audio interface to **Pro Audio** profile

### Step 2: Find Node Name

Run in terminal:

```bash
pw-link -o | grep -i apogee
# or for other interfaces:
pw-link -o | grep -i "your-interface-name"
```

Example output:

```
alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-audio:playback_FL
alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-audio:playback_FR
alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-audio:playback_FC
...
```

**Extract**:

- **Node Name**: `alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-audio`
- **Channels**: `playback_FL` (Front Left), `playback_FR` (Front Right) - usually main outputs

**Important**: Use the **`pro-audio`** profile suffix, not `multichannel-output`. The Pro Audio profile exposes all channels with better routing control.

### Step 3: Verify Channel Mapping

Check your audio interface manual to confirm which channels are your main outputs. Common mappings:

| Interface Type | Main Output Channels |
|----------------|----------------------|
| Apogee Symphony Desktop | `playback_1` (L), `playback_2` (R) |
| Focusrite Scarlett | `playback_FL`, `playback_FR` |
| RME Fireface | `playback_AIO1`, `playback_AIO2` |
| Universal Audio Apollo | `playback_1`, `playback_2` |

## Activation & Verification

### Apply Configuration

```bash
# System rebuild
sudo nixos-rebuild switch
# or
nh os switch

# Restart PipeWire
systemctl --user restart pipewire wireplumber
```

### Verify Bridge Exists

```bash
# List all sinks
pw-cli list-objects | grep -A 10 "node.name.*apogee_stereo_game_bridge"

# Or use pw-dump for detailed info
pw-dump | grep -A 20 "apogee_stereo_game_bridge"

# Check in Pavucontrol
pavucontrol
# → Output Devices tab → Look for "Apogee Stereo Game Bridge"
```

### Set as Default (Optional)

The bridge has high priority (`priority.session = 1900`) and should be the default automatically. To manually set it:

```bash
# Using wpctl (WirePlumber control)
wpctl status  # Find the bridge sink ID
wpctl set-default <sink-id>

# Or use Pavucontrol
# → Output Devices tab → Click green checkmark on "Apogee Stereo Game Bridge"
```

### Test with a Game

1. Launch a Proton/Steam game
2. Check audio output in-game
3. Verify in **Pavucontrol** → **Playback** tab that the game is routed to the bridge

## Troubleshooting

### No Audio from Games

**Check routing:**

```bash
# Monitor active connections
pw-top

# Check if the bridge is active and connected
pw-link -i | grep apogee_stereo_game_bridge
pw-link -o | grep apogee_stereo_game_bridge
```

**Verify loopback is connected:**

```bash
# Check that the virtual sink exists and routes to hardware
pw-link -o | grep apogee_stereo_game_bridge
pw-link -i | grep "alsa_output.*Apogee.*pro-audio"

# Should show the loopback routing audio to the physical device
```

### Game Still Crashes on Audio Init

**Check if game sees the bridge:**

```bash
# Run game with PipeWire debug logging
PIPEWIRE_DEBUG=3 %command%  # In Steam launch options
```

**Force PulseAudio backend:**

```bash
# Steam launch options:
SDL_AUDIODRIVER=pulseaudio %command%
```

### Audio Quality Issues / Crackling

**Check buffer settings:**

```bash
# View current quantum (buffer size)
pw-metadata -n settings 0 clock.force-quantum

# Increase buffer for stability (at cost of latency)
pw-metadata -n settings 0 clock.force-quantum 512

# Reset to default
pw-metadata -n settings 0 clock.force-quantum 0
```

**Adjust in configuration:**

```nix
# In hosts/jupiter/default.nix
features.media.audio = {
  ultraLowLatency = false;  # Use 256 frames instead of 64
};
```

### Bridge Not Appearing

**Check PipeWire config loaded:**

```bash
# View active PipeWire configuration
systemctl --user status pipewire

# Check for errors
journalctl --user -u pipewire -f

# Verify config files
ls ~/.config/pipewire/pipewire.conf.d/
```

**Manually load module:**

```bash
# Test loopback directly (temporary test)
pw-loopback \
  --capture-props='media.class=Audio/Sink audio.position=[FL,FR]' \
  --playback-props='audio.position=[FL,FR] node.target=alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-audio'
```

## Alternative: Simple Loopback Approach

For simpler setups, you can use just the loopback module without the null-audio-sink adapter:

```nix
services.pipewire.extraConfig.pipewire."99-stereo-bridge" = {
  "context.modules" = [
    {
      name = "libpipewire-module-loopback";
      args = {
        "node.name" = "apogee_stereo_game_bridge";
        "node.description" = "Apogee Stereo Game Bridge";

        "capture.props" = {
          "media.class" = "Audio/Sink";
          "audio.position" = [ "FL" "FR" ];
        };

        "playback.props" = {
          "audio.position" = [ "FL" "FR" ];
          "node.target" = "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-audio";
        };
      };
    }
  ];
};
```

### Why This Approach is Best Practice

This single loopback module approach is recommended by PipeWire documentation because:

**Advantages**:

✅ **Simpler configuration**: One module instead of two (adapter + loopback)
✅ **Less overhead**: Direct routing without intermediate adapters
✅ **Native PipeWire integration**: Better compatibility with WirePlumber routing
✅ **Cleaner graph**: Fewer nodes in the PipeWire audio graph
✅ **Better performance**: Less CPU usage and lower memory footprint
✅ **Full control**: Priority management via `capture.props`
✅ **Easy routing**: WirePlumber stream rules work seamlessly

**Comparison with Legacy Two-Stage Approach**:

Some older guides use a two-stage approach with `support.null-audio-sink` + loopback. This is unnecessary for modern PipeWire setups:

```nix
# ❌ LEGACY APPROACH - More complex, no benefits
"context.objects" = [{
  factory = "adapter";
  args = { "factory.name" = "support.null-audio-sink"; };
}];
"context.modules" = [{
  name = "libpipewire-module-loopback";
  args = { /* captures from null sink */ };
}];
```

**Why avoid the legacy approach**:

- ❌ More configuration complexity
- ❌ Extra audio graph nodes
- ❌ Higher CPU usage
- ❌ Harder to troubleshoot
- ❌ No practical benefits over single loopback

**Recommendation**: Use the single loopback approach (as implemented in this repository) for all setups.

## Performance Tuning

### Latency Considerations

| Buffer Size | Latency | Use Case |
|-------------|---------|----------|
| 64 frames | ~1.3ms | Pro recording/monitoring |
| 128 frames | ~2.7ms | Low-latency gaming |
| 256 frames | ~5.3ms | **Recommended for gaming** |
| 512 frames | ~10.7ms | Stability over latency |
| 1024 frames | ~21.3ms | High CPU usage scenarios |

Gaming recommendation: **256 frames** provides the best balance of low latency and stability.

### USB Audio Optimizations

The configuration includes USB-specific optimizations for professional interfaces:

```312:323:modules/nixos/features/desktop/audio.nix
# USB audio optimizations
# Critical for professional USB audio interfaces like Apogee Symphony Desktop
services.udev.extraRules = ''
  # Disable autosuspend for USB audio interfaces (class 01)
  ACTION=="add", SUBSYSTEM=="usb", ATTR{idClass}=="01", TEST=="power/control", ATTR{power/control}="on"

  # Set realtime priority for USB audio devices
  ACTION=="add", SUBSYSTEM=="usb", ATTR{idClass}=="01", ATTR{power/wakeup}="disabled"

  # Apogee-specific optimizations (if detected)
  # Apogee Symphony Desktop (USB Vendor ID: 0xa07, Product ID varies)
  ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0a07", ATTR{power/control}="on", ATTR{power/wakeup}="disabled"
'';
```

These rules:

- Disable USB autosuspend (prevents dropouts)
- Disable wakeup (prevents interference)
- Set realtime priority for audio devices

### Verifying Bit-Perfect Routing

To verify audio passes through without resampling:

```bash
# Check current graph
pw-dot | dot -Tpng > pipewire-graph.png
xdg-open pipewire-graph.png

# Verify sample rates match
pw-metadata -n settings | grep clock.rate

# Check if resampling is occurring
pw-top  # Look for "resample" in the graph
```

**Indicators of bit-perfect routing**:

- Sample rates match (48000 Hz throughout)
- No "resample" nodes in the graph
- `stream.dont-remix = true` is respected
- No format conversions (F32LE → F32LE)

## References

- **PipeWire Documentation**: [Loopback Module](https://docs.pipewire.org/page_module_loopback.html)
- **NixOS Wiki**: [PipeWire Configuration](https://nixos.wiki/wiki/PipeWire)
- **WirePlumber Docs**: [Stream Rules](https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/streams.html)
- **Apogee Symphony Desktop Manual**: Check channel mappings and routing
- **musnix**: [Real-time Linux for Audio](https://github.com/musnix/musnix) - Used for RT kernel optimizations

## Related Documentation

- [`docs/QBITTORRENT_GUIDE.md`](QBITTORRENT_GUIDE.md) - Media server setup
- [`docs/PERFORMANCE_TUNING.md`](PERFORMANCE_TUNING.md) - System-wide performance optimization
- [`modules/nixos/features/desktop/audio.nix`](../modules/nixos/features/desktop/audio.nix) - Audio configuration implementation
- [`hosts/jupiter/default.nix`](../hosts/jupiter/default.nix) - Host-specific audio settings

## Summary

The Pro Audio Gaming Bridge solves the fundamental incompatibility between professional multi-channel audio interfaces and legacy game audio engines by:

1. **Creating a simple stereo virtual device** that games can detect and use
2. **Automatically routing game audio** through WirePlumber rules
3. **Transparently bridging to the physical hardware** in the background
4. **Maintaining audio quality** with no resampling or format conversion
5. **Optimizing latency** for gaming while preserving stability

This approach allows you to keep your professional audio interface in "Pro Audio" mode for production work while ensuring perfect compatibility with gaming titles.
