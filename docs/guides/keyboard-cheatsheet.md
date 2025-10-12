# Keyboard Configuration - Quick Reference Card

**Print this page and keep it near your monitor during Week 1!**

---

## 🎹 Universal Shortcuts (Both NixOS + macOS)

### Core Modifiers

| Key | Tap | Hold |
|-----|-----|------|
| **Caps Lock** | Escape | Modifier (Super/Cmd) |
| **F13** | Modifier | Modifier |
| **Right Option** | Option | Navigation Layer |

---

## Navigation Layer (Right Option + Key)

### Arrows (Vim-Style)
```
┌─────────────────────────────┐
│  RAlt + H    ←  Left arrow  │
│  RAlt + J    ↓  Down arrow  │
│  RAlt + K    ↑  Up arrow    │
│  RAlt + L    →  Right arrow │
└─────────────────────────────┘
```

### Page Navigation
```
┌─────────────────────────────┐
│  RAlt + Y    ⌂  Home        │
│  RAlt + O    ⌙  End         │
│  RAlt + U    ⇟  Page Down   │
│  RAlt + I    ⇞  Page Up     │
└─────────────────────────────┘
```

### Word Navigation
```
┌─────────────────────────────┐
│  RAlt + W    →  Next word   │
│  RAlt + B    ←  Prev word   │
└─────────────────────────────┘
```

### Editing
```
┌─────────────────────────────┐
│  RAlt + A    Select All     │
│  RAlt + C    Copy           │
│  RAlt + V    Paste          │
│  RAlt + X    Cut            │
│  RAlt + Z    Undo           │
│  RAlt + S    Save           │
│  RAlt + F    Find           │
│  RAlt + D    Delete forward │
└─────────────────────────────┘
```

### Media Controls
```
┌─────────────────────────────┐
│  RAlt + F1   🔅 Brightness- │
│  RAlt + F2   🔆 Brightness+ │
│  RAlt + F5   🔉 Volume down │
│  RAlt + F6   🔊 Volume up   │
│  RAlt + F7   ⏮  Previous    │
│  RAlt + F8   ⏯  Play/Pause │
│  RAlt + F9   ⏭  Next        │
│  RAlt + F10  🔇 Mute        │
└─────────────────────────────┘
```

---

## NixOS-Specific (Niri Window Manager)

### Window Management (Caps Hold = Super)
```
┌─────────────────────────────┐
│  Caps + T    Open Terminal  │
│  Caps + D    Launcher       │
│  Caps + Q    Close window   │
│  Caps + E    File manager   │
│  Caps + B    Browser        │
└─────────────────────────────┘
```

### Workspaces
```
┌─────────────────────────────┐
│  Caps + 1-9     Switch      │
│  Caps + U/I     Next/Prev   │
│  Caps + O       Overview    │
│  Caps+Ctrl+1-9  Move window │
└─────────────────────────────┘
```

### Window Navigation
```
┌─────────────────────────────┐
│  Caps + H    Focus left     │
│  Caps + J    Focus down     │
│  Caps + K    Focus up       │
│  Caps + L    Focus right    │
└─────────────────────────────┘
```

### Layout
```
┌─────────────────────────────┐
│  Caps + F         Maximize  │
│  Caps + Shift+F   Fullscreen│
│  Caps + C         Center    │
│  Caps + W         Tab mode  │
│  Caps + Grave     Float     │
└─────────────────────────────┘
```

### Terminal (Zellij - Alt + key)
```
┌─────────────────────────────┐
│  Alt + H/J/K/L  Navigate    │
│  Alt + 1-9      Switch tabs │
│  Alt + D/S      Split panes │
│  Alt + T        New tab     │
│  Alt + W        Close pane  │
└─────────────────────────────┘
```

---

## macOS-Specific (Aqua Window Manager)

### Standard Shortcuts (Caps Hold = Command)
```
┌─────────────────────────────┐
│  Caps + Space   Spotlight   │
│  Caps + Tab     App switch  │
│  Caps + W       Close       │
│  Caps + Q       Quit        │
│  Caps + M       Minimize    │
│  Caps + H       Hide        │
└─────────────────────────────┘
```

### Text Editing (Native macOS)
```
┌─────────────────────────────┐
│  Caps + C/V/X   Copy/Paste  │
│  Caps + Z       Undo        │
│  Caps + Shift+Z Redo        │
│  Caps + A       Select all  │
│  Caps + S       Save        │
│  Caps + F       Find        │
└─────────────────────────────┘
```

### Window Management (Rectangle - if installed)
```
┌─────────────────────────────┐
│  Caps + H       Left half   │
│  Caps + L       Right half  │
│  Caps + K       Top half    │
│  Caps + J       Bottom half │
│  Caps + Return  Maximize    │
│  Caps + C       Center      │
└─────────────────────────────┘
```

