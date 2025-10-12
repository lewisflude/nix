# Keyboard Quick Reference Card

**v2.0 Ergonomic Hybrid - Universal (NixOS & macOS)**

---

## Core Modifiers

| Physical Key | Tap | Hold | Platform |
|--------------|-----|------|----------|
| **Caps Lock** | Escape | Super/Command | Both |
| **F13** | - | Super/Command | Both |
| **Right Option** | Option | Navigation Layer | Both |

---

## Navigation Layer (Right Option + Key)

### Arrows (Vim-style)

```
Right Option + H  →  ←  (Left arrow)
Right Option + J  →  ↓  (Down arrow)
Right Option + K  →  ↑  (Up arrow)
Right Option + L  →  →  (Right arrow)
```

### Page/Line Navigation

```
Right Option + A  →  Home (start of line)
Right Option + E  →  End (end of line)
Right Option + U  →  Page Up
Right Option + I  →  Page Up (alternative)

Legacy aliases:
Right Option + Y  →  Home
Right Option + O  →  End
```

### Word Navigation

```
Right Option + W  →  Next word
Right Option + B  →  Previous word
```

### Editing

```
Right Option + C  →  Copy  (Cmd/Ctrl+C)
Right Option + V  →  Paste (Cmd/Ctrl+V)
Right Option + X  →  Cut   (Cmd/Ctrl+X)
Right Option + Z  →  Undo  (Cmd/Ctrl+Z)
Right Option + S  →  Save  (Cmd/Ctrl+S)
Right Option + F  →  Find  (Cmd/Ctrl+F)
```

### Media Controls

```
Right Option + F1   →  Brightness Down
Right Option + F2   →  Brightness Up
Right Option + F5   →  Volume Down
Right Option + F6   →  Volume Up
Right Option + F7   →  Previous Track
Right Option + F8   →  Play/Pause
Right Option + F9   →  Next Track
Right Option + F10  →  Mute
```

---

## Window Management

### NixOS (Niri)

```
Caps + T            Terminal (Ghostty)
Caps + D            Launcher (Fuzzel)
Caps + B            Browser
Caps + E            File Manager (Yazi)
Caps + V            Clipboard History
Caps + Q            Close Window
Caps + F            Maximize Column
Caps + Shift+F      Fullscreen
Caps + Grave        Toggle Floating

Caps + 1-9          Switch to Workspace 1-9
Caps + U/I          Workspace Down/Up
Caps + H/J/K/L      Focus Window Left/Down/Up/Right
Caps + Shift+H/J/K/L Move Window

Caps + X            Power Menu
Caps + N            Dismiss Notification
Caps + Print        Screenshot (area)
Super+Alt+L         Lock Screen
```

### macOS (Aqua)

```
Caps + Space        Spotlight Search
Caps + Tab          App Switcher
Caps + W            Close Window
Caps + Q            Quit App
Caps + M            Minimize
Caps + ,            Preferences
Caps + H            Hide App
Caps + Shift+Tab    Reverse App Switch

Control + 1-9       Switch Desktop/Space
Caps + Up           Mission Control
Caps + Down         App Windows
Control + Left/Right Switch Spaces

Common shortcuts (work with Caps):
Caps + C/V/X        Copy/Paste/Cut
Caps + Z            Undo
Caps + Shift+Z      Redo
Caps + A            Select All
Caps + S            Save
Caps + F            Find
Caps + N            New Window
```

---

## Terminal Multiplexer (Zellij - Both Platforms)

```
Alt + H/J/K/L       Navigate Panes (vim-style)
Alt + 1-9           Switch to Tab 1-9
Alt + D             Split Right
Alt + S             Split Down
Alt + W             Close Pane
Alt + T             New Tab
Alt + R             Rename Tab
Alt + N/P           Next/Previous Tab
Alt + Q             Quit
Alt + Esc           Lock (detach)
```

---

## Vim/Helix Editor

**Pro Tip:** Caps Lock tap = Escape

```
Caps Tap            Exit Insert Mode (vim)
Caps Tap            Return to Normal Mode (helix)

Combined with navigation layer:
Right Alt + H/J/K/L  Navigate in normal mode
Right Alt + W/B      Word movement in normal mode
```

---

## Platform-Specific Notes

### NixOS
- **Modifier name:** Super / Meta
- **Configuration:** `modules/nixos/system/keyd.nix`
- **Testing:** `wev` (shows KEY_LEFTMETA for Caps Hold)
- **Service:** `systemctl status keyd`

### macOS
- **Modifier name:** Command (⌘)
- **Configuration:** `modules/darwin/karabiner.nix`
- **Testing:** Karabiner Event Viewer
- **Service:** Karabiner-Elements (GUI app)

---

## Troubleshooting Quick Reference

