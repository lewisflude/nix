# MNK88 Universal Keyboard Setup

> **⚠️ NEW ERGONOMIC CONFIGURATION AVAILABLE**  
> This guide describes the original F13-based setup. For the optimal ergonomic configuration with Caps Lock as Super, see:
> - [Keyboard Reference](keyboard-reference.md) - Complete new layout
> - [Migration Guide](keyboard-migration.md) - How to transition
> - [Firmware Update](keyboard-firmware-update.md) - Update your firmware

---

## YOU ONLY NEED ONE FIRMWARE!

Use the file: **`/tmp/mnk88-universal.json`** (original setup)

This single layout works on **both macOS and Linux**.

---

## What This Layout Does

### Layer 0 (Base)
- **Standard ANSI layout** with all keys where they should be
- **F13-F16** in navigation cluster (works on both OS)
- **Ctrl, Alt, GUI/Cmd** keys present (positions 84-86, 90-92)
- **Caps Lock**: Tap = Caps, Hold = Layer 1

### Layer 1 (Caps Hold)
- **F1-F12**: 
  - macOS: Brightness, Mission Control, Media (native functions)
  - Linux: RGB controls (F11-F12), macOS functions don't hurt Linux
- **Arrow Keys → Home/End/PgUp/PgDn** (works on both)
- **Reset**: Caps + R (to flash firmware)

### Layer 2 (Right Shift Hold)
- **F14-F16 → PrtSc/ScrLk/Pause** (for Linux screenshot tools)
- Otherwise transparent

---

## How to Flash

1. **Open VIA or VIAL**
2. **Load**: `/tmp/mnk88-universal.json`
3. **Done!** Works on both systems

---

## Key Differences Per OS

### What Works Differently (Automatically):

| Key | macOS | Linux |
|-----|-------|-------|
| F1-F2 | Brightness | F1-F2 (apps can bind) |
| F3-F4 | Mission Control/Launchpad | F3-F4 (apps can bind) |
| F5-F10 | Volume/Media | F5-F10 (apps can bind) |
| F13-F16 | Extra bindable keys | Extra bindable keys |
| Cmd/GUI | Works natively | Acts as Super/Meta |
| Layer 2 + F14-F16 | Transparent | PrtSc/ScrLk/Pause |

### What's The Same:

✅ **Caps Hold** → Function layer  
✅ **F13** → Available for custom shortcuts  
✅ **All modifiers** work (Ctrl, Alt, Cmd/Super)  
✅ **Navigation keys** (arrows, Ins/Del/Home/End/PgUp/PgDn)  
✅ **Muscle memory** is identical  

---

## NixOS Configuration

**Already set up!** Just rebuild:

```bash
# The keyboard module is already created and imported
sudo nixos-rebuild switch --flake .#jupiter
```

What it does:
- Sets US layout
- Fast key repeat
- Caps Lock handled in firmware (not OS)

---

## macOS Configuration

**Already set up!** Just rebuild:

```bash
darwin-rebuild switch --flake .#Lewiss-MacBook-Pro
```

What it does:
- Fast key repeat (2ms)
- Disables press-and-hold
- F-keys default to functions (not media)
- Disables text substitutions

---

## Why This Works

**Firmware handles:**
- Core layout (keys, layers, Caps hold)
- Works identically on both OS

**OS handles:**
- How F1-F12 are interpreted (macOS has special meanings, Linux doesn't)
- Modifier key semantics (Cmd vs Super)
- Key repeat speed

**You handle:**
- Custom F13-F16 bindings per application
- Workspace shortcuts in Niri (Linux)
- App shortcuts in Raycast/Rectangle (macOS)

---

## Troubleshooting

### "My F-keys do media stuff on macOS"

That's **correct**! Hold Fn on your keyboard to access F1-F12 as pure function keys, or:

```bash
# Make F-keys default to function mode (already in config)
defaults write NSGlobalDomain "com.apple.keyboard.fnState" -bool true
```

### "I want PrtSc key on Linux"

Hold **Right Shift + F14** → Acts as Print Screen  
(Layer 2 remaps F14 to PrtSc for Linux)

### "Caps Hold isn't working"

Check in VIA that position 51 shows: `LT(1,KC_CAPS)`

---

## Summary

✅ **One firmware** (`mnk88-universal.json`)  
✅ **Flash once**, works everywhere  
✅ **OS configs** already done in your nix files  
✅ **No switching** needed when changing systems  

**Just flash and rebuild your nix configs!**
