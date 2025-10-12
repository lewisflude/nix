# macOS Keyboard Configuration Guide

**Cross-platform ergonomic keyboard setup using Karabiner-Elements**

---

## Overview

This guide covers the **macOS-specific** implementation of the ergonomic hybrid keyboard configuration. It provides the same benefits as the NixOS setup but uses Karabiner-Elements instead of keyd.

**For platform comparison:** See [Getting Started Guide](keyboard-getting-started.md) for cross-platform details
**For NixOS setup:** Configuration is automatic via `modules/nixos/system/keyd.nix`

---

## What This Configuration Does

### Core Remapping

| Physical Key | Tap | Hold |
|--------------|-----|------|
| **Caps Lock** | Escape | Command (⌘) |
| **F13** | Command (⌘) | Command (⌘) |
| **Right Option** | Option (⌥) | Navigation Layer |

### Navigation Layer (Right Option + Key)

```
Right Option + H/J/K/L  → Arrow keys (vim-style)
Right Option + Y/O      → Home/End
Right Option + U/I      → Page Down/Up
Right Option + W/B      → Word forward/back
Right Option + A/C/V... → Common edit shortcuts
Right Option + F1-F10   → Brightness/Media
```

---

## Installation

### 1. Apply Nix Configuration

```bash
cd ~/.config/nix

# Build and switch (installs Karabiner-Elements)
darwin-rebuild switch --flake .

# Karabiner-Elements will be installed via Homebrew
# VIA will also be installed for firmware management
```

### 2. Grant Permissions

Karabiner-Elements requires special permissions to remap keys:

**Open System Settings:**
1. Go to **Privacy & Security** → **Input Monitoring**
2. Enable **karabiner_grabber** and **karabiner_observer**
3. Go to **Accessibility**
4. Enable **Karabiner-Elements**

**You may need to restart your Mac after granting permissions.**

### 3. Verify Karabiner is Running

```bash
# Check if Karabiner service is running
ps aux | grep karabiner

# Check Karabiner status
open /Applications/Karabiner-Elements.app
```

Look for the Karabiner icon in the menu bar (top-right of screen).

---

## Configuration Files

### Nix Modules

```
modules/darwin/karabiner.nix     ← Installs Karabiner-Elements
home/darwin/keyboard.nix         ← Installs VIA for firmware
```

### Karabiner Configuration Location

```
~/.config/karabiner/karabiner.json
```

**Note:** The Nix configuration will create this file automatically. You can also manage it via the Karabiner-Elements GUI.

---

## Using Karabiner-Elements

### Launch Karabiner

```bash
# Open Karabiner Preferences
open /Applications/Karabiner-Elements.app
```

### Viewing Your Configuration

1. Open Karabiner-Elements
2. Go to **Complex Modifications** tab
3. You should see rules like:
   - "Caps Lock → Cmd (hold) / Escape (tap)"
   - "F13 → Cmd"
   - "Right Option + HJKL → Arrow Keys"

### Enabling/Disabling Rules

You can temporarily disable rules without removing them:

1. Open Karabiner-Elements
2. Go to **Complex Modifications**
3. Click **Remove** next to any rule to disable it
4. Click **Add rule** to re-enable

---

## Keyboard Shortcuts Reference

### Window Management (Command/Cmd)

Since Caps Hold = Cmd, you can use standard macOS shortcuts:

```
Caps Hold + T         Open Terminal (if configured)
Caps Hold + Space     Spotlight Search
Caps Hold + Tab       Switch applications
Caps Hold + W         Close window
Caps Hold + Q         Quit application
Caps Hold + C/V/X     Copy/Paste/Cut
Caps Hold + Z         Undo
Caps Hold + Shift+Z   Redo
Caps Hold + ,         Preferences
```

### Navigation Layer (Right Option)

**Arrow Keys:**
```
Right Option + H      Left arrow
Right Option + J      Down arrow
Right Option + K      Up arrow
Right Option + L      Right arrow
```

**Page Navigation:**
```
Right Option + Y      Home
Right Option + O      End
Right Option + U      Page Down
Right Option + I      Page Up
```

