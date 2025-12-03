# Post-Reboot Audio Verification Guide

This guide walks you through verifying your real-time audio setup after rebuilding with musnix and rebooting to the RT kernel.

## Quick Checklist

- [ ] RT kernel loaded
- [ ] Realtime priority enabled
- [ ] PipeWire running
- [ ] rtirq service active
- [ ] Apogee Symphony Desktop detected
- [ ] pwvucontrol connects
- [ ] rtcqs analysis clean
- [ ] KVM switching works (optional)

---

## 1. Verify RT Kernel

```bash
# Check kernel version (should show "rt" in the version)
uname -r
# Expected: 6.11-rt or similar
```

✅ **Success**: Version contains `-rt`
❌ **Problem**: No `-rt` in version → Check boot menu or GRUB config

---

## 2. Check Realtime Priority Limits

```bash
# Check realtime priority limit
ulimit -r
# Expected: 99

# Check memlock limit
ulimit -l
# Expected: unlimited (or very large number)
```

✅ **Success**: `ulimit -r` shows 99
❌ **Problem**: Shows 0 → Check you're in the `audio` group:

```bash
groups | grep audio
```

---

## 3. Verify PipeWire is Running

```bash
# Check PipeWire service status
systemctl --user status pipewire

# Should show: Active: active (running)
```

✅ **Success**: PipeWire is active and running
❌ **Problem**: Failed or inactive → Check logs:

```bash
journalctl --user -u pipewire -n 50
```

---

## 4. Check rtirq Service

```bash
# Check rtirq service status
systemctl status rtirq

# View IRQ priorities
sudo /run/current-system/sw/bin/rtirq status
# Should show USB and sound IRQs with high priorities
```

✅ **Success**: Service active, USB/sound IRQs prioritized
❌ **Problem**: Service not found or inactive → Check musnix config

---

## 5. Detect Apogee Symphony Desktop

```bash
# List USB audio devices
lsusb | grep -i apogee
# Expected: Shows Apogee device

# Check ALSA devices
aplay -l | grep -i apogee
# Should list Apogee as a playback device

# Check PipeWire sees it
pw-cli list-objects | grep -i node.name | grep -i alsa
```

✅ **Success**: Apogee appears in all three commands
❌ **Problem**: Not detected → Try unplugging/replugging USB

---

## 6. Test pwvucontrol Connection

```bash
# Launch pwvucontrol
pwvucontrol
```

✅ **Success**: Opens without "Lost connection to PipeWire server" error
❌ **Problem**: Still shows error → Check:

```bash
# Verify PipeWire socket exists
ls -la /run/user/$(id -u)/pipewire-0

# Check WirePlumber
systemctl --user status wireplumber
```

---

## 7. Run rtcqs System Analysis

```bash
# Run the real-time configuration checker
rtcqs
```

This will analyze your system and provide recommendations. Common findings:

### Expected Passes ✅

- Realtime kernel
- RT priority limits
- Memlock limits
- CPU frequency governor (performance)
- Swappiness (should be low)

### Acceptable Warnings ⚠️

- CPU isolation (not required for most setups)
- IRQ threading (handled by rtirq)

### Should Fix ❌

- Power management issues
- USB autosuspend enabled (should be disabled)
- Network drivers causing latency

---

## 8. Test Audio Playback

```bash
# Test audio with speaker-test
speaker-test -D default -c 2 -t wav
# Press Ctrl+C to stop

# Or play a test file
pw-play /usr/share/sounds/alsa/Front_Center.wav
```

✅ **Success**: Hear audio through Apogee
❌ **Problem**: No sound → Check default device:

```bash
pactl info | grep "Default Sink"
# Change if needed:
pactl set-default-sink <apogee-sink-name>
```

---

## 9. Test KVM Switching (Optional)

Since you have a Level1Techs KVM:

### Test 1: Switch Away and Back

1. Switch KVM to MacBook Pro
2. Wait 5 seconds
3. Switch KVM back to NixOS
4. Check device reconnects:

```bash
# Watch for USB reconnection
journalctl -f | grep -i apogee
# (In another terminal, switch KVM)
```

### Test 2: PipeWire Auto-Reconnection

```bash
# Before switching, check devices
pw-cli list-objects | grep -i alsa

# Switch away and back

# Check again - Apogee should reappear within 2-3 seconds
pw-cli list-objects | grep -i alsa
```

✅ **Success**: Device reconnects within 2-3 seconds
❌ **Problem**: Takes longer or fails → May need to adjust KVM USB settings

