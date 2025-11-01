# Catppuccin Theming - Remaining Work

## ✅ COMPLETED: Conflicts Fixed

The following conflicts have been resolved:

1. ✅ **zellij** - Removed `theme = "default"` conflict
2. ✅ **micro** - Removed `colorscheme = lib.mkForce "default"` conflict
3. ✅ **gtklock** - Updated to use `"Catppuccin-GTK-Dark"` theme

## ✅ COMPLETED: Phase 3 - Config Files

4. ✅ **Mangohud** - Updated with Catppuccin Mocha colors
   - GPU stats: Blue
   - CPU stats: Red
   - RAM stats: Peach
   - FPS: Mauve
   - Frame timing: Lavender
   - Background: Base color with transparency
   - Text: Catppuccin text color

5. ✅ **MPV** - Created config file with Catppuccin Mocha colors
   - OSD colors: Catppuccin text/base
   - Subtitle colors: Catppuccin text/base
   - Seek bar: Mauve/Lavender
   - Added to `home/nixos/apps/mpv.nix`

6. ✅ **Swappy** - Updated with Catppuccin Mocha colors
   - Fill color: Base color with transparency
   - Line color: Mauve accent color
   - Text color: Catppuccin text color

7. ✅ **System-level options** - Added commented options in `modules/nixos/core/boot.nix`
   - GRUB bootloader theme (commented, ready to enable)
   - TTY console colors (commented, ready to enable)
   - Plymouth boot splash (commented, ready to enable if Plymouth is enabled)

## 🔵 Verification Steps (After Rebuild)

After rebuilding your system, verify that catppuccin theming is working:

1. **zellij** - Start zellij and verify it uses catppuccin theme (not default)
2. **micro** - Open micro editor and verify it uses catppuccin colorscheme
3. **gtklock** - Lock screen should use catppuccin GTK theme
4. **swappy** - Take a screenshot annotation and verify colors are catppuccin (mauve lines, base fill)
5. **Mangohud** - Launch a game and verify overlay uses catppuccin colors
6. **MPV** - Play a video and verify OSD/subtitles use catppuccin colors
7. **Other auto-enabled apps** - Check delta, atuin, ghostty, helix, yazi, lazygit, eza, fzf, zed, btop, wofi, chromium, thunderbird

## 🟡 Optional: Desktop Applications Without Catppuccin Modules

These applications don't have catppuccin/nix modules but can be themed manually:

### 1. **Discord**

- **Location**: `home/nixos/desktop-apps.nix:19`
- **Method**:
  - Use Discord's built-in appearance settings
  - Or install BetterDiscord/Vencord and use Catppuccin theme
- **Action**: Manual configuration in Discord app
- **Difficulty**: Easy

### 2. **Telegram Desktop**

- **Location**: `home/nixos/desktop-apps.nix:20`
- **Method**:
  - Telegram Settings → Appearance → Theme
  - Use built-in dark theme or install Catppuccin theme from Telegram themes
- **Action**: Manual configuration in Telegram app
- **Difficulty**: Easy

### 3. **Obsidian**

- **Location**: `home/common/apps/obsidian.nix`
- **Method**:
  - Open Obsidian
  - Settings → Appearance → Themes
  - Install "Catppuccin" theme from community themes
- **Action**: Manual installation via Obsidian UI
- **Difficulty**: Easy

### 4. **MPV** (Video Player)

- **Location**: `home/nixos/desktop-apps.nix:11`
- **Method**:
  - Check if catppuccin mpv theme exists at <https://github.com/catppuccin/mpv>
  - Add theme configuration to `~/.config/mpv/config` or create mpv config module
- **Action**:
  - Research catppuccin mpv theme availability
  - Add config file if theme exists
- **Difficulty**: Medium (requires research and config file creation)

### 5. **Mangohud** (Gaming Overlay)

- **Location**: `home/nixos/apps/gaming.nix:13`
- **Method**:
  - Check Mangohud documentation for color customization
  - Configure colors in `~/.config/MangoHud/MangoHud.conf`
