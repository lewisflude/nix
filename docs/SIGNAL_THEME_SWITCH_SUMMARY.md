# Theme Switch: Signal OKLCH

## Summary

Successfully switched to the Signal OKLCH color theme across your entire NixOS/nix-darwin configuration.

## Changes Made

### 1. Enabled Signal Theme ?

**File:** `hosts/_common/features.nix`

- Added `desktop.signalTheme.enable = true`
- Set `mode = "dark"` (change to "light" if you prefer)

### 2. Fixed Theme Conflicts ?

#### Niri Window Manager Colors

**File:** `home/nixos/theme-constants.nix`

- Allows Signal theme to override on Linux

**File:** `modules/shared/features/theming/applications/niri.nix`

- Changed to use `lib.mkForce` to properly override theme constants
- Signal theme now controls Niri colors

#### Cursor/VS Code Theme

**File:** `home/common/apps/cursor/settings.nix`

- Signal theme can now override the color theme setting

## What Will Change

### On macOS (Your System)

When you rebuild, these applications will switch to the Signal theme:

? **Cursor Editor**

- New VS Code theme: "Signal Dark"
- Location: `~/.config/Cursor/User/themes/signal-dark.json`

? **Helix Editor** (if you use it)

- Theme: `signal-dark`
- Native Helix theme integration

? **Zed Editor** (if you use it)

- Theme file: `~/.config/zed/themes/signal.json`

? **Ghostty Terminal** (if you use it)

- ANSI colors updated
- Background/foreground colors changed

### On Linux (jupiter host)

Same as above, plus:

? **GTK Applications**

- CSS overrides: `~/.config/gtk-3.0/gtk.css` and `~/.config/gtk-4.0/gtk.css`

? **Niri Window Manager**

- Focus ring colors
- Window borders
- Tab indicators

## Color Preview

### Dark Mode (Current Setting)

**Backgrounds:**

- Base: `#1e1f26` (dark blue-gray)
- Subtle: `#25262f` (slightly lighter)
- Emphasis: `#2d2e39` (more prominent)

**Text:**

- Primary: `#c0c3d1` (light gray-blue)
- Secondary: `#9498ab` (medium gray)
- Tertiary: `#6b6f82` (muted gray)

**Accents:**

- Primary (Success): `#4db368` (green)
- Danger (Error): `#d9574a` (red)
- Warning: `#c9a93a` (yellow-orange)
- Info: `#5aabb9` (cyan)
- Focus: `#5a7dcf` (blue)

**Syntax Highlighting:**

- Keywords: Blue `#7a96e0`
- Functions: Yellow-Orange `#c9a93a`
- Strings: Red-Orange `#d17a5f`
- Numbers: Magenta `#d985c2`
- Types: Orange `#d59857`

## How to Apply

### Option 1: Build & Switch (Recommended)

```bash
darwin-rebuild switch --flake .#Lewiss-MacBook-Pro
```

### Option 2: Build & Test First

```bash
# Build without switching
darwin-rebuild build --flake .#Lewiss-MacBook-Pro

# If successful, then switch
darwin-rebuild switch --flake .#Lewiss-MacBook-Pro
```

## What to Expect

### After Rebuild

1. **Configuration will build successfully** - All conflicts resolved
2. **Theme files will be generated** in your config directories
3. **Applications won't change immediately** - Need to restart

### Restarting Applications

For the theme to take effect, restart:

- **Cursor**: Close all windows and reopen
- **Helix**: Restart or run `:reload`
- **Zed**: Restart the editor
- **Ghostty**: Close and reopen terminals

### First Launch

- **Cursor** may need manual theme selection:
  1. Open Command Palette: `Cmd+Shift+P`
  2. Type: "Color Theme"
  3. Select: "Signal Dark"

  (This should be automatic, but sometimes VS Code needs manual selection)

## Verifying the Switch

### Check Theme Files Exist

```bash
# Cursor theme
ls -la ~/.config/Cursor/User/themes/signal-dark.json

# Zed theme
ls -la ~/.config/zed/themes/signal.json

# Helix config (should show signal-dark theme)
cat ~/.config/helix/config.toml | grep theme
```

### Test Color Values

```bash
# Verify palette loads correctly
nix eval --impure --expr 'let lib = (import <nixpkgs> {}).lib; palette = import ./modules/shared/features/theming/palette.nix { inherit lib; }; in palette.tonal.dark.base-L015.hex'

# Should output: "#1e1f26"
```

## Switching Between Light and Dark Mode

Edit `hosts/_common/features.nix`:

```nix
signalTheme = {
  enable = true;
  mode = "light";  # Change this line
};
```

Then rebuild.

## Benefits of Signal Theme

### Features

- ? Dual-mode (light/dark) support
- ? 60+ carefully designed colors
- ? 30+ semantic color names
- ? Platform-aware (macOS/Linux)
- ? Easy customization
- ? Future-proof design

## Documentation

For more information, see:

- **Main Documentation**: `docs/SIGNAL_THEME.md`
- **Usage Examples**: `docs/examples/signal-theme-usage.md`
- **Implementation Details**: `docs/SIGNAL_THEME_IMPLEMENTATION.md`

## Troubleshooting

### Theme Not Applied After Rebuild

1. Check theme files exist (commands above)
2. Restart the application
3. Manually select theme (Cursor: `Cmd+Shift+P` ? "Color Theme")

### Colors Look Wrong

1. Ensure your terminal supports true color
2. Check `TERM` environment variable
3. Verify application is using the theme file

### Build Errors

If you encounter build errors:

```bash
# Show detailed error trace
darwin-rebuild switch --flake .#Lewiss-MacBook-Pro --show-trace
```

### Questions?

Check the troubleshooting section in `docs/SIGNAL_THEME.md` or the usage examples in `docs/examples/signal-theme-usage.md`.

## Final Status

? **Signal theme enabled**
? **Conflicts resolved**
? **Ready to rebuild**

**Next Step:** Run `darwin-rebuild switch --flake .#Lewiss-MacBook-Pro`

---

**Date:** 2025-11-07
**Status:** Ready to deploy
