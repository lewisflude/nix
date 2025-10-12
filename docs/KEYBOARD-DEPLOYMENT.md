# Keyboard Configuration - Deployment Guide

**Version:** 2.0 - Cross-Platform Ergonomic Hybrid  
**Date:** 2025-10-12  
**Platforms:** 🐧 NixOS + 🍎 macOS  
**Status:** ✅ Ready for Production

---

## 🚀 Quick Deployment

### Choose Your Platform

<details>
<summary><strong>🐧 NixOS Deployment</strong></summary>

```bash
cd ~/.config/nix

# 1. Apply configuration
sudo nixos-rebuild switch --flake .

# 2. Verify keyd is running
systemctl status keyd
# Should show: active (running)

# 3. Test with wev
wev
# Hold Caps → Shows KEY_LEFTMETA ✓
# Tap Caps → Shows KEY_ESC ✓
# RAlt + H → Shows KEY_LEFT ✓

# 4. Test in terminal
# Hold Caps + T → Terminal should open
# Hold RAlt + HJKL → Cursor moves like arrows

# ✅ Done! Your keyboard is configured.
```

**See:** [NixOS Quick Start](guides/keyboard-quickstart.md)

</details>

<details>
<summary><strong>🍎 macOS Deployment</strong></summary>

```bash
cd ~/.config/nix

# 1. Apply configuration
darwin-rebuild switch --flake .
# This installs Karabiner-Elements and VIA

# 2. Grant permissions (REQUIRED)
# Open: System Settings → Privacy & Security

# Enable in "Input Monitoring":
# - karabiner_grabber
# - karabiner_observer

# Enable in "Accessibility":
# - Karabiner-Elements

# 3. Verify Karabiner is running
ps aux | grep karabiner
# Should see karabiner_grabber and karabiner_observer

# 4. Test shortcuts
# In any text editor:
# Hold Caps + C → Should copy text ✓
# Tap Caps → Should produce Escape ✓
# Hold RAlt + H → Cursor moves left ✓

# ✅ Done! Your keyboard is configured.
```

**See:** [macOS Quick Start](guides/keyboard-macos.md)

</details>

---

## 📋 Pre-Deployment Checklist

### Both Platforms

- [ ] Git repository is up to date: `git pull origin main`
- [ ] Firmware file exists: `docs/reference/mnk88-universal.json`
- [ ] Read quick start guide: `docs/guides/keyboard-quickstart.md`
- [ ] Printed cheat sheet: `docs/guides/keyboard-cheatsheet.md` (optional)

### NixOS Only

- [ ] Running NixOS with flake support
- [ ] User has sudo access
- [ ] `modules/nixos/system/keyd.nix` exists
- [ ] keyd module imported in `modules/nixos/system/default.nix`

### macOS Only

- [ ] Running macOS (tested on macOS 13+)
- [ ] Homebrew installed
- [ ] User has admin rights (for permissions)
- [ ] `modules/darwin/karabiner.nix` exists
- [ ] `home/darwin/keyboard.nix` exists

---

## 🔧 What Gets Installed

### NixOS Installation

```
System packages:
- keyd (system service)

Home packages:
- VIA (keyboard configurator)
- VIAL (alternative configurator)

System services:
- keyd.service (starts at boot)

Configuration files:
- /etc/keyd/default.conf (generated from keyd.nix)
```

### macOS Installation

```
Homebrew casks:
- karabiner-elements (key remapper)
- via (keyboard configurator)

Configuration files:
- ~/.config/karabiner/karabiner.json (generated)

Launch agents:
- Karabiner-Elements (auto-starts)
```

---

## 🧪 Testing Procedures

### Universal Tests (Both Platforms)

#### Test 1: Caps Lock Dual Function
```
Expected behavior:
✓ Tap Caps (< 200ms) → Produces Escape
✓ Hold Caps (≥ 200ms) → Acts as modifier (Super/Cmd)
✓ Caps + C → Copies text
✓ Caps + V → Pastes text

Test in:
- Text editor
- Terminal
- Browser
```

#### Test 2: Navigation Layer
```
Expected behavior:
✓ RAlt + H/J/K/L → Arrow keys
✓ RAlt + Y → Home (line start)
✓ RAlt + O → End (line end)
✓ RAlt + U/I → Page Down/Up
✓ RAlt + W/B → Word forward/back

Test in:
- Text editor (multi-line document)
- Terminal (command line)
- Browser (web page)
```

#### Test 3: Media Controls
```
Expected behavior:
✓ RAlt + F8 → Play/Pause
✓ RAlt + F9 → Next track
✓ RAlt + F5/F6 → Volume down/up

Test with:
- Music playing (Spotify, Apple Music, etc.)
```

#### Test 4: F13 Backup Modifier
```
Expected behavior:
✓ F13 acts same as Caps Hold
✓ F13 + C → Copies text
✓ F13 + V → Pastes text

Test in:
- Text editor
```

### Platform-Specific Tests

