# Keyboard Configuration Testing Guide

**Version:** 2.0 Ergonomic Hybrid
**Last Updated:** 2025-10-12

---

## Quick Test Checklist

### ✅ Test 1: Caps Lock Tap = Escape

**Expected:** Tapping Caps Lock should produce Escape (not toggle caps)

**How to test:**
1. Open a terminal or text editor
2. **Tap** Caps Lock quickly (don't hold)
3. Type some letters

**✓ Success:** Letters are lowercase (Escape was sent, not Caps Lock)
**✗ Fail:** Letters are UPPERCASE (Caps Lock is still functioning normally)

---

### ✅ Test 2: Caps Lock Hold = Super (Window Manager Commands)

**Expected:** Holding Caps Lock acts as the Super/Meta key

**How to test:**
1. **Hold** Caps Lock and press **T**
2. Should open a new terminal (Ghostty)

Other tests:
- `Caps (Hold) + D` → Should open launcher (Fuzzel)
- `Caps (Hold) + Q` → Should close focused window
- `Caps (Hold) + 1-9` → Should switch workspaces

**✓ Success:** Window manager commands work
**✗ Fail:** Nothing happens, or wrong actions occur

---

### ✅ Test 3: Right Alt + H/J/K/L = Arrow Keys

**Expected:** Holding Right Alt and pressing H/J/K/L moves the cursor

**How to test:**
1. Open a text editor with some text
2. **Hold Right Alt** and press:
   - `H` → Cursor moves **left** ←
   - `J` → Cursor moves **down** ↓
   - `K` → Cursor moves **up** ↑
   - `L` → Cursor moves **right** →

**✓ Success:** Cursor moves like arrow keys
**✗ Fail:** Strange characters appear, or nothing happens

---

### ✅ Test 4: Right Alt + Y/O = Home/End

**Expected:** Jump to start/end of line

**How to test:**
1. Open a text editor with a long line
2. Position cursor in the middle
3. **Hold Right Alt** and press:
   - `Y` → Jumps to **start** of line
   - `O` → Jumps to **end** of line

**✓ Success:** Cursor jumps to line boundaries
**✗ Fail:** Nothing happens or wrong behavior

---

### ✅ Test 5: Right Alt + U/I = Page Down/Up

**Expected:** Scroll full pages

**How to test:**
1. Open a long document or file
2. **Hold Right Alt** and press:
   - `U` → Scrolls **down** one page
   - `I` → Scrolls **up** one page

**✓ Success:** Page scrolls smoothly
**✗ Fail:** No scrolling or character insertion

---

### ✅ Test 6: Right Alt + C/V = Copy/Paste

**Expected:** Text editing shortcuts

**How to test:**
1. Select some text
2. **Hold Right Alt** + `C` (should copy)
3. Click elsewhere
4. **Hold Right Alt** + `V` (should paste)

**✓ Success:** Text copies and pastes
**✗ Fail:** Strange characters or nothing happens

---

## Advanced Testing Tools

### Option 1: Using `wev` (Wayland Event Viewer)

**Install:**
```bash
# Add to your system packages or run:
nix-shell -p wev
```

**Usage:**
```bash
wev
```

Then press keys and observe output:

```
# Expected outputs:
Caps Lock (hold)  → KEY_LEFTMETA (125)
Right Alt + H     → KEY_LEFT (105)
Right Alt + C     → KEY_LEFTCTRL + KEY_C
```

---

### Option 2: Using `evtest` (Low-level events)

**Install:**
```bash
nix-shell -p evtest
```

**Usage:**
```bash
sudo evtest
# Select your keyboard device (usually /dev/input/event*)
```

Press keys to see raw events:
- Caps Lock should show `KEY_CAPSLOCK` → transformed to `KEY_LEFTMETA`
- Right Alt should activate layer transformations

---

### Option 3: Check keyd Configuration

**View deployed config:**
```bash
cat /etc/keyd/default.conf
```

**Expected content:**
```ini
[ids]
*

[global]
overload_tap_timeout = 200

[main]
capslock = overload(super, esc)
f13 = leftmeta
rightalt = layer(nav)

[nav]
h = left
j = down
k = up
l = right
y = home
o = end
u = pagedown
i = pageup
...
```

---

## Troubleshooting

### Problem: Configuration file doesn't exist

**Solution:** Rebuild your NixOS system:
```bash
sudo nixos-rebuild switch --flake ~/.config/nix#jupiter
```

### Problem: keyd service not running

**Check status:**
```bash
systemctl status keyd
```

**Restart service:**
```bash
sudo systemctl restart keyd
```

**View logs:**
```bash
journalctl -u keyd -f
```

### Problem: Caps Tap triggers accidentally when holding

**Solution:** Increase timeout in `modules/nixos/system/keyd.nix`:
```nix
overload_tap_timeout = 250; # Increase from 200
```

Then rebuild.

### Problem: Right Alt layer not working

**Possible causes:**
1. AltGr/Compose key conflicts
2. Application-specific key bindings overriding
3. keyd not intercepting the keyboard

**Debug:**
```bash
# Check if keyd is seeing the keyboard
journalctl -u keyd --since "5 minutes ago" | grep DEVICE
```

---

## Testing Checklist Summary

| Test | Keys | Expected Result | Status |
|------|------|-----------------|--------|
| 1 | Caps Tap | Escape (no caps) | ☐ |
| 2 | Caps Hold + T | Terminal opens | ☐ |
| 3 | RAlt + H/J/K/L | Arrow movement | ☐ |
| 4 | RAlt + Y/O | Home/End jump | ☐ |
| 5 | RAlt + U/I | Page scroll | ☐ |
| 6 | RAlt + C/V | Copy/Paste | ☐ |

---

## Next Steps

If **all tests pass:** ✅ You're ready! See [keyboard-quickstart.md](keyboard-quickstart.md)

If **tests fail:**
1. Check that keyd is running: `systemctl status keyd`
2. Verify config exists: `cat /etc/keyd/default.conf`
3. Rebuild if needed: `sudo nixos-rebuild switch --flake ~/.config/nix`
4. Check logs: `journalctl -u keyd -n 50`

---

## Quick Commands Reference

```bash
# Test script
~/.config/nix/scripts/test-keyboard.sh

# View key events
wev

# Check keyd status
systemctl status keyd

# View live logs
journalctl -u keyd -f

# Restart keyd
sudo systemctl restart keyd

# Rebuild system
sudo nixos-rebuild switch --flake ~/.config/nix
```

---

**File:** `docs/guides/keyboard-testing.md`
**Version:** 2.0 Ergonomic Hybrid
**Updated:** 2025-10-12

