# Shift+Enter Not Working - Troubleshooting Guide

## The Problem

`Shift+Enter` doesn't insert a newline in **any** application (Claude, Cursor, terminal, web browsers). This indicates a **system-level issue** rather than app-specific configuration problems.

## Quick Diagnosis

### Test 1: Check if it's truly system-wide

**Open TextEdit** (native macOS app):
1. Press `Cmd+Space` to open Spotlight
2. Type "TextEdit" and press Enter
3. Press `Cmd+N` to create a new document
4. Type: "Line 1"
5. Press `Shift+Enter`
6. Type: "Line 2"

**Expected:** Two lines appear
**If this DOESN'T work:** → System-level keyboard issue (continue below)
**If this DOES work:** → App-specific config issue (see docs/NEWLINE_KEYBINDINGS.md)

## Root Causes (In Order of Likelihood)

### 1. Karabiner Elements Interference (MOST LIKELY)

**Problem:** Karabiner might be intercepting `Shift+Enter` even when not actively running, or has left system-level hooks.

**Quick Test:**
```bash
# 1. Completely quit Karabiner
osascript -e 'quit app "Karabiner-Elements"'
osascript -e 'quit app "Karabiner-EventViewer"'

# 2. Kill any remaining processes
pkill -9 karabiner || true

# 3. Test Shift+Enter in TextEdit again
# If it works now → Karabiner is the culprit
```

**Permanent Fix:**

If Karabiner was the issue, you need to ensure your rules don't interfere with `Shift+Enter`.

Check your configuration at `~/.config/karabiner/karabiner.json`:
- Look for any rules involving `"return_or_enter"`
- Make sure they're device-specific (MNK88 only)
- Ensure no global rules capture Shift+Enter

**Your current Karabiner config** (`home/darwin/karabiner.nix`) uses `return_or_enter` but only for F16 key mapping, which should be fine.

### 2. MNK88 Keyboard Firmware (SECOND MOST LIKELY)

**Problem:** Your custom keyboard (MNK88) might have firmware-level key remapping that's intercepting `Shift+Enter`.

**How to Check:**

1. **Test with a different keyboard:**
   ```bash
   # Connect a different keyboard (or use MacBook built-in)
   # Test Shift+Enter in TextEdit
   # If it works → MNK88 firmware is remapping the key
   ```

2. **Check keyboard firmware with VIA/VIAL:**
   - Your config mentions VIA support (`home/darwin/keyboard.nix`)
   - Open VIA or VIAL software
   - Check the keymap for your Enter key
   - Look for any layers that might remap `Shift+Enter`

3. **Check QMK firmware (if applicable):**
   - If MNK88 uses QMK firmware
   - Check for any `LT()`, `MT()`, or custom key codes on Enter
   - Look for Shift + Enter combinations in your keymap.c

**Fix:**
- Reset keyboard firmware to default
- Or remove any Shift+Enter specific mappings
- Flash updated firmware

### 3. macOS Input Method Conflict

**Problem:** British keyboard layout or input method intercepting keystroke.

**How to Check:**
```bash
# Check current input source
defaults read com.apple.HIToolbox AppleCurrentKeyboardLayoutInputSourceID

# Check all enabled input sources
defaults read com.apple.HIToolbox AppleEnabledInputSources
```

**Fix:**
```bash
# System Settings → Keyboard → Input Sources
# 1. Remove any input methods you don't use
# 2. Try switching to US keyboard layout temporarily
# 3. Test Shift+Enter again
```

### 4. Accessibility Permissions

**Problem:** Some app or service doesn't have proper accessibility permissions.

**How to Fix:**
1. System Settings → Privacy & Security → Accessibility
2. Check if these apps have access:
   - Karabiner Elements (if using)
   - Terminal
   - Ghostty
   - Cursor
3. Remove and re-add them if needed
4. Restart Mac

### 5. Shift Key Physically Stuck or "Virtually Stuck"

**Problem:** Shift modifier state is confused.