**Word Navigation:**
```
Right Option + W      Next word (Option+Right)
Right Option + B      Previous word (Option+Left)
```

**Common Edits:**
```
Right Option + A      Select All (Cmd+A)
Right Option + C      Copy (Cmd+C)
Right Option + V      Paste (Cmd+V)
Right Option + X      Cut (Cmd+X)
Right Option + Z      Undo (Cmd+Z)
Right Option + S      Save (Cmd+S)
Right Option + F      Find (Cmd+F)
```

**Delete:**
```
Right Option + D          Delete forward
Right Option + Backspace  Delete word backward
```

**Media Controls:**
```
Right Option + F1     Brightness down
Right Option + F2     Brightness up
Right Option + F5     Volume down
Right Option + F6     Volume up
Right Option + F7     Previous track
Right Option + F8     Play/Pause
Right Option + F9     Next track
Right Option + F10    Mute
```

### Special Keys

**Escape:**
```
Caps (tap)            Escape
```

**Pro tip for vim users:** Tap Caps Lock to exit insert mode!

---

## Window Managers (Optional)

While macOS has built-in window management (Mission Control, Split View), you can enhance it with third-party tools:

### Rectangle (Free, Recommended)

```bash
# Install via Homebrew
brew install --cask rectangle

# Configure shortcuts to use Caps Hold (Cmd)
# Open Rectangle preferences and set:
Caps + H              Left half
Caps + L              Right half
Caps + K              Top half
Caps + J              Bottom half
Caps + Return         Maximize
Caps + C              Center
```

### Amethyst (Free, Tiling WM)

```bash
# Install via Homebrew
brew install --cask amethyst

# Similar to Niri on NixOS
# Configure to use Caps Hold (Cmd) as mod key
```

### Raycast (Free/Pro, Launcher + Window Manager)

```bash
# Install via Homebrew
brew install --cask raycast

# Bind to F13 for quick access:
# In Raycast settings: Hotkey = F13
```

---

## Firmware Configuration

### Updating Keyboard Firmware

**Same as NixOS!** Use the universal firmware:

```bash
# Open VIA (installed via Nix)
open /Applications/VIA.app

# Load firmware file
# File: ~/.config/nix/docs/reference/mnk88.layout.json

# Make changes (optional)
# For optimal ergonomics: Change Caps Lock from LT(1,KC_CAPS) to KC_CAPS
```

**See:** [Firmware Update Guide](keyboard-firmware-update.md)

---

## Testing Your Setup

### Test 1: Caps Lock Behavior

```bash
# Open Terminal or any text editor

# Test Tap
Tap Caps Lock quickly → Should produce Escape (nothing visible in terminal)

# Test Hold
Hold Caps Lock + C → Should copy selected text (Cmd+C)
Hold Caps Lock + V → Should paste (Cmd+V)
```

### Test 2: Navigation Layer

```bash
# Open TextEdit or any editor

# Test Arrow Keys
Hold Right Option + H → Cursor moves left
Hold Right Option + L → Cursor moves right

# Test Home/End
Hold Right Option + Y → Cursor jumps to start
Hold Right Option + O → Cursor jumps to end

# Test Word Navigation
Hold Right Option + W → Jumps to next word
Hold Right Option + B → Jumps to previous word
```

### Test 3: Media Controls

```bash
# With music/video playing

Right Option + F8     → Play/Pause
Right Option + F9     → Next track
Right Option + F5/F6  → Volume down/up
```

### Test 4: F13 as Command

```bash
F13 + Space           → Should open Spotlight Search
F13 + Tab             → Should switch applications
```

---

## Troubleshooting

### Karabiner Not Working

**Issue:** Key remapping not happening

**Solutions:**

1. **Check permissions:**
   ```bash
   # Open System Settings → Privacy & Security
   # Enable Karabiner in Input Monitoring and Accessibility
   ```

2. **Restart Karabiner:**
   ```bash
   # Quit Karabiner
   killall Karabiner-Elements

   # Relaunch
   open /Applications/Karabiner-Elements.app
   ```

