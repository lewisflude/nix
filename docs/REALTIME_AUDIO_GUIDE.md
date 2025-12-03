# Real-Time Audio Guide

This guide covers real-time audio configuration using musnix for professional audio work with USB audio interfaces like the Apogee Symphony Desktop.

## Overview

This configuration uses [musnix](https://github.com/musnix/musnix) to optimize NixOS for real-time audio production, including:

- **RT Kernel**: Real-time Linux kernel with `CONFIG_PREEMPT_RT` patches
- **IRQ Priority Management**: rtirq prioritizes audio device interrupts
- **Low-Latency PipeWire**: Ultra-low latency (~1.3ms) for professional recording
- **USB Audio Optimizations**: Disabled autosuspend, optimized power management
- **Safety Features**: das_watchdog prevents RT process hangs
- **ZFS Compatible**: Tested with ZFS root filesystem

## Quick Start

### 1. Enable Real-Time Audio

In your host configuration (`hosts/<hostname>/default.nix`):

```nix
host.features.media = {
  enable = true;
  
  audio = {
    enable = true;
    realtime = true; # Enable RT kernel + musnix
    
    # Professional audio: 64 frames @ 48kHz = ~1.3ms latency
    ultraLowLatency = true;
    
    # USB audio interface (e.g., Apogee Symphony Desktop)
    usbAudioInterface = {
      enable = true;
      pciId = "00:14.0"; # Your USB controller PCI ID
    };
    
    # musnix features
    rtirq = true;        # IRQ priority management
    dasWatchdog = true;  # Safety: kills runaway RT processes
    rtcqs = true;        # Analysis tool
  };
};
```

### 2. Find Your USB Controller PCI ID

```bash
# List all USB controllers
lspci | grep -i usb

# Example output:
# 00:14.0 USB controller: Intel Corporation Device (rev 10)
#         ^^^^^^ This is your PCI ID
```

Update your config with the PCI ID (e.g., `"00:14.0"`).

### 3. Rebuild and Reboot

```bash
# Build the configuration
sudo nixos-rebuild switch

# Reboot to load RT kernel
sudo reboot
```

After reboot, verify RT kernel:
```bash
uname -r
# Should show something like: 6.11.0-rt7
```

## Configuration Options

### Audio Latency Settings

#### Ultra-Low Latency (Professional Recording)
```nix
audio.ultraLowLatency = true;
# - 64 frames @ 48kHz = ~1.3ms
# - Best for: Recording with live monitoring, live performance
# - CPU usage: Higher
```

#### Balanced Latency (General Use)
```nix
audio.ultraLowLatency = false;
# - 256 frames @ 48kHz = ~5.3ms
# - Best for: Mixing, mastering, streaming, gaming
# - CPU usage: Lower
```

### USB Audio Interface Options

```nix
audio.usbAudioInterface = {
  enable = true;  # Enable USB audio optimizations
  
  # PCI ID of USB controller (find with: lspci | grep -i usb)
  pciId = "00:14.0";  # Example: Intel xHCI controller
};
```

**What this does:**
- Sets PCI latency timer for USB controller
- Disables USB autosuspend for audio devices
- Disables USB wakeup events
- Adds Apogee-specific udev rules (Vendor ID: 0a07)

### musnix Features

```nix
audio.rtirq = true;  # IRQ priority management
```
- Prioritizes interrupts for: `rtc`, `usb`, `snd` (sound)
- Higher priority = lower IRQ number = faster response
- Priority range: 0 (lowest) to 90 (highest)

```nix
audio.dasWatchdog = true;  # Watchdog for RT processes
```
- Monitors RT process CPU usage
- Kills processes that consume 100% CPU for >15 seconds
- Prevents system hangs from buggy audio software

```nix
audio.rtcqs = true;  # Real-time analysis tool
```
- Installs `rtcqs` (realtime configuration quick scan)
- Analyzes system for real-time audio readiness
- Run with: `rtcqs`

## Verifying Your Setup

### 1. Check RT Kernel

```bash
# Should show kernel with "-rt" suffix
uname -r
```

### 2. Run rtcqs Analysis

```bash
rtcqs
```

This will check:
- ✅ RT kernel loaded
- ✅ User in `audio` group
- ✅ CPU frequency scaling (should be "performance")
- ✅ Swappiness (should be low, e.g., 10)
- ✅ Max RT priority (should be 99)

### 3. Check IRQ Priorities

```bash
# View rtirq status
sudo systemctl status rtirq

# Check current IRQ priorities
ps -eLo pid,cls,rtprio,pri,nice,cmd | grep -i "FF\|RR" | head -20
```

### 4. Check PipeWire Latency

```bash
# Current quantum (buffer size)
pw-metadata -n settings 0 clock.force-quantum

# Monitor PipeWire graph
pw-top
```

### 5. Check USB Audio Device

```bash
# List audio devices
aplay -l

# Check USB device power management
lsusb -t
# Look for your Apogee device

# Verify autosuspend is disabled
cat /sys/bus/usb/devices/*/power/control | grep -v "auto"
# Should show "on" for audio devices
```

## Apogee Symphony Desktop Specific

### Device Information
- **Interface**: USB 2.0 (high-speed)
- **Vendor ID**: 0x0a07 (Apogee Electronics)
- **Channels**: Up to 8x8 analog I/O
- **Sample Rates**: 44.1, 48, 88.2, 96, 176.4, 192 kHz
- **Class Compliant**: Yes (works without drivers)

### Optimal Settings

**For Recording/Live Monitoring:**
```nix
audio.ultraLowLatency = true;  # 64 frames = ~1.3ms
```
- Latency: ~1.3ms (round-trip: ~2.6ms)
- CPU usage: Higher
- Best for: Recording with zero-latency monitoring

**For Mixing/Production:**
```nix
audio.ultraLowLatency = false;  # 256 frames = ~5.3ms
```
- Latency: ~5.3ms (round-trip: ~10.6ms)
- CPU usage: Lower
- Best for: Mixing, mastering, plugin-heavy sessions

### Sample Rate Configuration

The Apogee Symphony Desktop supports up to 192 kHz. PipeWire is configured to allow:
- 44.1 kHz (CD quality)
- 48 kHz (video standard, recommended default)
- 96 kHz (high-resolution)
- 192 kHz (ultra-high-resolution)

PipeWire will automatically match your DAW's sample rate.

## DAW Configuration

### Reaper
```
Preferences → Audio → Device:
- Audio System: ALSA
- Input Device: hw:CARD=Symphony,DEV=0
- Output Device: hw:CARD=Symphony,DEV=0
- Request Sample Rate: 48000
- Request Block Size: 64 (ultra-low) or 256 (balanced)
```

### Bitwig Studio
```
Settings → Audio:
- Audio Device: PipeWire
- Sample Rate: 48000 Hz
- Device Buffer Size: 64 samples (ultra-low) or 256 (balanced)
```

### Ardour
```
Window → Audio/MIDI Setup:
- Audio System: ALSA
- Input Device: hw:Symphony
- Output Device: hw:Symphony
- Sample Rate: 48000
- Buffer Size: 64 (ultra-low) or 256 (balanced)
- Periods: 2
```

## Troubleshooting

### High CPU Usage / Xruns

**Symptoms:**
- Audio dropouts (xruns)
- DAW showing buffer overruns
- CPU spikes

**Solutions:**

1. **Increase buffer size** (reduce CPU load):
   ```nix
   audio.ultraLowLatency = false;  # Use 256 frames instead of 64
   ```

2. **Check CPU frequency scaling**:
   ```bash
   cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
   # Should show "performance" on all CPUs
   ```

3. **Monitor IRQ priorities**:
   ```bash
   sudo systemctl status rtirq
   ```

4. **Check for competing processes**:
   ```bash
   # Find processes using high CPU
   top -o %CPU
   ```

### USB Audio Not Detected

**Symptoms:**
- `aplay -l` doesn't show Apogee device
- No sound output

**Solutions:**

1. **Check USB connection**:
   ```bash
   lsusb | grep -i apogee
   # Should show: Bus XXX Device XXX: ID 0a07:XXXX Apogee Electronics
   ```

2. **Verify kernel modules**:
   ```bash
   lsmod | grep snd_usb_audio
   # Should show snd_usb_audio module loaded
   ```

3. **Check dmesg for errors**:
   ```bash
   dmesg | grep -i usb | grep -i audio
   ```

4. **Try different USB port**:
   - Use USB 2.0 port (not USB 3.0) if possible
   - Avoid USB hubs - connect directly to motherboard

### RT Kernel Not Loading

**Symptoms:**
- `uname -r` doesn't show "-rt" suffix
- System boots with standard kernel

**Solutions:**

1. **Check boot menu** (if using systemd-boot):
   ```bash
   # List available boot entries
   sudo bootctl list
   ```

2. **Force RT kernel selection**:
   - At boot, select the entry with "rt" in the name

3. **Check for kernel build errors**:
   ```bash
   # Rebuild and watch for errors
   sudo nixos-rebuild switch
   ```

### ZFS Compatibility Issues

**Symptoms:**
- Build fails with ZFS kernel module error
- System won't boot after enabling RT kernel

**Solutions:**

This shouldn't happen - ZFS compatibility is checked automatically. But if it does:

1. **Check ZFS compatibility**:
   ```bash
   # List available ZFS-compatible kernels
   nix eval --json .#nixosConfigurations.jupiter.config.boot.kernelPackages.kernel.version
   ```

2. **Use specific RT kernel version**:
   ```nix
   # In modules/shared/features/media/default.nix
   packages = pkgs.linuxPackages_6_11_rt;  # Instead of linuxPackages_latest_rt
   ```

## Performance Tuning

### Disable CPU Power Saving (Maximum Performance)

For the absolute lowest latency, disable CPU idle states:

```nix
# In your host configuration
boot.kernelParams = [
  "processor.max_cstate=1"  # Disable deep C-states
  "intel_idle.max_cstate=0" # Disable Intel idle driver C-states
  "idle=poll"               # Poll for work instead of halting CPU
];
```

**Warning**: This significantly increases power consumption and heat. Only use during recording sessions.

### Isolate CPU Cores for Audio

Reserve CPU cores exclusively for audio processing:

```nix
# Reserve cores 0-1 for system, 2-7 for audio work
boot.kernelParams = [
  "isolcpus=2-7"  # Isolate cores 2-7 (on 8-core system)
];
```

Then configure your DAW to use isolated cores.

### Custom IRQ Priorities

For advanced users, customize rtirq priorities:

```nix
# In modules/shared/features/media/default.nix
rtirq = {
  enable = true;
  nameList = "rtc usb snd";  # Device priority order (highest first)
  prioHigh = 90;             # Highest RT priority (max: 99)
  prioLow = 0;               # Lowest priority
};
```

## References

- [musnix Documentation](https://github.com/musnix/musnix)
- [Linux Audio Wiki - System Configuration](http://wiki.linuxaudio.org/wiki/system_configuration)
- [Real-Time Linux Kernel](https://wiki.linuxfoundation.org/realtime/start)
- [PipeWire Documentation](https://docs.pipewire.org/)
- [Apogee Symphony Desktop Manual](https://apogeedigital.com/products/symphony-desktop)
- [rtcqs - Real-Time Quick Scan](https://github.com/raboof/realtimeconfigquickscan)

## Quick Commands Reference

```bash
# Check RT kernel
uname -r

# Analyze system for RT audio
rtcqs

# Check IRQ priorities
sudo systemctl status rtirq

# Monitor PipeWire
pw-top

# List audio devices
aplay -l

# Check USB power management
lsusb -t

# Find USB controller PCI ID
lspci | grep -i usb

# Force PipeWire quantum (temporary)
pw-metadata -n settings 0 clock.force-quantum 64  # Ultra-low latency
pw-metadata -n settings 0 clock.force-quantum 256 # Balanced
pw-metadata -n settings 0 clock.force-quantum 0   # Reset to config default

# Monitor CPU frequency
watch -n1 'cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq'

# Check swappiness
cat /proc/sys/vm/swappiness  # Should be 10

# View audio group limits
ulimit -a
# max locked memory should be "unlimited"
# max rt priority should be 99
```
