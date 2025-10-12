# Optimal Winkeyless Keyboard Usage Guide

## The Core Philosophy: Caps Lock is Your New Best Friend

Since you don't have physical Win/Super keys, **Caps Lock becomes your primary modifier** through the Layer Tap feature.

---

## Daily Usage Patterns

### 1. **Caps Lock Layer Tap** - The Key to Everything

```
Tap Caps Lock     → Caps Lock (normal)
Hold Caps Lock    → Layer 1 (function layer)
```

**This is the most important feature!** Holding Caps Lock gives you:
- Navigation (Home/End/PgUp/PgDn on arrow keys)
- Media controls (on F1-F12)
- RGB controls
- Quick access to function keys

### 2. **The GUI/Super Keys ARE There** (Positions 86 & 90)

Your layout **does** have Cmd/Super keys:
- **Position 86**: Left GUI/Cmd (between Left Alt and Space)
- **Position 90**: Right GUI/Cmd (right side of spacebar)

**On your physical keyboard:**
- These are probably where the "Windows key would be" on a standard board
- On winkeyless TKL, these might be **extra 1u keys in the bottom row**
- Check your keyboard - you likely have small keys there!

---

## NixOS + Niri Optimal Setup

### Window Management Strategy

Since you're using **Niri** (tiling Wayland compositor), here's the optimal approach:

#### Option A: Use Caps Hold as "Pseudo-Super" (Recommended)

Create Niri bindings that work with **Caps + other keys**:

```nix
# home/nixos/niri/keybinds.nix
{
  programs.niri.settings.binds = {
    # Navigation with Caps Hold (already in firmware!)
    # Caps + H/J/K/L for vim-style window focus
    # These work because Caps Hold = Layer 1
    
    # Use F13 as your "super key" for Niri
    "F13+H".action.focus-window-left;
    "F13+J".action.focus-window-down;
    "F13+K".action.focus-window-up;
    "F13+L".action.focus-window-right;
    
    # Workspaces
    "F13+1".action.focus-workspace = 1;
    "F13+2".action.focus-workspace = 2;
    "F13+3".action.focus-workspace = 3;
    # ... etc
    
    # Common actions
    "F13+Return".action.spawn = ["alacritty"];
    "F13+D".action.spawn = ["fuzzel"];  # launcher
    "F13+Q".action.close-window;
    
    # Use F14-F16 for quick actions
    "F14".action.screenshot;
    "F15".action.spawn = ["your-scratchpad-terminal"];
    "F16".action.toggle-fullscreen;
  };
}
```

#### Option B: Use Physical GUI Key (if accessible)

If your keyboard has a small key at position 86/90:

```nix
{
  programs.niri.settings.binds = {
    # Standard Super-based bindings
    "Mod+H".action.focus-window-left;
    "Mod+J".action.focus-window-down;
    "Mod+K".action.focus-window-up;
    "Mod+L".action.focus-window-right;
    
    # Workspaces
    "Mod+1".action.focus-workspace = 1;
    # ... etc
  };
}
```

### Navigation Tips for Niri

1. **Caps + Arrow Keys** = Home/End/PgUp/PgDn (built into firmware)
2. **F13** = Your "super" launcher key
3. **F14-F16** = Quick access actions (screenshot, scratchpad, etc.)

---

## macOS Optimal Setup

macOS is actually **easier** for winkeyless because Cmd is just Opt+Cmd pattern:

### Primary Workflow

1. **Cmd keys exist** at positions 86 & 90 (check your spacebar area)
2. **Use Cmd normally** for macOS shortcuts (Cmd+C, Cmd+V, etc.)
3. **F13-F16** for custom power user shortcuts

### Recommended macOS Shortcuts (System Settings → Keyboard → Shortcuts)

```
F13 → Scratchpad Terminal
F14 → Screenshot to Clipboard (default)
F15 → Focus/Do Not Disturb toggle
F16 → Mission Control (default)

Shift+F13 → Window Manager (Rectangle/Amethyst)
Shift+F14 → Raycast/Alfred
Shift+F15 → Quick Note
```

### Window Management on macOS

If you use **Rectangle** or **Amethyst**:

```
# Use Caps + other keys for window management
Caps+H → Left Half
Caps+L → Right Half
Caps+K → Top Half
Caps+J → Bottom Half
Caps+F → Fullscreen

# Or bind to F13-F16
F13 → Trigger Rectangle mode
F14 → Next display
F15 → Center window
F16 → Maximize
```

### Terminal Power User (macOS)

In your terminal (Alacritty/iTerm2/Kitty):

```
Cmd+T        → New tab (native)
Cmd+W        → Close tab (native)
Caps+PgUp    → Scroll up (firmware layer)
Caps+PgDn    → Scroll down (firmware layer)
F13          → Toggle tmux/zellij
```

---

## Cross-Platform Muscle Memory

### Universal Shortcuts (Same on Both)

| Action | Keys | Works On |
|--------|------|----------|
| Navigate text | Caps + Arrows | Both (Home/End/PgUp/PgDn) |
| Media control | Caps + F7/F8/F9 | Both (Prev/Play/Next) |
| Volume | Caps + F5/F6 | Both |
| Brightness | Caps + F1/F2 | macOS (ignored on Linux) |
| RGB control | Caps + F11/F12 | Both (if RGB keyboard) |
| Screenshot | F14 or RShift+F14 | Both (need to bind) |
| Launcher | F13 | Both (need to bind) |

