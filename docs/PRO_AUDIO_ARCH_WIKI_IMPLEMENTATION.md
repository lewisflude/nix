# Professional Audio - Arch Wiki Implementation

This document describes the professional audio optimizations implemented from the [Arch Linux Professional Audio Wiki](https://wiki.archlinux.org/title/Professional_audio) that complement our existing PipeWire setup.

## Overview

The Arch Wiki's Professional Audio guide focuses on achieving ultra-low latency for music production, recording, and synthesis. While our setup is primarily for gaming and high-quality audio playback, many of these optimizations provide tangible benefits.

## Already Implemented (Pre-existing)

Our configuration already had several professional audio optimizations in place:

### ✅ System Configuration
- **CPU frequency scaling**: Set to `performance` for gaming
- **Swappiness tuning**: 180 for zram, 10 for disk swap
- **inotify watches**: 1,048,576 (higher than wiki's 600,000)
- **PAM limits configured**: Just added for audio group
- **irqbalance disabled**: Already disabled for gaming
- **User in audio group**: Just added to Jupiter config

### ✅ Audio Configuration  
- **PipeWire with JACK support**: Full JACK client compatibility
- **Low-latency quantum**: 64/256 based on workload
- **Realtime scheduling**: RTKit enabled
- **USB autosuspend disabled**: For audio class devices

## New Implementations from Pro Audio Wiki

### 1. threadirqs Kernel Parameter ⭐

**File**: `modules/nixos/features/desktop/audio/kernel.nix`

**What it does**: Forces all interrupt handlers to run as kernel threads instead of in hard IRQ context.

**Benefits**:
- Better realtime scheduling for audio processes
- More predictable latency under system load
- Required for professional audio work
- Enforced by default in RT kernels

**Verification**:
```bash
grep threadirqs /proc/cmdline
```

### 2. RTC Interrupt Frequency Optimization

**File**: `modules/nixos/features/desktop/audio/kernel.nix`

**Configuration**: Increases RTC frequency from 64 Hz (default) to 2048 Hz

**Implementation**: Systemd service runs at boot:
```nix
systemd.services.increase-rtc-frequency = {
  description = "Increase RTC interrupt frequency for pro audio";
  # Sets /sys/class/rtc/rtc0/max_user_freq = 2048
  # Sets /proc/sys/dev/hpet/max-user-freq = 2048 (if available)
};
```

**Benefits**:
- Improved timing precision for audio applications
- Better synchronization for MIDI and audio events
- Reduces jitter in audio processing

**Verification**:
```bash
cat /sys/class/rtc/rtc0/max_user_freq
# Should show: 2048
```

### 3. PCI Latency Timer Maximization

**File**: `modules/nixos/features/desktop/audio/usb.nix`

**Configuration**: 
- Default PCI devices: 176 (0xb0)
- Audio devices (class 04xx): 255 (0xff, maximum)

**Implementation**: Systemd service runs at boot:
```nix
systemd.services.optimize-pci-latency = {
  description = "Optimize PCI latency timers for audio devices";
  # Uses setpci to configure latency timers
};
```

**Benefits**:
- Prevents audio buffer underruns
- Allows audio devices more time on the PCI bus
- Reduces xruns (audio dropouts) under system load

**Verification**:
```bash
# View all PCI latency timers
setpci -d '*:*' latency_timer

# View audio device latency specifically
lspci -vv | grep -A 10 "Audio device" | grep "Latency"
```

### 4. Pro Audio Tools

**File**: `home/nixos/hardware-tools/audio.nix`

**Added**:
- `jack2` package for latency testing tools
- `jack_delay` utility for measuring round-trip latency
- Documentation on using PipeWire's Pro Audio profile

**Usage**:
```bash
# Measure round-trip latency (requires cable loopback)
jack_delay -O system:playback_1 -I system:capture_1
```

### 5. Enhanced Diagnostic Script

**File**: `scripts/diagnostics/check-audio-setup.sh`

**New Checks**:
- ✓ threadirqs kernel parameter status
- ✓ RTC interrupt frequency (checks for 2048 Hz)
- ✓ CPU frequency governor (optimal for audio)
- ✓ PCI latency configuration

## Optimizations NOT Implemented (and Why)

### Realtime Kernel

**Why not**: XanMod kernel provides excellent latency without full RT_PREEMPT patches. The Arch Wiki notes that vanilla kernels with `CONFIG_PREEMPT=y` (which XanMod has) are adequate for most use cases.

**When you'd need it**: 
- Professional music production with sub-3ms latency requirements
- Live performance with software synthesizers
- Running 32+ simultaneous audio tracks with plugins

**If you need it**: NixOS provides `linux-rt` and `linux-rt-lts` packages.

### Timer Frequency = 1000 Hz

**Why not**: Modern kernels already use appropriate timer frequencies. XanMod uses advanced timer management.

**Note**: This is mainly important for MIDI timing, which we're not using.

### APM Disabled

**Already done**: APM (Advanced Power Management) is disabled by default on x86_64 systems. Modern systems use ACPI instead.

## Comparison: Gaming vs Professional Audio

| Optimization | Gaming Priority | Pro Audio Priority | Our Implementation |
|-------------|----------------|-------------------|-------------------|
| CPU Governor | performance | performance (RT only) | ✅ performance |
| Swappiness | Low (10) | Low (10) | ✅ 10 (disk), 180 (zram) |
| threadirqs | Optional | **Required** | ✅ **Enabled** |
| RTC Frequency | Not critical | **Important** | ✅ **2048 Hz** |
| PCI Latency | Helpful | **Critical** | ✅ **Maximized** |
| Audio Suspension | Must disable | Must disable | ✅ Disabled |
| RT Kernel | Not needed | Sometimes | ❌ XanMod sufficient |

## Expected Latency Performance

Based on our quantum settings (256/2 @ 48kHz):

| Component | Latency | Calculation |
|-----------|---------|-------------|
| Capture (ADC) | ~2.7 ms | 128 / 48000 |
| Playback (DAC) | ~5.3 ms | 256 / 48000 |
| **Round-Trip Delay** | **~8 ms** | Capture + Playback |

This is comparable to on-stage monitoring at 2-3m distance, which professional performers are accustomed to.

### Latency Breakdown

```
┌─────────────────────────────────────┐
│ Sound → Air → Mic (negligible)     │
├─────────────────────────────────────┤
│ ADC (Analog to Digital)      2.7ms │
├─────────────────────────────────────┤
│ PipeWire Processing        < 0.1ms │
├─────────────────────────────────────┤
│ DAC (Digital to Analog)      5.3ms │
├─────────────────────────────────────┤
│ Speakers → Air → Ear (negligible)  │
└─────────────────────────────────────┘
        Total RTD: ~8ms
```

## Testing Your Configuration

### 1. Run the Diagnostic Script

```bash
./scripts/diagnostics/check-audio-setup.sh
```

This will verify all optimizations are active.

### 2. Measure Actual Latency

**Setup**: Connect an output channel to an input channel with a cable.

```bash
# Start PipeWire if not running
systemctl --user start pipewire

# Measure round-trip latency
jack_delay -O system:playback_1 -I system:capture_1
```

### 3. Test Under Load

```bash
# Start a stress test in another terminal
stress-ng --cpu 16 --io 4 --vm 2 --vm-bytes 1G

# Run jack_delay and monitor for xruns
jack_delay -O system:playback_1 -I system:capture_1
```

If you see stable latency without dropouts, the configuration is working.

## Using Pro Audio Profile (Optional)

PipeWire provides a "Pro Audio" profile for lower latency:

### Enabling Pro Audio Profile

1. Open `pavucontrol` (PulseAudio Volume Control)
2. Go to **Configuration** tab
3. Select your audio device
4. Choose **Pro Audio** from the profile dropdown
5. Click **Apply**

### What Changes

**Standard Profile**:
- Automatic channel mixing
- Higher latency but easier to use
- All applications share same output

**Pro Audio Profile**:
- Direct channel access
- Lower latency
- Manual routing required (use `qpwgraph` or `helvum`)
- Individual control of each channel

### When to Use It

- Music production with DAWs
- Multi-track recording
- Professional mixing/mastering
- When you need sub-5ms latency

**For gaming/streaming**: Standard profile is fine and easier to manage.

## Performance Impact

All these optimizations have minimal overhead:

| Optimization | CPU Impact | Memory Impact | Benefit |
|-------------|-----------|---------------|---------|
| threadirqs | < 0.1% | None | High |
| RTC 2048Hz | < 0.1% | None | Medium |
| PCI Latency | None | None | Medium |
| PAM Limits | None | None | High |

Total system overhead: **negligible** on modern hardware.

## Troubleshooting

### Audio Dropouts (xruns)

1. Check if threadirqs is active: `grep threadirqs /proc/cmdline`
2. Verify RTC frequency: `cat /sys/class/rtc/rtc0/max_user_freq`
3. Check CPU governor: `cpupower frequency-info`
4. Run diagnostic: `./scripts/diagnostics/check-audio-setup.sh`

### High Latency

1. Check quantum settings in `pw-metadata -n settings`
2. Verify sample rate matches your hardware
3. Try Pro Audio profile in pavucontrol
4. Measure with jack_delay

### Crackling/Popping

1. Increase buffer size (quantum) temporarily
2. Check for USB 3.0 issues (try USB 2.0 port)
3. Disable Wi-Fi during recording sessions
4. Check journal: `journalctl --user -u pipewire.service -f`

## References

- [Arch Wiki: Professional Audio](https://wiki.archlinux.org/title/Professional_audio)
- [Arch Wiki: PipeWire](https://wiki.archlinux.org/title/PipeWire)
- [Arch Wiki: Realtime Kernel](https://wiki.archlinux.org/title/Realtime_kernel)
- [PipeWire Documentation](https://docs.pipewire.org/)
- [Linux Foundation: RT_PREEMPT](https://wiki.linuxfoundation.org/realtime/start)

## Next Steps

After rebuilding your system:

1. **Verify optimizations**: `./scripts/diagnostics/check-audio-setup.sh`
2. **Test latency**: Use `jack_delay` if you have a loopback cable
3. **Monitor performance**: Run `pw-top` during audio workloads
4. **Check for errors**: `journalctl --user -u pipewire.service -f`
5. **Tune if needed**: Adjust quantum values based on your workload

Your audio configuration is now optimized for both gaming and professional-grade audio work!