**How to Fix:**
```bash
# Press each modifier key 5 times:
# - Left Shift (5x)
# - Right Shift (5x)
# - Caps Lock on, then off
# - Log out and log back in
```

### 6. System Keyboard Shortcuts Conflict

**Problem:** A system-wide shortcut is using Shift+Enter.

**How to Check:**
```bash
# Check for symbolic hotkeys
defaults read com.apple.symbolichotkeys AppleSymbolicHotKeys | grep -i "return"

# Check custom app shortcuts
defaults read -g NSUserKeyEquivalents
```

**How to Fix:**
1. System Settings → Keyboard → Keyboard Shortcuts
2. Go through each section (Mission Control, Keyboard, etc.)
3. Look for anything using Shift+Enter
4. Click "Restore Defaults" at bottom if needed

## Step-by-Step Diagnostic Process

### Phase 1: Identify the Layer

```bash
# Test 1: Native macOS app (TextEdit)
# Result: _______________

# Test 2: Terminal (Ghostty or Terminal.app)
# Result: _______________

# Test 3: Web browser (claude.ai)
# Result: _______________

# Test 4: Electron app (Cursor)
# Result: _______________
```

**If NONE work:** System-level issue → Continue to Phase 2
**If SOME work:** App-specific → See docs/NEWLINE_KEYBINDINGS.md

### Phase 2: Eliminate Suspects

```bash
# Step 1: Test with different keyboard
# (Use built-in MacBook keyboard or plug in USB keyboard)
# Result: _______________
# If it works → MNK88 firmware issue

# Step 2: Disable Karabiner completely
osascript -e 'quit app "Karabiner-Elements"'
sudo launchctl unload /Library/LaunchDaemons/org.pqrs.karabiner.karabiner_*
# Test Shift+Enter
# Result: _______________
# If it works → Karabiner configuration issue

# Step 3: Create new user account (test)
# System Settings → Users & Groups → Add Account
# Log into new account
# Test Shift+Enter
# Result: _______________
# If it works → Your user account has corrupted settings

# Step 4: Safe Mode boot
# Restart Mac, hold Shift during boot
# Test Shift+Enter
# Result: _______________
# If it works → A LaunchDaemon/LaunchAgent is interfering
```

### Phase 3: Identify Exact Cause

Based on Phase 2 results:

**If different keyboard works:**
→ MNK88 keyboard firmware issue
→ Solution: Check VIA/VIAL keymap, reset firmware

**If Karabiner disabled works:**
→ Karabiner rule interference
→ Solution: Review karabiner.json, remove conflicting rules

**If new user account works:**
→ User-specific macOS settings corrupted
→ Solution: Delete preference files (see below)

**If Safe Mode works:**
→ Third-party service interfering
→ Solution: Identify and disable the service

## Solutions

### Solution A: Fix Karabiner Configuration

```bash
# 1. Backup current config
cp ~/.config/karabiner/karabiner.json ~/.config/karabiner/karabiner.json.backup

# 2. Test with minimal config (no complex modifications)
cat > ~/.config/karabiner/karabiner.json << 'EOF'
{
  "global": {
    "check_for_updates_on_startup": true,
    "show_in_menu_bar": true
  },
  "profiles": [
    {
      "name": "Test Profile",
      "complex_modifications": {
        "rules": []
      },
      "simple_modifications": []
    }
  ]
}
EOF

# 3. Restart Karabiner
osascript -e 'quit app "Karabiner-Elements"'
open -a "Karabiner-Elements"

# 4. Test Shift+Enter
# If it works, gradually add rules back to find the culprit
```

### Solution B: Fix MNK88 Firmware

**If you have QMK/VIA firmware:**