### Text Editing Without Home/End Keys

Since navigation keys are on Layer 1 (Caps Hold):

```
Caps + Left Arrow  → Home (start of line)
Caps + Right Arrow → End (end of line)
Caps + Up Arrow    → Page Up
Caps + Down Arrow  → Page Down

# In Vim/Neovim (you probably use these already)
H/J/K/L → Navigate
0/$     → Start/End of line
```

---

## Advanced Tips

### 1. Layer 2 (Right Shift Hold) Usage

This is currently mostly empty. You could use it for:

```
RShift + Number Row → F13-F24 (more function keys!)
RShift + Q/W/E/R   → Launch specific apps
RShift + A/S/D/F   → Workspace/Desktop switching
RShift + Z/X/C/V   → Clipboard history shortcuts
```

### 2. Vim-Style Everything

Since you're on NixOS with Niri, embrace vim bindings everywhere:

**Browser (Vimium/Tridactyl)**
```
F13 → Toggle Vimium
Caps + H/J/K/L → Navigate (via firmware + browser extension)
```

**File Manager**
```
H/J/K/L → Navigate
Caps + H → Parent directory
Caps + L → Open directory
```

### 3. Zellij/Tmux Integration

Your `zellij-config.kdl` could leverage F13-F16:

```kdl
keybinds {
    shared {
        bind "F13" { SwitchToMode "Normal"; }
        bind "F14" { NewPane; }
        bind "F15" { NewTab; }
        bind "F16" { ToggleFloatingPanes; }
    }
}
```

### 4. Caps Lock Alternatives

If you find yourself accidentally hitting Caps:

**Option A**: Disable Caps entirely, make it always Layer 1:
```
Position 51: MO(1) instead of LT(1,KC_CAPS)
```

**Option B**: Make it require longer hold:
- Adjust tapping term in QMK (if you can recompile firmware)
- Default is usually 200ms

### 5. Make F13 Your "Hyper Key"

F13 is rarely used by any application, making it perfect:

**NixOS:**
```nix
# Bind F13 globally in Niri
"F13".action.spawn = ["your-launcher"];
"F13+Shift".action.spawn = ["your-scratchpad"];
```

**macOS:**
```bash
# In Hammerspoon or Karabiner-Elements
F13 → Trigger custom modal mode
  Then: H/J/K/L → Window management
        1-9 → Launch apps
        Etc.
```

---

## Recommended Daily Workflow

### Morning Routine

1. **macOS:**
   - `Caps + F1/F2` → Adjust brightness
   - `F13` → Open Raycast/Alfred
   - `Cmd + Space` → Spotlight (if you use it)
   - Start working with normal Cmd-based shortcuts

2. **NixOS:**
   - `F13` → Launch Fuzzel/Rofi
   - `F13 + 1/2/3` → Switch workspaces
   - `F13 + Enter` → Terminal
   - Work in Niri with F13-based bindings

### Text Editing

```
Caps + Arrows → Navigate by page/line ends
Caps + H/J/K/L → Could map to word jumping (if you add QMK macros)
Ctrl + Arrows → Word jumping (system default)
```

### Media Control

```
Caps + F8 → Play/Pause (universal)
Caps + F7 → Previous (universal)
Caps + F9 → Next (universal)
Caps + F5/F6 → Volume (universal)
Caps + F10 → Mute (universal)
```

---

## What to Do Next

### 1. Check Your Physical Keys

Look at your keyboard bottom row around the spacebar:
- Is there a small 1u key left of space? → That's Left GUI (Cmd/Super)
- Is there a small 1u key right of space? → That's Right GUI (Cmd/Super)

If these keys exist physically, **use them as your primary Super/Cmd keys!**

### 2. Start Simple

Week 1:
- Master **Caps Hold + Arrows** for navigation
- Use **Caps + F8** for media play/pause
- Get comfortable with **F13** as launcher

Week 2:
- Add **F14-F16** custom shortcuts
- Practice **Caps + F1-F12** for media/RGB
- Build muscle memory for your most-used commands

Week 3:
- Customize Layer 2 (Right Shift hold) for advanced shortcuts
- Add application-specific F13-F16 bindings
- Optimize your most common workflows

### 3. Document Your Layout

Create a cheat sheet:
```
F13    = Launcher
F14    = Screenshot
F15    = Scratchpad
F16    = Mission Control / Workspaces

Caps Hold = Function Layer
  + Arrows = Home/End/PgUp/PgDn
  + F8 = Play/Pause
  + F5/F6 = Volume
```

Keep it near your monitor for the first week!

---

## Bottom Line

**Your winkeyless layout is actually MORE ergonomic because:**

1. ✅ Caps Lock is easier to reach than a far-left Super key
2. ✅ F13-F16 give you extra bindable keys most keyboards don't have
3. ✅ Layer 1 keeps navigation under your fingers (Caps + Arrows)
4. ✅ You likely DO have small Cmd/Super keys near spacebar
5. ✅ Consistent across both macOS and Linux

**The key is training yourself to:**
- **Hold Caps** instead of reaching for Home/End/PgUp/PgDn
- **Use F13** as your primary "launch things" key
- **Use F14-F16** for your top 3 most-used actions

You'll be faster than people with traditional layouts within 2 weeks!
