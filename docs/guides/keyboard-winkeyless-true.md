# True Winkeyless Keyboard Setup

> **✅ OPTIMAL SOLUTION IMPLEMENTED**  
> This guide is now superseded by the ergonomic hybrid configuration. See:
> - [Keyboard Reference](keyboard-reference.md) - Complete new layout  
> - [Migration Guide](keyboard-migration.md) - Transition guide
> - [Firmware Update](keyboard-firmware-update.md) - Update firmware

---

## Your Hardware Setup

**PCB:** Supports Super/GUI keys at positions 86 & 90  
**Physical Layout:** Metal blockers prevent installing keycaps at those positions  
**Result:** We've implemented an optimal ergonomic solution (Caps Lock as Super + hybrid approach)

---

## The Solution: F13 as Super

Since you have **F13** available and no physical Super keys, we'll make F13 act as Super/Meta at the system level using `keyd`.

### Why This Works

1. ✅ **F13 is accessible** - Top right of your function row
2. ✅ **Never conflicts** - No application uses F13 by default
3. ✅ **System-wide** - Works in all applications, including Niri
4. ✅ **Transparent** - Applications think you're pressing Super
5. ✅ **Easy to reach** - Better than far corner keys

---

## NixOS Configuration (Already Set Up!)

The configuration has been added to your system:

```nix
# modules/nixos/system/keyd.nix
services.keyd = {
  enable = true;
  keyboards.default = {
    ids = [ "*" ];
    settings.main = {
      f13 = "leftmeta";  # F13 → Super/Meta
    };
  };
};
```

### Apply the Configuration

```bash
# Rebuild your system to enable keyd
sudo nixos-rebuild switch --flake .#jupiter

# Verify keyd is running
systemctl status keyd

# Test it - run this and press F13
wev
# Should show: KEY_LEFTMETA instead of KEY_F13
```

---

## How to Use Your Keyboard Now

### Primary Workflow

**F13 = Your Super/Mod Key**

All your existing Niri bindings work, just press **F13** instead of a Super key:

```
F13 + T     → Terminal (Mod+T)
F13 + D     → Launcher (Mod+D)
F13 + Q     → Close window (Mod+Q)
F13 + 1-9   → Switch workspaces
F13 + H/J/K/L → Window navigation (if configured)
```

### Secondary Functions

**Caps Lock Hold = Function Layer** (firmware-based)

```
Caps + Left Arrow  → Home
Caps + Right Arrow → End
Caps + Up Arrow    → Page Up
Caps + Down Arrow  → Page Down

Caps + F5/F6  → Volume Down/Up
Caps + F7     → Previous Track
Caps + F8     → Play/Pause
Caps + F9     → Next Track
Caps + F10    → Mute
```

### Layer 2 (Right Shift Hold)

Available for custom shortcuts if needed:

```
RShift + F14 → Print Screen (for Linux screenshots)
RShift + F15 → Scroll Lock
RShift + F16 → Pause
```

---

## Practical Daily Usage

### Morning Routine

```bash
# 1. Boot into NixOS
# 2. Press F13 + D → Launcher opens
# 3. Type "ghostty" → Terminal opens
# 4. Press F13 + 1/2/3 → Switch between workspaces
```

### Text Editing

```
# Navigation without dedicated keys
Caps + Arrows → Home/End/PgUp/PgDn

# Standard shortcuts work with F13
F13 + C      → Copy (in many apps that use Super+C)
F13 + V      → Paste
F13 + T      → New tab/terminal
```

### Window Management in Niri

Your existing keybinds from `home/nixos/niri/keybinds.nix` all work:

```
F13 + T           → New terminal
F13 + D           → Fuzzel launcher
F13 + Q           → Close window
F13 + Shift + Q   → Force close window
F13 + F           → Maximize column
F13 + Shift + F   → Fullscreen
F13 + V           → Clipboard manager
F13 + Print       → Screenshot
```

---

## Muscle Memory Tips

### Week 1: Get Comfortable with F13

**Practice these 5 shortcuts:**
1. `F13 + T` (terminal)
2. `F13 + D` (launcher)
3. `F13 + Q` (close window)
4. `F13 + 1/2/3` (workspaces)
5. `Caps + Arrows` (navigation)

### Week 2: Build Speed

- Use F13 without looking
- Practice Caps + Arrows for text navigation
- Add more F13 combinations

### Week 3: Advanced Usage

- Customize Layer 2 (Right Shift hold)
- Add application-specific F13 shortcuts
- Optimize your most-used commands

---

## Advantages of F13 as Super

### Better Than Corner Super Keys

