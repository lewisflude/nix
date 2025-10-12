# Niri + Winkeyless Keyboard Setup

## Current Situation

Looking at your `keybinds.nix`, you're using **`Mod`** as your primary modifier. 

On your winkeyless keyboard, you have **three options** for what `Mod` should be:

---

## Option 1: Use Physical GUI Key (Best if accessible)

**Check positions 86 & 90 on your keyboard** - these are mapped to `KC_LGUI` and `KC_RGUI`.

If you can reach these comfortably:

```nix
# No changes needed! Your current config works perfectly.
# Just use the physical Cmd/Super keys at positions 86/90
```

**Benefits:**
- ✅ Existing keybinds all work as-is
- ✅ Standard Linux desktop experience
- ✅ Easy to explain to others

**Check your keyboard:** Look for small 1u keys in the bottom row, typically:
```
[Ctrl] [Alt] [GUI] [      Space      ] [GUI] [Alt] [Ctrl]
                ↑                        ↑
           Position 86              Position 90
```

---

## Option 2: Use F13 as Mod (Recommended for winkeyless)

If positions 86/90 are hard to reach or don't exist physically, **rebind Mod to F13**:

```nix
# Add to your Niri config
{
  programs.niri.settings = {
    # Option A: Set input config to treat F13 as Mod
    input = {
      keyboard = {
        xkb = {
          # Map F13 to Super
          options = "altwin:super_win";  # This won't work for F13
        };
      };
    };
  };
}
```

Actually, Niri doesn't have a way to remap keys directly. You'd need to do this at the **system level**:

```nix
# modules/nixos/system/keyboard-layout.nix
{ ... }: {
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = [
      # Can't directly map F13 to Super via XKB options
    ];
  };
  
  # Better approach: Use keyd or evremap
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          f13 = "leftmeta";  # F13 → Super/Meta
        };
      };
    };
  };
}
```

**Benefits:**
- ✅ F13 is easy to reach (top-right of function row)
- ✅ Never conflicts with other shortcuts
- ✅ Unique to your keyboard
- ✅ All your existing Niri binds continue working

---

## Option 3: Use Caps Lock as Mod (Advanced)

Make Caps Lock act as Super/Meta at the **OS level**:

```nix
# modules/nixos/system/keyboard-layout.nix
{ ... }: {
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = [
      "caps:super"  # Caps Lock becomes Super
    ];
  };
}
```

**BUT WAIT!** Your firmware already has `LT(1,KC_CAPS)` - Caps Hold is Layer 1!

**Conflict:** This creates a conflict between firmware and OS.

**Solution:** If you want Caps = Super:

1. **Remove Layer Tap from firmware:**
   - Change position 51: `LT(1,KC_CAPS)` → `KC_CAPS`
   
2. **Add OS-level remap:**
   ```nix
   services.xserver.xkb.options = [ "caps:super" ];
   ```

3. **Move Layer 1 access** to another key (e.g., Fn key if you have one)

**Benefits:**
- ✅ Caps Lock is easiest key to reach
- ✅ Very ergonomic
- ✅ Industry standard for winkeyless layouts

**Drawbacks:**
- ❌ Lose Caps Hold → Function Layer
- ❌ Lose quick access to Home/End/PgUp/PgDn

---

## My Recommendation

### If you can comfortably hit positions 86/90:
**→ Keep your current setup!** It already works perfectly.

### If positions 86/90 are awkward or missing:
**→ Use F13 as your Super key** with keyd remapping.

### If you want maximum ergonomics:
**→ Use Caps Lock as Super** (remove firmware layer tap).

---

## Quick Test: Which Keys Do You Have?

Run this to see what your keyboard sends:

```bash
# Install if needed
nix-shell -p wev

# Then run
wev

# Press each key and see what code it sends:
# - Position 86 (left of space): Should show "KEY_LEFTMETA"
# - Position 90 (right of space): Should show "KEY_RIGHTMETA"
# - F13: Should show "KEY_F13"
# - Caps Lock: Should show "KEY_CAPSLOCK"
```

---

## Configuration Examples

### Setup 1: F13 as Mod (via keyd)

```nix
# modules/nixos/system/keyboard-layout.nix
{ pkgs, ... }: {
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
          f13 = "leftmeta";
        };
      };
    };
  };
}
```

Then your existing Niri config works as-is! Just press **F13** instead of a Super key.

### Setup 2: Caps as Mod (firmware change + XKB)

**Step 1:** Change firmware
```json
// Position 51 in Layer 0
"KC_CAPS"  // Instead of "LT(1,KC_CAPS)"
```