- **Action**:
  - Research Mangohud color options
  - Create config file with catppuccin colors
- **Difficulty**: Medium (requires research and config file creation)

## 🔵 System-Level Theming (NixOS Modules)

These require NixOS module configuration, not Home Manager:

### 1. **GRUB Bootloader**

- **Location**: `modules/nixos/core/boot.nix`
- **Method**:
  - Add `catppuccin.grub.enable = true;` to NixOS configuration
  - Configure in system configuration, not home-manager
- **Action**:
  - Add to `modules/nixos/core/boot.nix` or host configuration
  - Research catppuccin grub module options
- **Difficulty**: Medium (requires NixOS module configuration)
- **Note**: Only relevant if using GRUB bootloader

### 2. **Plymouth Boot Splash**

- **Location**: NixOS configuration (if Plymouth is enabled)
- **Method**:
  - Add `catppuccin.plymouth.enable = true;` to NixOS configuration
  - Requires Plymouth to be enabled first
- **Action**:
  - Check if Plymouth is enabled
  - Add catppuccin plymouth module if desired
- **Difficulty**: Medium (requires NixOS module configuration)
- **Note**: Only relevant if Plymouth is enabled

### 3. **TTY Virtual Console**

- **Location**: NixOS configuration
- **Method**:
  - Add `catppuccin.tty.enable = true;` to NixOS configuration
  - Configures virtual console colors
- **Action**:
  - Add to NixOS configuration if desired
  - Research catppuccin tty module options
- **Difficulty**: Medium (requires NixOS module configuration)
- **Note**: Useful for console sessions

## 📋 Implementation Plan

### Phase 1: Verification (Immediate)

1. ✅ Rebuild system with fixed conflicts
2. 🔄 Verify zellij uses catppuccin theme
3. 🔄 Verify micro uses catppuccin colorscheme
4. 🔄 Verify gtklock uses catppuccin GTK theme
5. 🔄 Spot-check other auto-enabled applications

### Phase 2: Easy Desktop Apps (Quick Wins)

1. **Discord**: Open Discord → Settings → Appearance → apply catppuccin theme (if available)
2. **Telegram**: Open Telegram → Settings → Appearance → Theme → install catppuccin theme
3. **Obsidian**: Open Obsidian → Settings → Appearance → Themes → install "Catppuccin"

### Phase 3: Research & Config Files (Medium Effort)

1. ✅ **MPV**: Created config file with catppuccin colors
2. ✅ **Mangohud**: Updated config with catppuccin colors

### Phase 4: System-Level (Optional, NixOS)

1. ✅ **GRUB/TTY/Plymouth**: Added commented options in `modules/nixos/core/boot.nix` (ready to enable if desired)

## 🎯 Priority Recommendations

**High Priority:**

- ✅ Verification (Phase 1) - Essential to ensure fixes work

**Medium Priority:**

- Phase 2 (Discord, Telegram, Obsidian) - Easy wins with immediate visual impact

**Low Priority:**

- ✅ Phase 3 (MPV, Mangohud) - COMPLETED
- ✅ Phase 4 (System-level) - Options added, ready to enable
- Phase 2 (Discord, Telegram, Obsidian) - Manual app configuration only

## 📝 Notes

- ✅ **Mangohud** - Now uses Catppuccin Mocha colors (automatically pulls from palette)
- ✅ **MPV** - Now uses Catppuccin Mocha colors for OSD and subtitles
- ✅ **Swappy** - Now uses Catppuccin Mocha colors for annotation tools
- ✅ **System-level** - Options are ready in `modules/nixos/core/boot.nix` (commented out, uncomment to enable)
- Desktop applications (Discord, Telegram, Obsidian) require manual configuration in their respective apps
- Most catppuccin modules are already enabled via `catppuccin.enable = true`
- Verify theming works after rebuild before proceeding with optional manual app configuration
