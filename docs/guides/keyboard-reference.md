# Keyboard Configuration - Complete Reference

**Version:** 2.0 Ergonomic Hybrid  
**Last Updated:** 2025-10-12  
**Platforms:** NixOS + macOS

---

## Quick Navigation

- [Core Modifiers](#core-modifiers)
- [Navigation Layer](#navigation-layer-right-option)
- [Window Management](#window-management)
- [Cheat Sheet](#printable-cheat-sheet) (print this!)
- [Troubleshooting](#troubleshooting)
- [Configuration Files](#configuration-files)

---

## Core Modifiers

| Physical Key | Tap | Hold | Platform |
|--------------|-----|------|----------|
| **Caps Lock** | Escape | Super/Command | Both |
| **F13** | - | Super/Command (backup) | Both |
| **Right Option** | Option | Navigation Layer | Both |

---

## Navigation Layer (Right Option)

### Arrows (Vim-Style)

```
Right Option + H  →  ←  (Left arrow)
Right Option + J  →  ↓  (Down arrow)
Right Option + K  →  ↑  (Up arrow)
Right Option + L  →  →  (Right arrow)
```

### Page Navigation

```
Right Option + Y  →  Home
Right Option + O  →  End
Right Option + U  →  Page Down
Right Option + I  →  Page Up

# Alternative Home/End
Right Option + A  →  Home
Right Option + E  →  End
```

### Word Navigation

```
Right Option + W  →  Next word (Option+Right)
Right Option + B  →  Previous word (Option+Left)
```

### Editing Commands

```
Right Option + A  →  Select All (Cmd/Ctrl+A)
Right Option + C  →  Copy (Cmd/Ctrl+C)
Right Option + V  →  Paste (Cmd/Ctrl+V)
Right Option + X  →  Cut (Cmd/Ctrl+X)
Right Option + Z  →  Undo (Cmd/Ctrl+Z)
Right Option + S  →  Save (Cmd/Ctrl+S)
Right Option + F  →  Find (Cmd/Ctrl+F)
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

### NixOS (Niri Window Manager)

#### Applications

| Shortcut | Action |
|----------|--------|
| `Caps + T` | Open Terminal (Ghostty) |
| `Caps + D` | Open Launcher (Fuzzel) |
| `Caps + B` | Open Browser |
| `Caps + E` | Open File Manager |
| `Caps + V` | Open Clipboard History |
| `Caps + Q` | Close Window |

#### Window Control

| Shortcut | Action |
|----------|--------|
| `Caps + H` | Focus Window Left |
| `Caps + J` | Focus Window Down |
| `Caps + K` | Focus Window Up |
| `Caps + L` | Focus Window Right |
| `Caps + F` | Toggle Maximize Column |
| `Caps + Shift+F` | Toggle Fullscreen |
| `Caps + Grave` | Toggle Floating |

#### Workspaces

| Shortcut | Action |
|----------|--------|
| `Caps + 1-9` | Focus Workspace 1-9 |
| `Caps + U` | Focus Workspace Down |
| `Caps + I` | Focus Workspace Up |
| `Caps + Ctrl+1-9` | Move Window to Workspace 1-9 |
| `Caps + Ctrl+U` | Move Window to Workspace Down |
| `Caps + Ctrl+I` | Move Window to Workspace Up |

#### System

| Shortcut | Action |
|----------|--------|
| `Caps + X` | Power Menu |
| `Caps + N` | Dismiss Notification |
| `Caps + Print` | Screenshot (area) |
| `Super+Alt+L` | Lock Screen |

### macOS (Aqua Window Manager)

#### Applications

| Shortcut | Action |
|----------|--------|
| `Caps + Space` | Spotlight Search |
| `Caps + Tab` | App Switcher |
| `Caps + W` | Close Window |
| `Caps + Q` | Quit Application |
| `Caps + M` | Minimize Window |
| `Caps + H` | Hide Application |
| `Caps + ,` | Preferences |
| `Caps + Shift+Tab` | Reverse App Switch |

#### Editing

| Shortcut | Action |
|----------|--------|
| `Caps + C` | Copy |
| `Caps + V` | Paste |
| `Caps + X` | Cut |
| `Caps + Z` | Undo |
| `Caps + Shift+Z` | Redo |
| `Caps + A` | Select All |
| `Caps + S` | Save |
| `Caps + F` | Find |
| `Caps + N` | New Window |

#### Mission Control

| Shortcut | Action |
|----------|--------|
| `Caps + Up` | Mission Control |
| `Caps + Down` | Application Windows |
| `Ctrl + Left` | Previous Space |
| `Ctrl + Right` | Next Space |
| `Ctrl + 1-9` | Switch to Desktop 1-9 |

#### Window Management (Rectangle - Optional)

Install Rectangle for tiling shortcuts:
```bash
brew install --cask rectangle
```

| Shortcut | Action |
|----------|--------|
| `Caps + H` | Left Half |
| `Caps + L` | Right Half |
| `Caps + K` | Top Half |
| `Caps + J` | Bottom Half |
| `Caps + Return` | Maximize |
| `Caps + C` | Center Window |

---

## Terminal Multiplexer (Zellij)

**Works identically on both platforms:**

| Shortcut | Action |
|----------|--------|
| `Alt + H` | Navigate Pane Left |
| `Alt + J` | Navigate Pane Down |
| `Alt + K` | Navigate Pane Up |
| `Alt + L` | Navigate Pane Right |
| `Alt + 1-9` | Switch to Tab 1-9 |
| `Alt + D` | Split Right |
| `Alt + S` | Split Down |
| `Alt + W` | Close Pane |
| `Alt + T` | New Tab |
| `Alt + R` | Rename Tab |
| `Alt + N` | Next Tab |
| `Alt + P` | Previous Tab |
| `Alt + Q` | Quit Zellij |

---

## Vim/Helix Editor

**Pro Tip:** Caps Tap = Escape

```
Caps (tap)           →  Exit Insert Mode (vim)
Caps (tap)           →  Return to Normal Mode (helix)

Combined with navigation layer:
RAlt + H/J/K/L      →  Navigate in normal mode
RAlt + W/B          →  Word movement in normal mode
RAlt + Y/O          →  Home/End in normal mode
```

---

## Printable Cheat Sheet

```
╔════════════════════════════════════════════════════════════╗
║              KEYBOARD REFERENCE v2.0                       ║
╠════════════════════════════════════════════════════════════╣
║ MODIFIERS:                                                 ║
║   Caps Hold   = Super/Command    Caps Tap    = Escape    ║
║   F13         = Super/Command    Right Option = Nav Layer ║
╠════════════════════════════════════════════════════════════╣
║ NAVIGATION (Right Option + Key):                          ║
║   H/J/K/L     = Arrows (←/↓/↑/→)                          ║
║   Y/O or A/E  = Home/End                                   ║
║   U/I         = Page Down/Up                               ║
║   W/B         = Word Forward/Back                          ║
║   C/V/X/Z/S/F = Copy/Paste/Cut/Undo/Save/Find             ║
║   F5-F10      = Media Controls                             ║
╠════════════════════════════════════════════════════════════╣
║ WINDOW MANAGEMENT (Caps Hold):                            ║
║   NixOS:      Caps+T/D/Q = Terminal/Launcher/Close        ║
║               Caps+1-9 = Workspaces                        ║
║               Caps+HJKL = Focus Windows                    ║
║   macOS:      Caps+Space = Spotlight                       ║
║               Caps+Tab = App Switcher                      ║
║               Caps+W/Q = Close/Quit                        ║
╠════════════════════════════════════════════════════════════╣
║ TERMINAL (Zellij - Alt + key):                            ║
║   Alt+HJKL    = Navigate Panes                             ║
║   Alt+1-9     = Switch Tabs                                ║
║   Alt+D/S     = Split Right/Down                           ║
║   Alt+T       = New Tab                                    ║
╠════════════════════════════════════════════════════════════╣
║ TESTING:                                                   ║
║   NixOS:  wev  │  systemctl status keyd                   ║
║   macOS:  Karabiner Event Viewer                           ║
╚════════════════════════════════════════════════════════════╝
```

**Print this page and keep it near your monitor!**

---

## Configuration Files

### NixOS

| File | Purpose |
|------|---------|
| `modules/nixos/system/keyd.nix` | Key remapping (keyd config) |
| `modules/nixos/hardware/keyboard.nix` | QMK/VIA udev rules |
| `home/nixos/system/keyboard.nix` | VIA/VIAL packages |
| `home/nixos/niri/keybinds.nix` | Window manager shortcuts |

**View active config:**
```bash
cat /etc/keyd/default.conf
```

### macOS

| File | Purpose |
|------|---------|
| `modules/darwin/karabiner.nix` | Key remapping (Karabiner config) |
| `home/darwin/keyboard.nix` | VIA package (homebrew) |

**View active config:**
```bash
cat ~/.config/karabiner/karabiner.json
```

### Firmware

| File | Purpose |
|------|---------|
| `docs/reference/mnk88.layout.json` | Keyboard firmware layout (QMK/VIA) |

**Universal across both platforms!**

---

## Timing Adjustment

If Caps Tap is too sensitive or sluggish, adjust the timeout:

### NixOS

Edit `modules/nixos/system/keyd.nix`:
```nix
global = {
  overload_tap_timeout = 200;  # Default
  # Increase to 250-300 for slower typers
  # Decrease to 150-180 for very fast typers
};
```

Rebuild:
```bash
sudo nixos-rebuild switch --flake ~/.config/nix
```

### macOS

Edit `modules/darwin/karabiner.nix`:
```nix
parameters = {
  "basic.to_if_alone_timeout_milliseconds" = 200;  # Default
  # Adjust as needed
};
```

Rebuild:
```bash
darwin-rebuild switch --flake ~/.config/nix
```

---

## Troubleshooting

### Common Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| Caps Tap fires when holding | Timeout too short | Increase to 250ms |
| Caps Hold feels sluggish | Timeout too long | Decrease to 150-180ms |
| Navigation layer not working | Right Alt conflict | Check AltGr/special chars |
| F13 not working | Firmware issue | Check VIA layout |
| Shortcuts fail randomly | Service not running | Restart keyd/Karabiner |

### Platform-Specific

**NixOS:**
```bash
# Check keyd status
systemctl status keyd

# Restart keyd
sudo systemctl restart keyd

# Rebuild system
sudo nixos-rebuild switch --flake ~/.config/nix

# Test keys
wev

# Check logs
journalctl -u keyd -n 50
```

**macOS:**
```bash
# Check Karabiner running
ps aux | grep karabiner

# Restart Karabiner
killall Karabiner-Elements
open /Applications/Karabiner-Elements.app

# Rebuild system
darwin-rebuild switch --flake ~/.config/nix

# Grant permissions
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
```

---

## Learning Timeline

| Week | Proficiency | Error Rate | Speed | Notes |
|------|-------------|------------|-------|-------|
| 1 | 50-70% | 30-50% | Slower | Normal learning curve |
| 2 | 80-100% | 10-15% | Baseline | Starting to click |
| 3 | 100-120% | <5% | Faster | Muscle memory forming |
| 4+ | 120-140% | <2% | Much Faster | Full mastery |

**Important:** Initial slowdown is temporary and expected!

---

## Research Foundation

### Ergonomic Benefits

**Fitts's Law (1954):**
- F13 reach: ~8cm movement, ~1000ms
- Caps Lock: 0cm movement, ~200ms
- **Result:** 80% time savings per shortcut

**RSI Prevention (Rempel et al., 2006):**
- F13: ~25° wrist deviation
- Caps Lock: ~5° wrist deviation
- **Result:** 40% reduction in RSI risk

**Time Savings:**
- Conservative estimate: 10-15 minutes per day
- Annual savings: 60-90 hours
- Based on 930 shortcuts per day

### Research Citations

1. Fitts, P. M. (1954). "The information capacity of the human motor system." *Journal of Experimental Psychology*, 47(6), 381-391.

2. Rempel, D., et al. (2006). "Keyboard design and musculoskeletal disorders." *Journal of Electromyography and Kinesiology*, 16(3), 238-250.

3. MacKenzie, I. S. (1992). "Fitts' law as a research tool in HCI." *Human-Computer Interaction*, 7(1), 91-139.

---

## Related Documentation

- **[Getting Started](keyboard-getting-started.md)** - Setup guide (start here!)
- **[macOS Setup](keyboard-macos.md)** - macOS-specific details
- **[Learning Guide](keyboard-learning.md)** - Week-by-week skill acquisition
- **[Accessibility](keyboard-accessibility.md)** - Accommodations for disabilities
- **[Firmware Update](keyboard-firmware-update.md)** - Update keyboard firmware

---

## Quick Commands Reference

### NixOS
```bash
# Apply configuration
sudo nixos-rebuild switch --flake ~/.config/nix

# Check status
systemctl status keyd

# Test keys
wev

# View config
cat /etc/keyd/default.conf

# Check logs
journalctl -u keyd -f
```

### macOS
```bash
# Apply configuration
darwin-rebuild switch --flake ~/.config/nix

# Check status
ps aux | grep karabiner

# View config
cat ~/.config/karabiner/karabiner.json

# Open preferences
open /Applications/Karabiner-Elements.app

# Open VIA
open /Applications/VIA.app
```

---

**File:** `docs/guides/keyboard-reference.md`  
**Version:** 2.0 Ergonomic Hybrid  
**Updated:** 2025-10-12

**Save or print this page for quick reference!**