#### NixOS: Window Management
```
Expected behavior:
✓ Caps + T → Opens terminal (Ghostty)
✓ Caps + D → Opens launcher (Fuzzel)
✓ Caps + Q → Closes window
✓ Caps + 1-9 → Switches workspaces
✓ Caps + H/L → Focuses left/right window

Test in:
- Niri compositor
- With multiple windows open
```

#### macOS: System Integration
```
Expected behavior:
✓ Caps + Space → Opens Spotlight
✓ Caps + Tab → App switcher
✓ Caps + W → Closes window
✓ Caps + Q → Quits application

Test in:
- Finder
- Safari/Chrome
- Multiple applications
```

---

## 🐛 Troubleshooting

### NixOS Issues

<details>
<summary><strong>keyd service not running</strong></summary>

```bash
# Check status
systemctl status keyd

# View logs
journalctl -u keyd -n 50

# Restart service
sudo systemctl restart keyd

# If still not working, rebuild
sudo nixos-rebuild switch --flake ~/.config/nix
```

</details>

<details>
<summary><strong>Caps Lock not working as modifier</strong></summary>

```bash
# Check keyd config
cat /etc/keyd/default.conf | grep capslock
# Should show: capslock = overload(super, esc)

# Test key events
wev
# Hold Caps → Should show KEY_LEFTMETA

# If wrong, check modules/nixos/system/keyd.nix
# Then rebuild
```

</details>

<details>
<summary><strong>Navigation layer not working</strong></summary>

```bash
# Check Right Alt mapping
cat /etc/keyd/default.conf | grep -A 10 "\[nav\]"
# Should show h = left, j = down, etc.

# Test in wev
wev
# Hold RAlt + H → Should show KEY_LEFT

# If wrong, rebuild
sudo nixos-rebuild switch --flake ~/.config/nix
```

</details>

### macOS Issues

<details>
<summary><strong>Karabiner not working</strong></summary>

```bash
# Check Karabiner is running
ps aux | grep karabiner | grep -v grep

# If not running, launch manually
open /Applications/Karabiner-Elements.app

# Check permissions
# System Settings → Privacy & Security
# Enable Karabiner in Input Monitoring & Accessibility

# Restart Karabiner
killall Karabiner-Elements
open /Applications/Karabiner-Elements.app
```

</details>

<details>
<summary><strong>Permissions not working</strong></summary>

**This is the #1 macOS issue!**

```bash
# Open System Settings
open "x-apple.systempreferences:com.apple.preference.security?Privacy"

# Manually enable:
1. Privacy & Security → Input Monitoring
   ✓ karabiner_grabber
   ✓ karabiner_observer

2. Privacy & Security → Accessibility
   ✓ Karabiner-Elements

# Restart Mac (if still not working)
sudo reboot
```

</details>

<details>
<summary><strong>Caps Lock not working as Command</strong></summary>

```bash
# Check Karabiner config
cat ~/.config/karabiner/karabiner.json | grep caps_lock

# Open Karabiner preferences
open /Applications/Karabiner-Elements.app

# Go to: Complex Modifications
# Should see: "Caps Lock → Cmd (hold) / Escape (tap)"

# If missing, rebuild
darwin-rebuild switch --flake ~/.config/nix
```

</details>

<details>
<summary><strong>Right Option conflicts with special characters</strong></summary>

**If you need Right Option for international characters:**

```nix
# Edit modules/darwin/karabiner.nix
# Change all "right_option" to "right_control"
# This uses Right Ctrl for navigation layer instead

# Then rebuild
darwin-rebuild switch --flake ~/.config/nix
```

</details>

---

## 🔄 Rollback Procedures

### NixOS Rollback

```bash
# Option 1: Use previous generation
sudo nixos-rebuild switch --rollback

# Option 2: Disable keyd temporarily
sudo systemctl stop keyd
sudo systemctl disable keyd

# Option 3: Remove keyd module
# Edit modules/nixos/system/default.nix
# Comment out: ./keyd.nix
# Then rebuild
```

### macOS Rollback

```bash
# Option 1: Quit Karabiner
killall Karabiner-Elements

# Option 2: Disable at startup
# System Settings → General → Login Items
# Remove Karabiner-Elements

# Option 3: Uninstall completely
brew uninstall --cask karabiner-elements

# Option 4: Rebuild without karabiner module
# Edit modules/darwin/default.nix
# Comment out: ./karabiner.nix
darwin-rebuild switch --flake ~/.config/nix
```

---

## 📊 Success Metrics

### Immediate Success (Day 1)

- [ ] Configuration applied without errors
- [ ] Service/application running
- [ ] Caps Lock tap produces Escape
- [ ] Caps Lock hold acts as modifier
- [ ] Right Option + H produces left arrow
- [ ] All basic tests pass

### Week 1 Success

- [ ] Can use Caps Hold for 5 most common shortcuts without thinking
- [ ] Can use RAlt arrows instead of physical arrows
- [ ] Caps Tap for Escape feels natural (vim users)
- [ ] No accidental caps lock activations
- [ ] Starting to forget F13 exists

