# New Tools Usage Guide

## 🚀 **Upgraded Tools Overview**

### **1. `swayimg` - Image Viewer**
**Replaced:** `imv`
**Usage:**
```bash
swayimg image.jpg                    # Basic usage
swayimg --scale=fit image.png        # Fit to window
swayimg --fullscreen image.gif       # Fullscreen mode
```
**Features:** Better Wayland scaling, fractional scaling support, more responsive

### **2. `dragon-drop` - Drag & Drop from Terminal**
**New Tool**
**Usage:**
```bash
dragon-drop image.jpg                # Drag image to GUI apps
dragon-drop *.png                    # Drag multiple images
dragon-drop --target                 # Create drop target (receive files)
dragon-drop --and-exit image.jpg     # Exit after first drag
```
**Pro Tip:** Add aliases to your shell:
```bash
alias drag='dragon-drop'
alias drop='dragon-drop --target'
```

### **3. `trash-cli` - Safe File Deletion**
**Standard Tool**
**Usage:**
```bash
trash file.txt                      # Safe delete (to trash)
trash-list                          # List deleted files
trash-restore                       # Restore files interactively
trash-empty                         # Empty trash
trash-empty 30                      # Empty files older than 30 days
```

### **4. `wtype` - Text Automation**
**New Tool**
**Usage:**
```bash
wtype "Hello, World!"                # Type text
wtype -d 100 "Slow typing"           # 100ms delay between characters
echo "clipboard content" | wtype -   # Type from stdin

# Useful in scripts or waybar modules:
wtype "$(date '+%Y-%m-%d %H:%M:%S')" # Type current timestamp
```

### **5. SwayNC - Notification Center**
**Replaced:** `mako`
**Usage:**
- **Click notification icon in waybar** - Toggle notification center
- **Right-click notification icon** - Toggle do-not-disturb
- **Keyboard shortcuts in notification center:**
  - `Escape` - Close
  - `Delete/Backspace` - Clear notifications
  - `Tab` - Navigate

**Test notifications:**
```bash
notify-send "Test" "This is a test notification"
notify-send -u critical "Alert" "Critical notification"
notify-send -t 5000 "Timeout" "5 second notification"
```

## 🎯 **Workflow Integration Examples**

### **Image Workflow with New Tools:**
```bash
# View images with better Wayland support
swayimg ~/Pictures/*.jpg

# Drag images from terminal to Discord/Slack/etc
dragon-drop ~/Pictures/screenshot.png

# Or use with yazi for file browsing + drag-drop
yazi ~/Pictures
# Then press 'o' to open with swayimg, or drag with dragon-drop
```

### **Enhanced File Management:**
```bash
# Safe file operations
trash old-files/                     # Move to trash instead of rm -rf
trash-list                          # See what you've deleted
trash-restore                       # Interactively restore files
```

### **Text Automation Workflows:**
```bash
# Create waybar scripts for common text
echo '#!/bin/bash
case "$1" in
  email) wtype "your-email@domain.com" ;;
  date) wtype "$(date '+%Y-%m-%d')" ;;
  timestamp) wtype "$(date '+%Y-%m-%d %H:%M:%S')" ;;
esac' > ~/bin/text-snippets
```

## 📋 **What Was Removed/Changed:**
- ✅ `grimblast` → Use niri's built-in screenshot (Mod+Shift+S)
- ✅ `imv` → `swayimg` (better Wayland support)
- ✅ Using `trash-cli` for safe file deletion
- ✅ `mako` → `swaync` (notification history + center)
- ✅ Added font rendering enhancement for sharper text
- ✅ Added `tmux` alongside `zellij` for compatibility

## 🚀 **Next Steps:**
1. Rebuild your system: `nh os switch`
2. Test new tools with the examples above
3. Set up shell aliases for frequently used commands
4. Customize SwayNC themes in `~/.config/swaync/` if needed

Enjoy your upgraded Wayland setup! 🎉
