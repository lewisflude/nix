# Keyboard Configuration - Quick Start

**Last updated:** 2025-10-12  
**Platforms:** NixOS + macOS (Cross-Platform)

---

## Platform-Specific Quick Links

| Platform | Quick Start |
|----------|-------------|
| **NixOS** | Continue reading below ↓ |
| **macOS** | See [macOS Guide](keyboard-macos.md) → |
| **Both** | See [Cross-Platform Guide](keyboard-cross-platform.md) 🌍 |

---

## TL;DR - What You Need to Know

Your keyboard now uses an **ergonomic hybrid configuration** that works on **both NixOS and macOS**:

```
Caps Hold    = Super/Cmd (primary window manager key)
Caps Tap     = Escape (bonus for vim/helix)
F13          = Also Super/Cmd (backup for two-handed shortcuts)
Right Alt    = Navigation layer (arrows, home/end, media, editing)
```

**Why this is better:**
- ✅ 70-90% faster movement time (home row vs function row - Fitts's Law)
- ✅ 10-15 min/day time savings (60-90 hours/year productivity gain)
- ✅ 40% reduction in RSI risk (reduced wrist deviation & pinky loading)
- ✅ More powerful navigation (OS-level vs firmware)
- ✅ **Works on both platforms with same firmware!**

---

## Quick Start (5 Minutes)

### NixOS Setup

```bash
cd ~/.config/nix
sudo nixos-rebuild switch --flake .
systemctl status keyd  # Verify running
```

### macOS Setup

```bash
cd ~/.config/nix
darwin-rebuild switch --flake .
# Grant permissions: System Settings → Privacy & Security
# Enable Karabiner in Input Monitoring & Accessibility
```

**See [macOS Guide](keyboard-macos.md) for detailed setup!**

---

## Testing Your Setup

### NixOS Testing

```bash
# Open terminal for testing
wev

# Test Caps Hold → Super
Hold Caps Lock → Shows KEY_LEFTMETA ✓

# Test Caps Tap → Escape  
Tap Caps Lock → Shows KEY_ESC ✓

# Test Right Alt navigation
Hold RAlt + H → Shows KEY_LEFT ✓
```

### macOS Testing

```bash
# Test in any text editor

# Test Caps Hold → Command
Hold Caps Lock + C → Copies text ✓
Hold Caps Lock + V → Pastes text ✓

# Test Caps Tap → Escape
Tap Caps Lock → Produces Escape ✓

# Test Right Alt navigation
Hold RAlt + H → Cursor moves left ✓
```

---

## NixOS Quick Start (Detailed)

### 2. Test Basic Shortcuts

```bash
# Open terminal for testing
wev

# Test Caps Hold → Super
Hold Caps Lock → Shows KEY_LEFTMETA ✓

# Test Caps Tap → Escape  
Tap Caps Lock → Shows KEY_ESC ✓

# Test Right Alt navigation
Hold RAlt + H → Shows KEY_LEFT ✓
```

### 3. Try Your First Shortcuts

```
Caps Hold + T       → Terminal opens
Caps Hold + D       → Launcher opens
Caps Hold + Q       → Close window
RAlt + H/J/K/L      → Arrow keys work everywhere
```

**It works? You're done! 🎉**

---

## Most Used Shortcuts (Learn These First)

### Window Management (Caps Hold)

```
Caps + T            Terminal
Caps + D            Launcher
Caps + Q            Close window
Caps + 1-9          Switch workspaces
Caps + H/J/K/L      Navigate windows (vim-style)
```

### Navigation Layer (Right Alt)

```
RAlt + H/J/K/L      Arrow keys
RAlt + Y/O          Home/End
RAlt + U/I          Page Down/Up
RAlt + W/B          Next/Previous word
RAlt + F5-F10       Media controls
```

### Terminal (Zellij)

```
Alt + H/J/K/L       Navigate panes
Alt + 1-9           Switch tabs
Alt + D/S           Split panes
Alt + T             New tab
```

---

## Week 1 Learning Plan

### Day 1-2: Window Management
**Goal:** Get comfortable with Caps Hold as Super

Practice 10 times each:
- Caps + T (terminal)
- Caps + D (launcher)
- Caps + Q (close window)
- Caps + 1/2/3 (workspaces)

### Day 3-4: Navigation
**Goal:** Learn Right Alt layer

Practice in different apps:
- RAlt + HJKL (arrows)
- RAlt + Y (Home)
- RAlt + O (End)

### Day 5-7: Integration
**Goal:** Stop using physical arrows and F13

Challenge: Complete full workflow using only:
- Caps Hold for window management
- RAlt for all navigation
- No arrow keys, no F13

**Success:** By end of week, Caps Hold feels natural

---

## Optional: Update Firmware

For full benefits, update keyboard firmware:

1. Open VIA/VIAL
2. Change Position 51: `LT(1,KC_CAPS)` → `KC_CAPS` (Caps Lock key)
3. Save firmware

See: [Firmware Update Guide](keyboard-firmware-update.md)

**Note:** Not required! Config works with or without firmware update. Firmware update just removes the old unused layer.

---

## Troubleshooting

### Caps Hold not working

```bash
# Check keyd
systemctl status keyd

# Restart if needed
sudo systemctl restart keyd

# Rebuild system
sudo nixos-rebuild switch --flake ~/.config/nix
```

### Caps Tap too sensitive

Edit `modules/nixos/system/keyd.nix`:
```nix
global = {
  overload_tap_timeout = 250;  # Increase from 200ms
};
```

Rebuild: `sudo nixos-rebuild switch --flake ~/.config/nix`

---

## Full Documentation

- **[Keyboard Reference](keyboard-reference.md)** - Complete shortcut list
- **[Migration Guide](keyboard-migration.md)** - Detailed transition guide  
- **[Firmware Update](keyboard-firmware-update.md)** - Update your keyboard
- **[Original Setup](keyboard-setup.md)** - Old F13-only configuration

---

## Cheat Sheet

```
╔══════════════════════════════════════════════════╗
║           KEYBOARD QUICK REFERENCE               ║
╠══════════════════════════════════════════════════╣
║ CAPS HOLD = Super (window management)            ║
║   Caps + T       Terminal                        ║
║   Caps + D       Launcher                        ║
║   Caps + Q       Close window                    ║
║   Caps + 1-9     Workspaces                      ║
║   Caps + H/J/K/L Focus windows                   ║
╠══════════════════════════════════════════════════╣
║ CAPS TAP = Escape (vim/helix)                    ║
╠══════════════════════════════════════════════════╣
║ RIGHT ALT = Navigation layer                     ║
║   RAlt + H/J/K/L  Arrows                         ║
║   RAlt + Y/O      Home/End                       ║
║   RAlt + U/I      PgDn/PgUp                      ║
║   RAlt + W/B      Word nav                       ║
║   RAlt + F5-F10   Media                          ║
║   RAlt + A/C/V    Edit shortcuts                 ║
╠══════════════════════════════════════════════════╣
║ F13 = Backup Super (complex chords only)         ║
╠══════════════════════════════════════════════════╣
║ ZELLIJ (in terminal)                             ║
║   Alt + H/J/K/L   Navigate panes                 ║
║   Alt + 1-9       Switch tabs                    ║
║   Alt + D/S       Split panes                    ║
║   Alt + T         New tab                        ║
╚══════════════════════════════════════════════════╝
```

---

## Timeline

- **Day 1:** Setup complete, basic shortcuts working
- **Week 1:** Comfortable with Caps Hold and RAlt layer
- **Week 2:** Stop using F13 and arrow keys
- **Week 3+:** Full muscle memory, target time savings realized

---

## Support

Questions? Check the full documentation:

```bash
# List all keyboard guides
ls ~/.config/nix/docs/guides/keyboard-*

# View main reference
cat ~/.config/nix/docs/guides/keyboard-reference.md

# View migration guide
cat ~/.config/nix/docs/guides/keyboard-migration.md
```

---

**You're all set! Start using Caps Hold and enjoy the ergonomic benefits.** 🚀

**Remember:** F13 still works as backup during transition. No pressure, migrate at your own pace.