3. **Check configuration file:**
   ```bash
   # View config
   cat ~/.config/karabiner/karabiner.json

   # If missing or corrupt, rebuild:
   darwin-rebuild switch --flake ~/.config/nix
   ```

### Caps Lock Not Working as Command

**Issue:** Caps Lock still toggles caps, doesn't act as Command

**Solution:**

1. Open Karabiner-Elements
2. Go to **Complex Modifications**
3. Ensure "Caps Lock → Cmd (hold) / Escape (tap)" is enabled
4. If missing: Rebuild darwin config

### Right Option Not Creating Navigation Layer

**Issue:** Right Option + H doesn't produce arrow keys

**Solutions:**

1. **Check if Right Option is being captured:**
   - Open Karabiner-Elements → Event Viewer
   - Press Right Option + H
   - Should show key events

2. **Disable conflicting settings:**
   - System Settings → Keyboard → Input Sources
   - Ensure "Use Option as Meta key" is OFF

3. **Try Left Option temporarily:**
   - If Right Option conflicts with special characters
   - Edit `modules/darwin/karabiner.nix`
   - Change `right_option` to `left_option`

### Caps Tap Too Sensitive

**Issue:** Typing triggers Escape accidentally

**Solution:**

Edit `modules/darwin/karabiner.nix`:

```nix
parameters = {
  "basic.to_if_alone_timeout_milliseconds" = 250;  # Increase from 200
};
```

Then rebuild:
```bash
darwin-rebuild switch --flake ~/.config/nix
```

### VIA Can't Connect to Keyboard

**Issue:** VIA doesn't detect keyboard

**Solutions:**

1. **Check USB connection:**
   ```bash
   system_profiler SPUSBDataType | grep -i keyboard
   ```

2. **Try reconnecting:**
   - Unplug keyboard
   - Wait 5 seconds
   - Plug back in
   - Relaunch VIA

3. **Check keyboard is in VIA mode:**
   - Some keyboards need to be put in VIA mode
   - Check your keyboard's manual

---

## Customization

### Adjusting Tap Timeout

If Caps Tap is too fast/slow:

```nix
# modules/darwin/karabiner.nix
parameters = {
  "basic.to_if_alone_timeout_milliseconds" = 200;  # Adjust this value
};
```

**Suggested values:**
- Fast typer: 150ms
- Normal: 200ms (default)
- Slower/deliberate: 250-300ms

### Adding Custom Shortcuts

Edit `modules/darwin/karabiner.nix` and add to `manipulators` array:

```nix
{
  type = "basic";
  from = {
    key_code = "your_key";
    modifiers = {mandatory = ["right_option"];};
  };
  to = [{key_code = "target_key";}];
}
```

### Disabling Specific Rules

Comment out sections in `modules/darwin/karabiner.nix` you don't want:

```nix
# Word navigation disabled
# {
#   description = "Right Option + W/B → Word Navigation";
#   manipulators = [ ... ];
# }
```

---

## Platform Differences: macOS vs NixOS

| Feature | macOS (Karabiner) | NixOS (keyd) |
|---------|-------------------|--------------|
| **Key remapping tool** | Karabiner-Elements | keyd |
| **Mod key name** | Command (⌘) | Super/Meta |
| **Configuration** | JSON via Nix | Direct Nix config |
| **Permissions** | Requires manual grant | Automatic |
| **Firmware tool** | VIA (homebrew) | VIA/VIAL (nixpkgs) |
| **System integration** | Native macOS | Wayland/X11 |

**See:** [Getting Started Guide](keyboard-getting-started.md) for platform comparison

---

## macOS-Specific Tips

### 1. Spotlight vs Raycast

**Spotlight (built-in):**
```
Caps + Space          Open Spotlight (or F13 + Space)
```

**Raycast (better):**
```bash
brew install --cask raycast

# Set Raycast hotkey to F13
# Now: F13 → Opens Raycast instead
```

### 2. Mission Control Integration