**Step 2:** Add to modules
```nix
# modules/nixos/system/keyboard-layout.nix
{ ... }: {
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = [ "caps:super" ];
  };
}
```

**Step 3:** Move Layer 1 access to another key in firmware
```json
// Example: Make Right Shift tap = RShift, hold = Layer 1
// Position 79
"LT(1,KC_RSFT)"  // Instead of just "KC_RSFT"
```

### Setup 3: Dedicated F-key bindings (no Mod change)

Keep Mod as-is, but add F13-F16 shortcuts alongside:

```nix
# home/nixos/niri/keybinds.nix
{
  programs.niri.settings.binds = {
    # Your existing Mod bindings stay the same
    "Mod+T".action.spawn = terminal;
    "Mod+D".action.spawn = launcher;
    # etc...
    
    # Add F13-F16 as quick actions
    "F13".action.spawn = launcher;  # Same as Mod+D
    "F14".action.spawn = terminal;  # Same as Mod+T
    "F15".action.spawn = [screenLocker];
    "F16".action.toggle-window-floating = {};
    
    # Shift + F-keys for more actions
    "Shift+F13".action.spawn = ["hyprpicker"];
    "Shift+F14".action.screenshot;
    "Shift+F15".action.maximize-column = {};
    "Shift+F16".action.fullscreen-window = {};
  };
}
```

---

## Best Practices for Your Setup

### 1. Use Caps Hold for Navigation

Your firmware already has this! Practice:

```
Caps + Left  = Home (start of line)
Caps + Right = End (end of line)  
Caps + Up    = Page Up
Caps + Down  = Page Down
```

This works **everywhere** - terminal, browser, editor.

### 2. Use F13 for "Context Actions"

Since F13 doesn't conflict with anything:

```nix
# Single app launcher
"F13".action.spawn = launcher;

# Or make it contextual
"F13".action.spawn = [
  "sh" "-c"
  "if pgrep ghostty; then niri msg action focus-window ghostty; else ghostty; fi"
];
```

### 3. Layer Your Shortcuts

```
Base:       Mod + Key        = Primary action
Enhanced:   Mod + Shift + Key = Secondary action  
Advanced:   Mod + Alt + Key   = Tertiary action
Quick:      F13-F16          = Most-used actions
```

Example from your config:
```nix
"Mod+Q"         = Close window
"Mod+Shift+Q"   = Force close window
"Mod+Alt+Q"     = Close all windows in workspace
```

### 4. Optimize Your Top 5 Actions

Look at your most-used commands and map them to F13-F16:

```nix
# Based on your config, probably:
"F13".action.spawn = launcher;        # Was Mod+D
"F14".action.spawn = terminal;        # Was Mod+T
"F15".action.screenshot;              # Was Mod+Print
"F16".action.close-window = {};       # Was Mod+Q
```

Now your top actions are **one key press** instead of Mod+Key!

---

## Testing Your Layout

### Day 1: Verify Basics

```bash
# Open wev to test keys
wev

# Test:
# 1. Press F13 - should show KEY_F13
# 2. Hold Caps, press Left - should show KEY_HOME
# 3. Hold Caps, press F8 - should trigger play/pause
# 4. Check positions 86/90 - do they send KEY_LEFTMETA?
```

### Day 2-7: Build Muscle Memory

Focus on these three habits:
1. **Caps + Arrows** for navigation (instead of Home/End/PgUp/PgDn)
2. **F13** as your launcher (instead of Mod+D)
3. **Mod key** (position 86/90 or remapped F13) for window management

### Week 2: Optimize

Look at your most-used commands:
```bash
# If you have atuin or similar
atuin history | head -20

# Check Niri commands
journalctl --user -u niri.service | grep "spawn"
```

Map your top 5 to F13-F16 combinations.

---

## My Final Recommendation for YOU

Based on your current setup:

1. **Check if positions 86/90 are comfortable**
   - If yes: **Keep everything as-is**, just practice using them
   - If no: **Add keyd** to remap F13 → Super

2. **Add F13-F16 quick shortcuts** alongside your existing Mod bindings

3. **Practice Caps + Arrows** for navigation

4. **Keep Layer 1 (Caps Hold)** - it's perfect for your workflow

This gives you:
- ✅ All your existing keybinds work
- ✅ F13-F16 for one-key quick actions  
- ✅ Caps Hold for navigation/media
- ✅ No need to relearn everything

Want me to create a specific keyd configuration or update your Niri keybinds?
