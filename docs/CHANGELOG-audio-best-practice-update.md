# Audio Configuration Update: Best Practice Loopback Approach

**Date**: December 9, 2025
**Type**: Refactor
**Impact**: Improved simplicity and performance

## Summary

Updated the Pro Audio gaming bridge configuration to follow PipeWire best practices by using a single `libpipewire-module-loopback` where the capture side directly creates the virtual sink, instead of the more complex two-stage approach with `support.null-audio-sink` + loopback.

## Changes Made

### 1. Audio Module Configuration (`modules/nixos/features/desktop/audio.nix`)

**Previous Approach (Legacy)**:

- Used `support.null-audio-sink` adapter to create `proton_stereo_bridge`
- Separate loopback module captured from the null sink's monitor
- More complex configuration with two separate stages

**New Approach (Best Practice)**:

- Single `libpipewire-module-loopback` module
- Capture side (`capture.props`) directly creates the virtual sink with `media.class = "Audio/Sink"`
- Playback side (`playback.props`) routes to the physical hardware
- Targets the **Pro Audio** profile (`pro-audio`) instead of `multichannel-output`
- Node renamed from `proton_stereo_bridge` to `apogee_stereo_game_bridge`

**Key Configuration**:

```nix
extraConfig.pipewire."90-stereo-bridge" = {
  "context.modules" = [{
    name = "libpipewire-module-loopback";
    args = {
      "node.name" = "apogee_stereo_game_bridge";
      "node.description" = "Apogee Stereo Game Bridge";

      # Capture side: Virtual sink that games see
      "capture.props" = {
        "media.class" = "Audio/Sink";
        "audio.position" = [ "FL" "FR" ];
        "priority.session" = 1900;
        "node.passive" = false;
      };

      # Playback side: Routes to hardware
      "playback.props" = {
        "audio.position" = [ "FL" "FR" ];
        "node.target" = "alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-audio";
        "node.passive" = false;
        "stream.dont-remix" = true;
      };
    };
  }];
};
```

### 2. WirePlumber Routing Rules

Updated all references from `proton_stereo_bridge` to `apogee_stereo_game_bridge`:

- Monitor rules for setting bridge priority
- Stream rules for Steam/Proton/Wine applications
- Gamescope routing rules

### 3. Documentation (`docs/PRO_AUDIO_GAMING_BRIDGE.md`)

Comprehensive documentation updates:

- **Architecture diagram**: Updated to reflect single loopback approach
- **Implementation section**: Replaced two-stage explanation with best practice approach
- **Configuration examples**: Updated all code examples to use new pattern
- **Key options table**: Added distinction between capture and playback sides
- **Node name examples**: Changed from `multichannel-output` to `pro-audio` profile
- **Troubleshooting**: Updated commands to use new node name
- **Best practice section**: Added detailed explanation of why this approach is superior

Added new section: **Why This Approach is Best Practice**

- Lists advantages: simpler, less overhead, better performance
- Explains the legacy two-stage approach and why to avoid it
- Clear comparison between old and new methods

## Benefits

### Performance Improvements

✅ **Lower CPU usage**: Fewer PipeWire nodes in the audio graph
✅ **Reduced memory footprint**: Single module instead of adapter + loopback
✅ **Better latency**: Direct routing without intermediate adapters

### Simplicity

✅ **Cleaner configuration**: One module instead of two
✅ **Easier troubleshooting**: Fewer components to debug
✅ **Better maintainability**: Follows PipeWire documentation patterns

### Compatibility

✅ **Native PipeWire integration**: Better with WirePlumber routing
✅ **Pro Audio profile**: Better channel exposure and routing control
✅ **Future-proof**: Aligns with current PipeWire best practices

## Migration Notes

### For Existing Users

No action required when rebuilding the system:

1. The old `proton_stereo_bridge` will be replaced with `apogee_stereo_game_bridge`
2. WirePlumber rules automatically route applications to the new bridge
3. You may need to restart PipeWire services after rebuild:

   ```bash
   systemctl --user restart pipewire wireplumber
   ```

### Verification Steps

After system rebuild:

```bash
# 1. Verify bridge exists
pw-cli list-objects | grep -A 10 "apogee_stereo_game_bridge"

# 2. Check in Pavucontrol
pavucontrol
# → Output Devices → Look for "Apogee Stereo Game Bridge"

# 3. Test with a game
# Launch any Proton/Steam game and verify audio works
```

## Technical Details

### Why Pro Audio Profile?

The configuration now targets the **Pro Audio** profile instead of `multichannel-output`:

**Advantages**:

- Exposes all channels for better routing flexibility
- Direct ALSA access without PulseAudio abstraction
- Better control over channel mapping
- Standard naming: `playback_FL`, `playback_FR` instead of `playback_1`, `playback_2`

**Finding Your Device**:

```bash
# Set interface to Pro Audio profile in Pavucontrol first
pw-link -o | grep -i apogee
# Look for: alsa_output.usb-Apogee_***.pro-audio
```

### Loopback Module Behavior

The `libpipewire-module-loopback` creates two linked streams:

1. **Capture Stream** (`capture.props`):
   - When `media.class = "Audio/Sink"`, it becomes a virtual output device
   - Applications can output audio to this sink
   - This is what games see and connect to

2. **Playback Stream** (`playback.props`):
   - Receives audio from the capture side
   - Plays it back to the specified target (`node.target`)
   - Routes to the physical hardware interface

## References

- **PipeWire Loopback Documentation**: <https://docs.pipewire.org/page_module_loopback.html>
- **WirePlumber Stream Rules**: <https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/streams.html>
- **NixOS PipeWire Wiki**: <https://nixos.wiki/wiki/PipeWire>

## Related Changes

This update is part of ongoing audio configuration improvements:

- Maintains compatibility with existing gaming setups
- Preserves low-latency configuration for professional audio work
- Aligns with modern PipeWire ecosystem best practices

## Testing

Tested configurations:

- ✅ Steam games with Proton
- ✅ Native Linux games
- ✅ Wine applications
- ✅ Gamescope sessions
- ✅ Professional audio software (Ardour, REAPER)
- ✅ Browser audio and video conferencing

All scenarios work correctly with the new configuration.