### Week 2 Success

- [ ] All shortcuts are muscle memory
- [ ] Never reach for arrow keys
- [ ] Can use navigation layer in any application
- [ ] Noticeable speed improvement
- [ ] Reduced hand/wrist strain

### Week 4+ Mastery

- [ ] Everything is automatic
- [ ] 35% faster than before
- [ ] Can't imagine going back
- [ ] Recommending to others
- [ ] Works seamlessly on both platforms (if using both)

---

## 📚 Documentation Reference

### Getting Started
- [Quick Start](guides/keyboard-quickstart.md) - 5-minute setup
- [Cheat Sheet](guides/keyboard-cheatsheet.md) - **Print this!**

### Platform-Specific
- [macOS Guide](guides/keyboard-macos.md) - Complete macOS setup
- [Cross-Platform](guides/keyboard-cross-platform.md) - NixOS vs macOS comparison

### Advanced
- [Complete Reference](guides/keyboard-reference.md) - All shortcuts
- [Migration Guide](guides/keyboard-migration.md) - Learning timeline
- [Firmware Update](guides/keyboard-firmware-update.md) - Update keyboard

### Technical
- [Update Summary](KEYBOARD-UPDATE-SUMMARY.md) - What changed
- [NixOS keyd.nix](../modules/nixos/system/keyd.nix) - Configuration
- [macOS karabiner.nix](../modules/darwin/karabiner.nix) - Configuration

---

## 🎯 Deployment Timeline

### Immediate (0-5 minutes)
1. Run deployment command for your platform
2. Grant permissions (macOS only)
3. Run basic tests
4. Verify all core functionality works

### Short-term (Day 1)
1. Print cheat sheet
2. Practice 5 most common shortcuts
3. Test in different applications
4. Read migration guide

### Medium-term (Week 1)
1. Use daily with reference to cheat sheet
2. Force yourself to use new shortcuts
3. Practice navigation layer
4. Track progress

### Long-term (Week 2-4)
1. Build muscle memory
2. Remove cheat sheet
3. Achieve automatic shortcuts
4. Enjoy productivity gains

---

## ✅ Final Deployment Checklist

### Pre-Deployment
- [ ] Read this document completely
- [ ] Choose your platform (NixOS or macOS)
- [ ] Understand what will be installed
- [ ] Have rollback plan ready
- [ ] Print cheat sheet (optional)

### Deployment
- [ ] Run platform-specific deployment command
- [ ] Grant permissions (macOS)
- [ ] Verify service/application running
- [ ] Run all basic tests
- [ ] Verify tests pass

### Post-Deployment
- [ ] Read quick start guide
- [ ] Read cheat sheet
- [ ] Practice 5 most common shortcuts
- [ ] Set calendar reminder for Week 2 check-in
- [ ] Bookmark documentation

### Week 1 Check-in
- [ ] Review progress
- [ ] Adjust timing if needed (tap sensitivity)
- [ ] Practice difficult shortcuts
- [ ] Read migration guide tips

### Week 2+ Mastery
- [ ] Measure productivity gains
- [ ] Share setup with others
- [ ] Contribute improvements (optional)
- [ ] Enjoy ergonomic benefits!

---

## 🆘 Support

### Issues or Questions?

1. **Check troubleshooting section above**
2. **Read platform-specific guide:**
   - [macOS Guide](guides/keyboard-macos.md)
   - [Quick Start](guides/keyboard-quickstart.md)
3. **Check configuration files:**
   - NixOS: `modules/nixos/system/keyd.nix`
   - macOS: `modules/darwin/karabiner.nix`
4. **Review logs:**
   - NixOS: `journalctl -u keyd -f`
   - macOS: Karabiner Event Viewer

### Common Questions

**Q: Do I need to update firmware?**  
A: Recommended but not required. See [Firmware Update Guide](guides/keyboard-firmware-update.md).

**Q: Can I use this with other keyboards?**  
A: Yes! The OS-level remapping works with any keyboard.

**Q: Will this work on both my NixOS and macOS machines?**  
A: Yes! Same firmware, same muscle memory, different OS implementations.

**Q: What if I hate it?**  
A: Easy rollback! See rollback procedures above. But give it 2 weeks first!

**Q: Can I customize the shortcuts?**  
A: Yes! Edit the platform-specific .nix files and rebuild.

---

## 🎉 You're Ready!

**Everything is prepared and tested. Time to deploy!**

```
┌──────────────────────────────────────┐
│  🚀 Choose your platform above       │
│  📋 Follow the deployment steps      │
│  ✅ Run the tests                    │
│  🎹 Start typing ergonomically!      │
│  💪 Give it 2 weeks for mastery      │
└──────────────────────────────────────┘
```

**Good luck! You'll love the productivity boost!** ✨

---

**Last updated:** 2025-10-12  
**Version:** 2.0  
**Status:** Production Ready 🚀
