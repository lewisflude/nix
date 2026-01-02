# Streaming Debug Guide - Steam Link & Moonlight Issues

## Problems Fixed

### 1. Steam Link (Apple TV) - Blank Screen

**Symptom**: Blank screen with cursor, UI sounds work
**Cause**: Steam using "Black Frame" capture on Wayland/Niri
**Status**: ⚠️ **Steam Link desktop streaming may not work on Niri/Wayland** - use Moonlight instead

### 2. Moonlight/Sunshine - Lock Screen

**Symptom**: Both Desktop and Steam buttons show lock screen
**Cause**: `swayidle` auto-locks after 5 minutes of idle
**Status**: ✅ **FIXED** - Auto-lock now disabled during streaming

## Changes Applied

### File: `home/nixos/apps/sunshine.nix`

1. **Changed capture display**: `output_name = 0` (DP-3 main monitor instead of dummy HDMI)
2. **Added prep-cmd hooks**: Auto-disable swayidle when streaming starts/stops

### File: `home/nixos/apps/swayidle.nix`

1. **Added streaming-mode command**: Manual control over auto-lock

## After Rebuild: Testing Steps

### Step 1: Verify Commands are Available

```bash
# Check streaming-mode is installed
which streaming-mode

# Test the command help
streaming-mode
```

**Expected output:**

```
Usage: streaming-mode {on|off}
  on  - Disable auto-lock for streaming
  off - Re-enable auto-lock
```

### Step 2: Test Manual Lock Control

```bash
# Disable auto-lock
streaming-mode on

# Verify swayidle stopped
systemctl --user status swayidle.service
# Should show: "Active: inactive (dead)"

# Re-enable auto-lock
streaming-mode off

# Verify swayidle started
systemctl --user status swayidle.service
# Should show: "Active: active (running)"
```

### Step 3: Unlock Your Screen

Before testing streaming, make sure screen is unlocked:

```bash
# Check if swaylock is running
pgrep swaylock

# If locked, unlock at your desktop
# Or kill it for testing:
pkill swaylock
```

### Step 4: Test Moonlight Desktop Streaming

1. **On Apple TV**: Open Moonlight app
2. **Select your PC** (jupiter)
3. **Click "Desktop"** button
4. **Expected**: Should see your unlocked desktop, NOT lock screen
5. **Verify**: Auto-lock should be disabled during session
6. **Exit Moonlight**
7. **Verify**: Run `systemctl --user status swayidle.service` - should be active again

### Step 5: Test Moonlight Steam Streaming

1. **On Apple TV**: Open Moonlight app
2. **Select your PC** (jupiter)
3. **Click "Steam Big Picture"** button
4. **Expected**: Steam Big Picture should launch
5. **Verify**: No lock screen interruptions
6. **Exit**
7. **Verify**: Auto-lock re-enabled

## Troubleshooting

### Issue: Still seeing lock screen in Moonlight

**Debug steps:**

```bash
# 1. Check if screen is actually locked
pgrep swaylock

# 2. Manually unlock
pkill swaylock

# 3. Check if swayidle stopped during streaming
systemctl --user status swayidle.service

# 4. Check Sunshine logs
journalctl --user -u sunshine -f
```

**Manual workaround:**

```bash
# Before connecting with Moonlight:
streaming-mode on

# After done streaming:
streaming-mode off
```

### Issue: Sunshine prep-cmd not working

Check Sunshine logs when launching apps:

```bash
tail -f ~/.config/sunshine/sunshine.log
```

Look for prep-cmd execution. Should see:

```
[info] Executing prep-cmd: systemctl --user stop swayidle.service
```

### Issue: Screen locks during streaming

**Check current timeout:**

```bash
# View swayidle config
systemctl --user cat swayidle.service
```

**Temporary increase timeout** (until reboot):

```bash
# Stop current swayidle
systemctl --user stop swayidle.service

# Start with longer timeout (30 minutes instead of 5)
swayidle -w timeout 1800 'swaylock -f' &
```

### Issue: Steam Link still blank

**This is expected** - Steam Link doesn't support Wayland desktop capture well.

**Options:**

1. ✅ **Use Moonlight** for desktop streaming (recommended)
2. ✅ **Use Steam Link for games only** (not desktop)
3. ❌ Desktop streaming via Steam Link on Niri won't work reliably

**Why games work but desktop doesn't:**

- Games run in their own rendering context (Xwayland/Gamescope)
- Steam can capture game windows directly
- Desktop capture requires compositor support Steam doesn't have

## Configuration Reference

### Current Sunshine Configuration

**Display Capture:** DP-3 (3440x1440 @ 164.90Hz)

- Change to `output_name = 1` to use HDMI-A-4 dummy display

**Encoder:** NVENC (NVIDIA RTX 4090)

**Capture Method:** KMS (Kernel Mode Setting)

**Apps Configured:**

1. **Desktop** - Full desktop with auto-lock disabled
2. **Steam Big Picture** - Gamescope wrapper with auto-lock disabled

### Current Swayidle Configuration

**Timeouts:**

- 300s (5 min) - Lock screen
- 600s (10 min) - Power off monitors

**Events:**

- `before-sleep` - Lock screen
- `after-resume` - Power on monitors

## Quick Reference Commands

```bash
# Disable auto-lock for streaming
streaming-mode on

# Re-enable auto-lock
streaming-mode off

# Check if screen is locked
pgrep swaylock

# Unlock screen (if locked)
pkill swaylock

# Check swayidle status
systemctl --user status swayidle.service

# View Sunshine logs
tail -f ~/.config/sunshine/sunshine.log

# Restart Sunshine
systemctl --user restart sunshine.service

# Check what display is being captured
cat ~/.config/sunshine/sunshine.conf | grep output_name
```

## Performance Notes

### Expected Latency (from logs)

- **Capture**: ~1.15ms (excellent)
- **Encode**: ~4.38ms (good - NVENC is fast)
- **Network**: ~1.18ms (local network)
- **Decode**: ~11.71ms (tvOS hardware decoding)

### If You Experience Issues

1. **High network latency**: Check WiFi signal on Apple TV
2. **Choppy video**: Check bandwidth limit in Sunshine settings
3. **Controller lag**: Verify PS5 controller is properly paired
4. **Audio issues**: Check PipeWire audio routing

## Additional Resources

- Sunshine documentation: <https://docs.lizardbyte.dev/projects/sunshine/>
- Moonlight protocol: <https://moonlight-stream.org/>
- Niri compositor: <https://github.com/YaLTeR/niri>

---

**Last Updated**: 2026-01-02
**System**: NixOS with Niri compositor, NVIDIA RTX 4090