### NixOS

```bash
# Check keyd status
systemctl status keyd

# Restart keyd
sudo systemctl restart keyd

# Rebuild system
sudo nixos-rebuild switch --flake ~/.config/nix

# Test keys
wev

# View config
cat /etc/keyd/default.conf

# Check logs
journalctl -u keyd -n 50
```

### macOS

```bash
# Check Karabiner running
ps aux | grep karabiner

# Restart Karabiner
killall Karabiner-Elements
open /Applications/Karabiner-Elements.app

# Rebuild system
darwin-rebuild switch --flake ~/.config/nix

# View config
cat ~/.config/karabiner/karabiner.json

# Grant permissions
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
```

---

## Timing Adjustment

If Caps Tap triggers accidentally or feels sluggish:

### NixOS

```nix
# Edit: modules/nixos/system/keyd.nix
global = {
  overload_tap_timeout = 200;  # Default
  # Increase to 250-300 for slower typers
  # Decrease to 150-180 for very fast typers
};
```

### macOS

```nix
# Edit: modules/darwin/karabiner.nix
parameters = {
  "basic.to_if_alone_timeout_milliseconds" = 200;
  # Adjust as needed
};
```

---

## Learning Timeline

| Week | Proficiency | Error Rate | Speed |
|------|-------------|------------|-------|
| 1 | 50-70% | 30-50% | Slower |
| 2 | 80-100% | 10-15% | Baseline |
| 3 | 100-120% | <5% | Faster |
| 4+ | 120-140% | <2% | Much Faster |

---

## Common Mistakes & Fixes

| Problem | Cause | Fix |
|---------|-------|-----|
| Caps Tap fires when holding | Timeout too short | Increase to 250ms |
| Caps Hold feels sluggish | Timeout too long | Decrease to 150-180ms |
| Navigation layer not working | Right Alt conflict | Check AltGr/special chars |
| F13 not working | Firmware issue | Check VIA layout |
| Shortcuts fail randomly | Service not running | Restart keyd/Karabiner |

---

## Print-Friendly Cheat Sheet

```
╔══════════════════════════════════════════════════════════╗
║         KEYBOARD QUICK REFERENCE v2.0                    ║
╠══════════════════════════════════════════════════════════╣
║ MODIFIERS:                                               ║
║   Caps Hold  = Super/Command    Caps Tap   = Escape     ║
║   F13        = Super/Command    Right Alt  = Nav Layer  ║
╠══════════════════════════════════════════════════════════╣
║ NAVIGATION (Right Alt + Key):                           ║
║   H/J/K/L    = Arrows (←/↓/↑/→)                         ║
║   A/E or Y/O = Home/End                                  ║
║   U/I        = Page Up                                   ║
║   W/B        = Word Forward/Back                         ║
║   C/V/X/Z/S/F = Copy/Paste/Cut/Undo/Save/Find           ║
║   F5-F10     = Media Controls                            ║
╠══════════════════════════════════════════════════════════╣
║ WINDOW MANAGEMENT:                                       ║
║   NixOS:     Caps+T/D/Q = Terminal/Launcher/Close       ║
║              Caps+1-9 = Workspaces                       ║
║              Caps+HJKL = Focus Windows                   ║
║   macOS:     Caps+Space = Spotlight                      ║
║              Caps+Tab = App Switcher                     ║
║              Caps+W/Q = Close/Quit                       ║
╠══════════════════════════════════════════════════════════╣
║ TERMINAL (Zellij):                                       ║
║   Alt+HJKL   = Navigate Panes                            ║
║   Alt+1-9    = Switch Tabs                               ║
║   Alt+D/S    = Split Right/Down                          ║
╠══════════════════════════════════════════════════════════╣
║ TESTING:                                                 ║
║   NixOS:  wev  │  systemctl status keyd                 ║
║   macOS:  Karabiner Event Viewer                         ║
╚══════════════════════════════════════════════════════════╝
```

---

## Related Documentation

- **[Quick Start](keyboard-quickstart.md)** - 5-minute setup guide
- **[Complete Reference](keyboard-reference.md)** - Detailed shortcuts
- **[Learning Curve](keyboard-learning-curve.md)** - Skill acquisition guide
- **[NixOS Setup](../KEYBOARD-README.md)** - NixOS-specific details
- **[macOS Setup](keyboard-macos.md)** - macOS-specific details
- **[Cross-Platform Guide](keyboard-cross-platform.md)** - Platform comparison
- **[Accessibility](keyboard-accessibility.md)** - Accommodations

---

**Save this page as a PDF or print for desk reference!**

**File:** `docs/guides/keyboard-quick-reference.md`  
**Version:** 2.0 Ergonomic Hybrid  
**Updated:** 2025-10-12
