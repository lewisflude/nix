# Audio Troubleshooting Guide

## Overview

This document explains the audio configuration in this NixOS setup and how to troubleshoot common issues.

## Architecture

### Audio Stack

```
Application Layer
    ├─ SDL2 games → PulseAudio API → PipeWire
    ├─ FMOD games → ALSA → PipeWire ALSA plugin → PipeWire
    ├─ Wine/Proton → PulseAudio API → PipeWire
    ├─ OpenAL games → ALSA → PipeWire
    └─ Native PipeWire apps → PipeWire directly

PipeWire Layer (services.pipewire)
    ├─ PulseAudio compatibility (pulse.enable = true)
    ├─ ALSA compatibility (alsa.enable = true)
    ├─ JACK compatibility (jack.enable = true)
    └─ WirePlumber (session manager, sets defaults)

Hardware Layer
    └─ Apogee Symphony Desktop → AUX0/AUX1 channels
        └─ pw-loopback "Speakers" virtual sink (for games)
```

### Custom Audio Routing

**Problem**: Apogee Symphony Desktop uses professional audio routing with separate AUX channels. Games expect a simple stereo sink.

**Solution**: Use `pw-loopback` to create a virtual "Speakers" sink that routes to Apogee's AUX0/AUX1 channels.

**Implementation**: `modules/nixos/features/desktop/audio/hardware-specific.nix`

## Best Practices Implemented

### 1. Let NixOS Handle ALSA Configuration

**What we DO:**

- Enable `services.pipewire.alsa.enable = true`
- Enable `services.pipewire.alsa.support32Bit = true`

**What NixOS does automatically:**

- Installs `pipewire-alsa` package
- Creates `/etc/alsa/conf.d/99-pipewire-default.conf`
- Configures ALSA to route through PipeWire by default

**What we DON'T do:**

- ❌ Manually create `/etc/asound.conf`
- ❌ Create user `~/.asoundrc` files
- ❌ Override NixOS's ALSA configuration

### 2. Provide Complete Audio Libraries for Steam

**The Problem**: Steam's pressure-vessel container isolates games from the host system. Games using different audio APIs need the appropriate libraries available.

**The Solution**: Use `extraCompatPackages` to provide complete audio stack:

```nix
extraCompatPackages = with pkgs; [
  pipewire          # PipeWire daemon and libraries
  pulseaudio        # PulseAudio daemon (for fallback)
  libpulseaudio     # PulseAudio client library
  alsa-lib          # ALSA user-space library (required for FMOD, OpenAL)
  alsa-plugins      # ALSA plugins including PipeWire bridge
];
```

**Why each package is needed:**

- `pipewire`: For native PipeWire-aware games
- `pulseaudio`/`libpulseaudio`: For SDL2 games and Wine/Proton
- `alsa-lib`: For FMOD games (Dwarf Fortress, Celeste, etc.)
- `alsa-plugins`: Provides the ALSA→PipeWire bridge inside container

### 3. Set WirePlumber Priorities (Not Hardcoded Defaults)

**Best Practice**: Use priority system instead of hardcoding defaults.

```lua
-- GOOD: Set priority, let WirePlumber decide
rule = {
  matches = {{ { "node.name", "equals", "Speakers" }}},
  apply_properties = {
    ["priority.session"] = 3000,  -- Higher than hardware devices
  },
}
```

**Why**: This allows users to override defaults and respects PipeWire's design.

### 4. Minimal Environment Variables

**Best Practice**: Only set environment variables when necessary.

**What we set:**

- `SDL_AUDIODRIVER="pulseaudio"` - SDL2 needs explicit backend
- `WINE_AUDIO="pulse"` - Wine needs explicit backend
- `PULSE_LATENCY_MSEC="60"` - Gaming latency setting
- `PIPEWIRE_LATENCY="256/48000"` - PipeWire native latency

**What we DON'T set:**

- ❌ `FMOD_OUTPUTTYPE` - Not needed with proper ALSA libs
- ❌ `ALSA_*` variables - ALSA config handles this
- ❌ Hardcoded device names in env vars

### 5. Use Systemd Service Dependencies Correctly

**Best Practice**: Ensure audio routing services start in correct order.

```nix
systemd.user.services.apogee-speakers-loopback = {
  after = ["pipewire.service" "wireplumber.service"];
  wants = ["pipewire.service" "wireplumber.service"];
  partOf = ["pipewire.service"];
  wantedBy = ["pipewire.service"];
};
```

**Why**: Prevents race conditions where games start before audio routing is ready.

## Common Issues

### Issue: Apogee Symphony Desktop Not Working After KVM Switch

**Symptoms:**

- After switching to this computer using KVM, audio interface doesn't appear in PipeWire
- No audio output or input available
- Device shows in `lsusb` but not in `wpctl status`

**Cause:**

When switching between computers via KVM, the USB audio interface can retain state from the previous system (e.g., macOS/Ableton) which prevents Linux from properly initializing it.

**Solution:**

This system has **automatic USB reset** configured in `modules/nixos/hardware/apogee-symphony.nix`.

When you switch to this computer via KVM:

1. The udev rule detects the Apogee reconnection
2. Automatically runs USB reset to clear device state
3. Restarts PipeWire services to detect the device
4. Restarts the speakers loopback service for gaming

**Manual Reset (if automatic fails):**

