# Audio Configuration Edge Cases Analysis

## Issues Found

### 1. **Hardcoded Bridge Target** ⚠️

**Problem**: Bridge has hardcoded device name `alsa_output.usb-Apogee_Electronics_Corp_Symphony_Desktop-00.pro-output-0`. If device disconnects or name changes, games get no audio.

**Current Behavior**:

- Bridge fails silently (node.passive = true, ifexists/nofail flags)
- Games still route to bridge but get no audio
- No fallback mechanism

**Impact**: Games lose audio if Apogee disconnects

### 2. **No Fallback for Games** ⚠️

**Problem**: Games are forced to bridge via stream rules, but if Apogee disconnects, there's no fallback to Intel PCH or other devices.

**Current Behavior**:

- Games → Bridge → Apogee (if connected)
- Games → Bridge → Nothing (if Apogee disconnected)

**Impact**: Silent failure for games when Apogee unavailable

### 3. **Intel PCH Fallback Priority Too Low** ⚠️

**Problem**: Intel PCH has priority 1, which is extremely low. If Apogee disconnects, it might not be selected automatically.

**Current Behavior**:

- Apogee: Priority 100 (selected)
- Intel PCH: Priority 1 (might not auto-select)

**Impact**: No audio if Apogee disconnects and Intel PCH doesn't auto-select

### 4. **Bridge Priority Not Enforced in WirePlumber** ⚠️

**Problem**: Bridge priority (50) is set in module definition, but there's no WirePlumber rule to enforce it. This might cause conflicts.

**Current Behavior**:

- Bridge priority set in capture.props (50)
- No WirePlumber rule to enforce this
- Might conflict with other priority rules

**Impact**: Bridge might get wrong priority in some scenarios

### 5. **Bluetooth Priority Rule Syntax** ⚠️

**Problem**: Bluetooth priority rule uses `monitor.rules` with `bluez_output.*` pattern. Need to verify this matches actual Bluetooth sink names.

**Current Behavior**:

- Bluetooth sinks get priority 200 (higher than Apogee)
- Rule syntax might be incorrect

**Impact**: Bluetooth might not get proper priority

### 6. **Multiple Bluetooth Devices** ⚠️

**Problem**: If multiple Bluetooth devices connect, they all get priority 200. No mechanism to prefer one over another.

**Current Behavior**:

- All Bluetooth devices: Priority 200
- First connected or highest priority wins

**Impact**: Unpredictable behavior with multiple Bluetooth devices

### 7. **JACK Applications** ✅

**Status**: OK - JACK is enabled and applications can use PipeWire's JACK compatibility layer directly. They bypass PulseAudio routing.

### 8. **Rule Ordering** ✅

**Status**: OK - Rules are numbered correctly (10-*before 90-*), so they process in the right order.

## Fixes Applied

### ✅ Fix 1: Bridge Priority Rule Added

**Status**: FIXED

- Added explicit WirePlumber rule to set bridge priority to 50
- Ensures bridge priority matches module definition
- Prevents priority conflicts

### ✅ Fix 2: Intel PCH Priority Increased

**Status**: FIXED

- Changed Intel PCH priority from 1 to 10
- More likely to be selected as fallback if Apogee disconnects
- Still low enough to not interfere when Apogee is available

### ⚠️ Fix 3: Game Fallback (Known Limitation)

**Status**: DOCUMENTED (not fixed - by design)

- Games are forced to bridge, which requires Apogee
- If Apogee disconnects, games will have no audio
- This is intentional - games need the bridge for compatibility
- User must reconnect Apogee or manually select another sink for games

### ⚠️ Fix 4: Bluetooth Rule Syntax

**Status**: NEEDS VERIFICATION

- Bluetooth priority rule added (priority 200)
- Rule syntax uses `bluez_output.*` pattern
- Should be tested when Bluetooth device connects
- May need adjustment based on actual device names

### ⚠️ Fix 5: Hardcoded Bridge Target

**Status**: ACCEPTABLE LIMITATION

- Bridge targets specific Apogee device name
- If device name changes (unlikely), bridge will fail
- Bridge has `ifexists`/`nofail` flags to prevent crashes
- This is acceptable since device name is stable

## Current Priority Order (After Fixes)

| Device Type | Priority | Status | Notes |
|------------|----------|--------|-------|
| Bluetooth (when connected) | 200 | Auto-select | Higher than Apogee |
| Apogee Direct | 100 | Default | Regular apps |
| Generic ALSA | 50 | Fallback | Future devices |
| Bridge | 50 | Gaming only | Forced via rules |
| Intel PCH | 10 | Backup | Fallback if Apogee unavailable |
| NVIDIA HDMI | Disabled | N/A | Never used |

## Known Limitations

1. **Games require Apogee**: Games are forced to bridge → Apogee. If Apogee disconnects, games lose audio. This is by design for compatibility.

2. **No automatic game fallback**: Games cannot automatically fall back to Intel PCH because they need the bridge for multi-channel compatibility.

3. **Bluetooth priority**: Bluetooth devices get priority 200, which means they'll auto-select over Apogee when connected. This is intentional for convenience.

4. **Multiple Bluetooth devices**: If multiple Bluetooth devices connect, they all get priority 200. First connected or highest priority wins.

5. **Hardcoded device names**: Bridge targets specific Apogee device name. If name changes, bridge fails (unlikely in practice).

## Testing Recommendations

1. **Test Apogee disconnection**: Unplug Apogee and verify:
   - Regular apps fall back to Intel PCH (priority 10)
   - Games lose audio (expected - they need bridge)

2. **Test Bluetooth connection**: Connect Bluetooth device and verify:
   - Auto-selects (priority 200)
   - Regular apps route to Bluetooth
   - Games still use bridge (forced via rules)

3. **Test Intel PCH fallback**: With Apogee disconnected, verify:
   - Regular apps select Intel PCH (priority 10)
   - Audio works correctly

4. **Test bridge priority**: Verify bridge doesn't interfere with regular app routing:
   - Regular apps use Apogee direct (100), not bridge (50)
   - Games use bridge (forced via rules)