1. Open VIA (https://usevia.app)
2. Connect MNK88
3. Check the keymap for your Enter key
4. Look for any layers or macros on Enter
5. Reset to default keymap
6. Save to keyboard

**If you need to reflash:**

```bash
# Find your QMK firmware directory
cd ~/qmk_firmware/keyboards/mnk88

# Reset to default keymap
qmk compile -kb mnk88 -km default

# Flash (put keyboard in bootloader mode first)
qmk flash -kb mnk88 -km default
```

### Solution C: Reset macOS Keyboard Settings

```bash
# Delete keyboard preference files
rm ~/Library/Preferences/com.apple.HIToolbox.plist
rm ~/Library/Preferences/com.apple.symbolichotkeys.plist

# Restart Mac
sudo shutdown -r now
```

### Solution D: Rebuild Home Manager (Ensure Config is Applied)

```bash
# Make sure the Nix config changes are actually deployed
cd ~/.config/nix

# Rebuild darwin configuration
darwin-rebuild switch --flake .

# Restart affected apps
killall Ghostty
killall Cursor
```

## Workarounds (While Diagnosing)

Use alternative keybindings that are less likely to be remapped:

### Option 1: `Option+Enter` (⌥+↩)
Most reliable alternative on macOS.

### Option 2: `Ctrl+J`
Unix newline character - works in many terminal apps.

### Option 3: `Cmd+Return` (⌘+↩)
Common in messaging apps.

### Option 4: Compose Multi-line First
Write multi-line text in TextEdit, then copy-paste into the target app.

## App-Specific Fixes (After System is Fixed)

Once `Shift+Enter` works in TextEdit, configure individual apps:

### Ghostty
Already configured in `home/common/features/core/terminal.nix`:
```nix
keybind = [ ''shift+enter=text:\n'' ];
```

### Cursor
Already configured in `home/common/apps/cursor/keybindings.nix`:
```nix
keybindings = [
  {
    key = "shift+enter";
    command = "editor.action.insertLineAfter";
    when = "editorTextFocus && !editorReadonly && !suggestWidgetVisible";
  }
];
```

### Claude Desktop
Built-in support - should work once system issue is resolved.

### Web Browsers
Built-in support - should work once system issue is resolved.

## Testing Checklist

```
[ ] Tested Shift+Enter in TextEdit
    Result: _____________

[ ] Tested with different keyboard
    Result: _____________

[ ] Disabled Karabiner and tested
    Result: _____________

[ ] Checked MNK88 firmware in VIA
    Result: _____________

[ ] Verified no system keyboard shortcuts conflict
    Result: _____________

[ ] Tested in new user account
    Result: _____________

[ ] Tested in Safe Mode
    Result: _____________
```

## Next Steps

1. **Start with the Quick Diagnosis** (Test in TextEdit)
2. **Run Phase 2 diagnostics** to isolate the cause
3. **Apply the appropriate solution** based on findings
4. **Test in all apps** to confirm fix
5. **Report back** with results so we can update this guide

## Additional Resources

- **Full keybinding guide:** `docs/NEWLINE_KEYBINDINGS.md`
- **Karabiner docs:** https://karabiner-elements.pqrs.org/docs/
- **VIA keyboard configurator:** https://usevia.app
- **QMK firmware:** https://docs.qmk.fm/

## Common Questions

**Q: Why does Shift+Enter not work anywhere?**
A: This is almost always either Karabiner intercept or keyboard firmware remapping at hardware level.

**Q: Should I use Shift+Enter or Option+Enter?**
A: `Shift+Enter` is the standard, but `Option+Enter` is more reliable on macOS with complex keyboard setups.

**Q: Will rebuilding my Nix config fix this?**
A: Only if the issue is in app configuration. If it's system/hardware level, Nix won't help.

**Q: My MNK88 has custom firmware - could that be it?**
A: Yes, very likely. Check your keymap in VIA or QMK source code.

## Report Template

When reporting this issue, include:

```
System: macOS [version]
Keyboard: MNK88 (Vendor: 19280, Product: 34816)
Karabiner: [version] - [running/not running]

Test Results:
- TextEdit: [works/doesn't work]
- Terminal: [works/doesn't work]
- Web browser: [works/doesn't work]
- Different keyboard: [works/doesn't work]
- Karabiner disabled: [works/doesn't work]

Configuration:
- Ghostty keybind: [show line from config]
- Karabiner rules: [number of rules]
- Input method: [name]
```