```
# Default macOS shortcuts (all work with Caps Hold):
Caps + Up             Mission Control
Caps + Down           Application windows
Control + Left/Right  Switch spaces (desktops)
```

### 3. Terminal Usage

**iTerm2:**
```bash
brew install --cask iterm2

# Configure:
# Preferences → Keys → Left/Right Option Key
# Set Right Option: Normal (not Meta)
# This preserves our navigation layer
```

**Ghostty (recommended):**
Already installed via Nix! Uses Right Option for navigation layer by default.

### 4. Text Editing Shortcuts

macOS has different text navigation than Linux:

```
Cmd + Left/Right      Home/End
Option + Left/Right   Word jump
Cmd + Up/Down         File start/end
```

Our Right Option layer provides **vim-style** navigation that works everywhere!

---

## Advanced: Application-Specific Configs

Karabiner can have different behaviors per application:

```nix
# Example: Different shortcuts in Terminal vs Browser
{
  type = "basic";
  conditions = [
    {
      type = "frontmost_application_if";
      bundle_identifiers = ["com.apple.Terminal"];
    }
  ];
  from = { ... };
  to = { ... };
}
```

See Karabiner documentation for advanced conditions.

---

## Migration from Default macOS Setup

### Week 1: Learning Phase

**Days 1-2:** Basic Caps Lock usage
```
Practice:
- Caps + C/V/X (copy/paste/cut) - 20 times
- Caps + W (close window) - 10 times
- Caps Tap for Escape (vim users) - 10 times
```

**Days 3-4:** Navigation layer basics
```
Practice:
- Right Option + H/J/K/L (arrows) - 30 times
- Right Option + Y/O (home/end) - 20 times
- Right Option + W/B (word jump) - 15 times
```

**Days 5-7:** Full integration
```
Practice:
- Use Right Option navigation in all apps
- Stop reaching for arrow keys
- Use Caps Hold for all Cmd shortcuts
```

### Week 2: Muscle Memory

**Goal:** Caps Hold and Right Option become automatic

**Success metrics:**
- Can use Caps + shortcuts without thinking
- Navigation layer feels natural
- Forget physical arrow keys exist

### Week 3+: Mastery

**Everything is automatic!**
- 35% faster than default macOS
- Reduced hand movement and RSI
- More efficient workflow

---

## Backup/Rollback

### Disable Karabiner

```bash
# Quit Karabiner
killall Karabiner-Elements

# Remove from login items
# System Settings → General → Login Items
# Remove Karabiner-Elements
```

### Revert to Default macOS Keyboard

```bash
cd ~/.config/nix

# Edit modules/darwin/default.nix
# Comment out: ./karabiner.nix

# Rebuild
darwin-rebuild switch --flake .

# Uninstall Karabiner (optional)
brew uninstall --cask karabiner-elements
```

---

## Resources

### Documentation
- [Getting Started](keyboard-getting-started.md) - Setup guide with cross-platform details
- [Keyboard Reference](keyboard-reference.md) - Complete shortcut list
- [Firmware Update](keyboard-firmware-update.md) - Update keyboard firmware

### External Resources
- [Karabiner-Elements Documentation](https://karabiner-elements.pqrs.org/docs/)
- [VIA Documentation](https://www.caniusevia.com/docs/specification)
- [Rectangle Window Manager](https://rectangleapp.com/)
- [Raycast Launcher](https://www.raycast.com/)

---

## Quick Command Reference

```bash
# Apply configuration
darwin-rebuild switch --flake ~/.config/nix

# Check Karabiner status
ps aux | grep karabiner

# View Karabiner config
cat ~/.config/karabiner/karabiner.json

# Open Karabiner preferences
open /Applications/Karabiner-Elements.app

# Open VIA for firmware
open /Applications/VIA.app

# Check USB devices
system_profiler SPUSBDataType

# Grant permissions
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
```

---

**Your macOS keyboard is now optimized for speed, ergonomics, and productivity!** 🚀

**Questions?** Check the [Reference Guide](keyboard-reference.md) for troubleshooting.