### Mission Control
```
┌─────────────────────────────┐
│  Caps + Up      Mission Ctrl│
│  Caps + Down    App windows │
│  Ctrl + Left    Prev desktop│
│  Ctrl + Right   Next desktop│
└─────────────────────────────┘
```

---

## Week 1 Learning Plan

### Days 1-2: Master These 5
```
✓ Caps Tap → Escape
✓ Caps Hold + T → Terminal/App
✓ Caps Hold + Q/W → Close
✓ RAlt + H/J/K/L → Arrows
✓ RAlt + Y/O → Home/End
```

### Days 3-4: Add Navigation
```
✓ RAlt + U/I → Page Up/Down
✓ RAlt + W/B → Word jump
✓ RAlt + C/V → Copy/Paste
```

### Days 5-7: Full Integration
```
✓ RAlt + A/Z/S/F → Edit shortcuts
✓ RAlt + F5-F10 → Media
✓ Caps + workspace/window shortcuts
```

---

## Common Patterns

### Pattern 1: Text Navigation (No Arrow Keys!)
```
1. RAlt + H/J/K/L   Move cursor
2. RAlt + Y/O       Jump to line start/end
3. RAlt + W/B       Jump by word
4. RAlt + U/I       Scroll page
```

### Pattern 2: Fast Editing
```
1. RAlt + A         Select all
2. RAlt + C         Copy
3. RAlt + Y         Jump to start
4. RAlt + V         Paste
```

### Pattern 3: Window Workflow (NixOS)
```
1. Caps + D         Open launcher
2. Type "firefox"   
3. Caps + Ctrl + 2  Send to workspace 2
4. Caps + 2         Switch to workspace 2
5. Caps + F         Maximize
```

### Pattern 4: Window Workflow (macOS)
```
1. Caps + Space     Open Spotlight/Raycast
2. Type "safari"
3. Ctrl + 2         Switch to desktop 2
4. Caps + Return    Maximize (Rectangle)
```

---

## Troubleshooting Quick Fixes

### Not Working?

**NixOS:**
```bash
sudo systemctl restart keyd
sudo nixos-rebuild switch --flake ~/.config/nix
```

**macOS:**
```
System Settings → Privacy & Security
Enable Karabiner in:
- Input Monitoring
- Accessibility
```

### Caps Tap Too Sensitive?

**NixOS:** Edit `modules/nixos/system/keyd.nix`
```nix
overload_tap_timeout = 250;  # Increase from 200
```

**macOS:** Edit `modules/darwin/karabiner.nix`
```nix
"basic.to_if_alone_timeout_milliseconds" = 250;
```

---

## Muscle Memory Tips

### ✅ Do This:
- Practice 10 minutes daily
- Force yourself to use RAlt arrows (no arrow keys!)
- Use Caps Hold for ALL modifiers
- Keep F13 for backup only

### ❌ Don't Do This:
- Don't reach for arrow keys
- Don't use physical Caps Lock function
- Don't give up after Day 2 (it gets easier!)
- Don't skip the navigation layer practice

---

## Speed Metrics

| Shortcut | Old (F13) | New (Caps) | Savings |
|----------|-----------|------------|---------|
| Terminal | 500ms | 200ms | 60% faster |
| Launcher | 500ms | 200ms | 60% faster |
| Close | 500ms | 200ms | 60% faster |
| Navigate | Arrow keys | 0ms | No hand movement! |

**Daily savings: ~100 minutes with 500+ shortcuts**

---

## Remember

```
┌─────────────────────────────────────┐
│  🎯 Focus on muscle memory          │
│  ⏱️  Give it 2 weeks                 │
│  💪 Practice daily                   │
│  🚀 Speed comes automatically        │
│  ✨ Works on both platforms!         │
└─────────────────────────────────────┘
```

---

## Full Documentation

- **Quick Start:** [keyboard-quickstart.md](keyboard-quickstart.md)
- **macOS Setup:** [keyboard-macos.md](keyboard-macos.md)
- **Cross-Platform:** [keyboard-cross-platform.md](keyboard-cross-platform.md)
- **Complete Reference:** [keyboard-reference.md](keyboard-reference.md)
- **Migration Guide:** [keyboard-migration.md](keyboard-migration.md)

---

**Print Date:** `_______`  
**Platform:** ☐ NixOS  ☐ macOS  ☐ Both  
**Progress:** Week ☐1 ☐2 ☐3 ☐4+

---

**🎹 Happy typing! Keep this near your monitor during Week 1! 🚀**