1. **More reachable** - Function row vs far corner
2. **Both hands** - Can use either hand for F13
3. **Fewer accidental presses** - F13 is deliberate
4. **Unique** - No other application conflicts

### Better Than Caps as Super

1. **Keep Caps Hold layer** - Still have Home/End/PgUp/PgDn access
2. **Less confusion** - Caps still acts as Caps when tapped
3. **Dedicated** - F13 is only for Super, no dual purpose

---

## macOS Configuration

Since macOS actually **requires** Cmd keys for most shortcuts, you have two options:

### Option 1: Different Keyboard for macOS

If you primarily use NixOS and occasionally use macOS, consider:
- Using the built-in MacBook keyboard when on macOS
- Or a different external keyboard with Cmd keys for macOS

### Option 2: Remap for macOS (Advanced)

Use **Karabiner-Elements** on macOS to map F13 to Cmd:

```json
// ~/.config/karabiner/karabiner.json
{
  "profiles": [{
    "complex_modifications": {
      "rules": [{
        "description": "F13 to Command",
        "manipulators": [{
          "from": {"key_code": "f13"},
          "to": [{"key_code": "left_command"}],
          "type": "basic"
        }]
      }]
    }
  }]
}
```

But honestly, **macOS is difficult without physical Cmd keys**. The OS is designed around them.

---

## Testing Your Setup

### Verify F13 → Super Mapping

```bash
# 1. Check keyd is running
systemctl status keyd
# Should show: active (running)

# 2. Test key output
wev
# Press F13 - should show: KEY_LEFTMETA (not KEY_F13)

# 3. Test in Niri
# Press F13 + D - launcher should open
# Press F13 + T - terminal should open
```

### Troubleshooting

**F13 still acts as F13, not Super:**

```bash
# Check keyd config
cat /etc/keyd/default.conf

# Should contain:
# [main]
# f13 = leftmeta

# Restart keyd
sudo systemctl restart keyd
```

**keyd not starting:**

```bash
# Check logs
journalctl -u keyd -n 50

# Rebuild system
sudo nixos-rebuild switch --flake .#jupiter
```

**F13 works but Niri bindings don't:**

Check your Niri config uses `Mod` (not hardcoded `Super`):

```nix
# ✅ Good
"Mod+T".action.spawn = terminal;

# ❌ Bad
"Super+T".action.spawn = terminal;
```

---

## Advanced: Layer 2 Customization

Since you don't have Super keys, you can repurpose Layer 2 for other functions:

### Option 1: App Launcher Layer

```json
// In VIA/VIAL, set Layer 2 (RShift hold):
Position 18-26 (number row) → Launch specific apps via F13-F22
Position 35-45 (QWERTY row) → Quick actions
```

Then in Niri:

```nix
# Map F17-F22 to apps
"F17".action.spawn = ["firefox"];
"F18".action.spawn = ["code"];
"F19".action.spawn = ["slack"];
# etc.
```

### Option 2: Navigation Layer

Make Right Shift hold give you arrow keys on HJKL:

```json
// Layer 2:
Position 57 (H) → Left Arrow
Position 58 (J) → Down Arrow  
Position 59 (K) → Up Arrow
Position 60 (L) → Right Arrow
```

---

## Comparison: Your Options

| Method | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **F13 as Super (keyd)** | ✅ Easy to reach<br>✅ No conflicts<br>✅ All bindings work | ❌ Slightly unusual | **BEST for NixOS** |
| **Caps as Super (XKB)** | ✅ Most ergonomic<br>✅ Industry standard | ❌ Lose Caps Hold layer<br>❌ Lose nav shortcuts | Good alternative |
| **Physical Key Mod** | ✅ Traditional | ❌ Impossible (blockers) | Not available |
| **Layer 2 holds** | ✅ No OS config needed | ❌ Awkward to hold<br>❌ Slow | Not recommended |

---

## Bottom Line

**Your optimal setup:**

1. ✅ **F13 = Super** (via keyd) - Primary modifier for Niri
2. ✅ **Caps Hold = Function Layer** - Navigation & media controls  
3. ✅ **Right Shift Hold = Layer 2** - Extra shortcuts if needed
4. ✅ **F14-F16** - Quick one-key actions

**Rebuild your system to enable keyd:**

```bash
cd ~/.config/nix
sudo nixos-rebuild switch --flake .#jupiter
```

**Test F13:**

```bash
wev  # Press F13, should show KEY_LEFTMETA
```

**Use your keyboard:**

Press **F13 + D** to open your launcher!

Your winkeyless keyboard is now fully functional with Niri! 🎉