---

## 10. Verify USB Controller Optimization

```bash
# Check PCI latency timer is set
sudo lspci -vvv -s 00:14.0 | grep -i latency
# Should show optimized latency value

# Verify USB autosuspend is disabled
cat /sys/bus/usb/devices/*/power/control | sort -u
# Should show "on" (not "auto")
```

---

## Performance Testing (Optional)

### Test 1: Latency with JACK

```bash
# If you use JACK applications
pw-jack jack_iodelay
# Should show <5ms round-trip latency
```

### Test 2: Check CPU Frequency

```bash
# CPU should be running at max frequency
watch -n 1 "cat /proc/cpuinfo | grep MHz"
# All cores should be at max frequency (not throttled)
```

### Test 3: Measure Audio Latency

```bash
# Check current PipeWire quantum
pw-metadata -n settings 0 clock.force-quantum
# Should match your ultraLowLatency setting:
# - 64 frames (ultraLowLatency=true) = ~1.3ms @ 48kHz
# - 256 frames (ultraLowLatency=false) = ~5.3ms @ 48kHz
```

---

## Troubleshooting

### PipeWire Won't Start

```bash
# Reset PipeWire completely
systemctl --user stop pipewire wireplumber pipewire-pulse
rm -rf ~/.local/state/pipewire
systemctl --user start pipewire wireplumber pipewire-pulse
```

### Apogee Not Detected

```bash
# Check USB power management
lsusb -t | grep -A 5 -i apogee
# Should show device and driver

# Force USB rescan
echo "1" | sudo tee /sys/bus/usb/devices/*/authorized
```

### Audio Crackling/Dropouts

```bash
# Check for xruns (buffer underruns)
journalctl --user -u pipewire -f
# Look for "xrun" or "underrun" messages

# If present, increase buffer size in host config:
# ultraLowLatency = false;  # Use 256 frames instead of 64
```

### rtirq Not Prioritizing IRQs

```bash
# Manually trigger rtirq
sudo systemctl restart rtirq

# Check IRQ assignments
sudo /run/current-system/sw/bin/rtirq status

# View actual IRQ priorities
ps -eLo pid,class,rtprio,pri,nice,cmd | grep -E "FF|RR" | sort -k4 -r
```

---

## Next Steps After Verification

Once everything is working:

1. **Test with your DAW** (if you use one)
   - Bitwig Studio, Reaper, Ardour, etc.
   - Configure to use PipeWire/JACK backend
   - Test recording and playback

2. **Optimize Sample Rate**
   - Set consistent 48kHz across all applications
   - Match Apogee's native sample rate

3. **Configure Audio Applications**
   - Set buffer size to match PipeWire quantum
   - Enable JACK compatibility if needed

4. **Monitor Performance**
   - Watch for xruns during recording
   - Check CPU usage with `htop`
   - Monitor temperature if running intensive sessions

5. **Document Your Settings**
   - Note what buffer sizes work best for your workflow
   - Record any application-specific tweaks

---

## Reference: Key Configuration Values

From your Jupiter host config:

```nix
audio = {
  enable = true;
  realtime = true;
  ultraLowLatency = true;  # 64 frames @ 48kHz = ~1.3ms

  usbAudioInterface = {
    enable = true;
    pciId = "00:14.0";  # Intel Raptor Lake USB 3.2
  };

  rtirq = true;
  dasWatchdog = true;
  rtcqs = true;
};
```

---

## Success Criteria

✅ **Your system is ready for professional audio when:**

- RT kernel is loaded (`uname -r` shows `-rt`)
- Realtime priority is 99 (`ulimit -r`)
- PipeWire is running without errors
- rtirq is prioritizing USB/sound IRQs
- Apogee Symphony Desktop is detected and working
- pwvucontrol connects without errors
- rtcqs shows mostly green/passing results
- KVM switching reconnects the Apogee within 2-3 seconds
- No audio dropouts during playback/recording

🎵 **You're ready to record!**

---

## Additional Resources

- **musnix Documentation**: <https://github.com/musnix/musnix>
- **PipeWire Wiki**: <https://wiki.archlinux.org/title/PipeWire>
- **rtcqs Tool**: <https://wiki.linuxaudio.org/wiki/system_configuration#rtcqs>
- **Your Audio Config**: `modules/nixos/features/desktop/audio.nix`
- **Host Config**: `hosts/jupiter/default.nix`

---

**Last Updated**: 2025-12-03 (after RT kernel + musnix setup)