```bash
# Run the manual reset command
sudo apogee-reset

# Or manually restart PipeWire services
systemctl --user restart pipewire wireplumber pipewire-pulse
systemctl --user restart apogee-speakers-loopback
```

**Check Logs:**

```bash
# View reset activity logs
journalctl -t apogee-reset -f

# Check if reset service ran
systemctl status 'apogee-kvm-reset@*'
```

### Issue: Game Has No Audio

**Symptoms:**

- Game launches fine but produces no sound
- Game doesn't appear in audio mixer (pwvucontrol)

**Diagnosis:**

```bash
# Check if PipeWire is running
systemctl --user status pipewire pipewire-pulse

# Check default devices
wpctl status | grep "*"

# Check if game creates audio stream
pw-cli list-objects | grep -A 10 "Stream"
```

**Common Causes:**

1. **Missing ALSA libraries** (FMOD games like Dwarf Fortress)
   - **Solution**: Added `alsa-lib` and `alsa-plugins` to `extraCompatPackages`

2. **Wrong default device**
   - **Check**: `pw-metadata -n default | grep default.audio`
   - **Solution**: WirePlumber priority configuration ensures "Speakers" is default

3. **Steam container isolation**
   - **Check**: Sockets exist at `/run/user/$UID/pipewire-0` and `/run/user/$UID/pulse/native`
   - **Solution**: `PULSE_SERVER` environment variable override

### Issue: Audio Works But Wrong Device

**Symptoms:**

- Game has audio but it's on wrong output
- Can't select "Speakers" device in game

**Solution:**

```bash
# Manually set default for this session
wpctl set-default $(wpctl status | grep "Speakers" | awk '{print $1}' | tr -d '*.')

# Permanent: Already configured in WirePlumber rules
```

### Issue: Crackling or Stuttering Audio

**Symptoms:**

- Audio plays but has dropouts or crackles
- Especially during high CPU load

**Diagnosis:**

```bash
# Check buffer underruns
pw-top

# Check system load
top -o %CPU
```

**Solutions:**

1. Increase quantum: Edit `modules/nixos/features/desktop/audio/pipewire.nix`

   ```nix
   "default.clock.quantum" = 256;  # Was 128
   ```

2. Check realtime priority:

   ```bash
   chrt -p $(pgrep pipewire)  # Should show SCHED_FIFO or SCHED_RR
   ```

## Testing Audio Configuration

### Test Native ALSA

```bash
# List ALSA devices
aplay -L | grep -A 2 "default"

# Should show:
# default
#   Default ALSA Output (currently PipeWire Media Server)
```

### Test PulseAudio Compatibility

```bash
# List PulseAudio sinks
pactl list sinks short

# Should show Speakers and other devices
```

### Test in Steam Container

```bash
# Run test from Steam runtime
steam-run pactl list sinks short
steam-run aplay -L
```

## When to Rebuild

After changing these files, rebuild your system:

```bash
# Review changes
git diff modules/nixos/features/gaming.nix
git diff modules/nixos/features/desktop/audio/

# Rebuild (user runs this)
nh os switch

# Restart audio services (if needed)
systemctl --user restart pipewire pipewire-pulse wireplumber

# Restart Steam completely
pkill steam && steam
```

## Architecture Decisions

### Why pw-loopback Instead of Virtual ALSA Device?

**Considered**: Creating ALSA virtual device pointing to Apogee
**Chosen**: pw-loopback creating virtual sink

**Reasoning**:

- pw-loopback integrates better with WirePlumber
- Automatic priority handling
- Visible in all audio APIs (PulseAudio, ALSA, JACK)
- Can be controlled by audio mixer applications

### Why Not Use ~/.asoundrc?

**Best Practice**: System-level configuration via NixOS modules.

**Reasoning**:

- Declarative: Reproducible across systems
- Version controlled: Part of system configuration
- No hidden user configs: Everything in one place
- NixOS already provides proper ALSA→PipeWire config

### Why extraCompatPackages Instead of FHS Environment?

**Best Practice**: Provide only necessary packages to Steam.

**Reasoning**:

- Smaller container overhead
- Explicit about what's needed
- Easier to debug (know exactly what's available)
- Follows NixOS Steam module design

## References

- [PipeWire Documentation](https://docs.pipewire.org/)
- [WirePlumber Documentation](https://pipewire.pages.freedesktop.org/wireplumber/)
- [NixOS PipeWire Options](https://search.nixos.org/options?query=services.pipewire)
- [Arch Wiki: PipeWire](https://wiki.archlinux.org/title/PipeWire)
- [FMOD System Requirements](https://www.fmod.com/docs/2.02/api/platforms-linux.html)

## Summary

**This configuration follows best practices by:**

1. ✅ Using NixOS's built-in PipeWire ALSA configuration (not overriding it)
2. ✅ Providing complete audio libraries for Steam containers
3. ✅ Setting WirePlumber priorities (not hardcoded defaults)
4. ✅ Using minimal, necessary environment variables
5. ✅ Proper systemd service ordering and dependencies
6. ✅ Declarative configuration (no manual configs)
7. ✅ Documentation of architecture decisions

**Root cause of FMOD audio issues**: Missing `alsa-lib` and `alsa-plugins` in Steam's `extraCompatPackages`. FMOD uses ALSA directly, not PulseAudio or SDL.

**Solution**: Add complete ALSA stack to pressure-vessel container, let NixOS's existing ALSA configuration handle routing to PipeWire.
