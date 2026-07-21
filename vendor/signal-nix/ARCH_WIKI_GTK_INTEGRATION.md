# Arch Wiki GTK Integration - Implementation Summary

## What We Learned from the Arch Wiki

The [Arch Linux GNOME documentation](https://wiki.archlinux.org/title/GNOME) provides comprehensive guidance on configuring GNOME/GTK environments. While targeted at GNOME users, many concepts apply to any Linux desktop using GTK applications.

### Key Insights

1. **dconf/gsettings behavioral settings** complement visual theming
2. **color-scheme preference** (`prefer-dark`/`prefer-light`) is the standard way to tell GTK apps which theme variant to use
3. **Font rendering settings** (antialiasing, hinting) significantly impact text clarity
4. **Touchpad settings** improve laptop UX
5. **Night Light** provides blue light filtering
6. **Application-specific defaults** (file manager, text editor) enhance usability

### What Was NOT Relevant

Since we use **niri** (not GNOME Shell), these Arch Wiki sections don't apply:

- ❌ GNOME Shell extensions
- ❌ GDM-specific configuration (system-level)
- ❌ Mutter window manager settings
- ❌ GNOME Settings daemon plugins
- ❌ Power management (handled at system level)

## What Was Implemented

### New Module: `modules/gtk/dconf.nix`

A comprehensive dconf behavioral settings module that complements signal-nix's existing GTK visual theming.

#### Features

1. **Automatic color-scheme preference**
   - Sets `prefer-dark` or `prefer-light` based on Signal's theme mode
   - Follows FreeDesktop Dark Style Preference specification

2. **Font rendering configuration**
   - Antialiasing method (none, grayscale, rgba)
   - Hinting style (none, slight, medium, full)
   - Optimized defaults for LCD monitors

3. **Touchpad settings**
   - Tap-to-click
   - Click method (areas vs fingers)
   - Natural scroll direction

4. **Night Light support**
   - Optional blue light filter
   - Configurable color temperature (2700K-6500K)

5. **Application defaults**
   - Nautilus (Files) preferences
   - GNOME Text Editor settings

6. **Interface behaviors**
   - Clock format (12h/24h)
   - Show weekday toggle
   - Animation enable/disable

### Module Organization

```
modules/gtk/
├── default.nix  # Module group (imports theme.nix + dconf.nix)
├── theme.nix    # Visual theming (CSS, colors, Adwaita palette)
└── dconf.nix    # Behavioral settings (NEW)
```

### Configuration API

```nix
theming.signal.gtk.dconf = {
  enable = true;  # Default: true (auto-enabled with GTK theming)

  # All configurable options
  clockFormat = "24h";
  clockShowWeekday = false;
  enableAnimations = true;
  fontAntialiasing = "rgba";
  fontHinting = "slight";

  touchpad = {
    tapToClick = true;
    clickMethod = "fingers";
    naturalScroll = false;
  };

  nightLight = {
    enable = false;
    temperature = 4500;
  };
};
```

## Why This Matters for niri Users

Even though we use niri (not GNOME), these dconf settings are valuable because:

1. **xdg-desktop-portal-gnome** - We use this portal which reads dconf
2. **GTK applications** - All GTK apps respect these settings
3. **File dialogs** - Portal file picker follows color-scheme preference
4. **Font clarity** - System-wide improvement for GTK text rendering
5. **Future compatibility** - Settings carry over if switching to GNOME

## Integration Points

### With Existing signal-nix Architecture

- **Follows tier system** - Uses structured configuration (Tier 2)
- **Uses semantic bridge** - Accesses Signal colors via `semantic` helper
- **Respects theme mode** - Reacts to light/dark/auto setting
- **Automatic activation** - Enabled by default when GTK theming is active
- **Optional override** - Can be disabled independently

### With User's NixOS Config

Works seamlessly with existing setup:

```nix
# In your nix-config
features.desktop.signalTheme = {
  enable = true;
  mode = "dark";
};

# signal-nix automatically provides:
# 1. GTK visual theming (colors, CSS)
# 2. GTK behavioral settings (dconf) ← NEW
```

## Documentation Added

1. **`docs/gtk-dconf-integration.md`** - Comprehensive technical documentation
2. **`docs/configuration-guide.md`** - Updated with dconf section
3. **`examples/gtk-complete.nix`** - Complete GTK theming example
4. **`ARCH_WIKI_GTK_INTEGRATION.md`** - This summary

## Testing

Verify dconf settings are applied:

```bash
# Color scheme preference
gsettings get org.gnome.desktop.interface color-scheme

# Font rendering
gsettings get org.gnome.desktop.interface font-antialiasing
gsettings get org.gnome.desktop.interface font-hinting

# Touchpad
gsettings get org.gnome.desktop.peripherals.touchpad tap-to-click

# Night Light
gsettings get org.gnome.settings-daemon.plugins.color night-light-temperature
```

## Files Modified/Created

### New Files
- `modules/gtk/dconf.nix` - Behavioral settings module
- `docs/gtk-dconf-integration.md` - Technical documentation
- `examples/gtk-complete.nix` - Complete example
- `ARCH_WIKI_GTK_INTEGRATION.md` - This summary

### Modified Files
- `modules/gtk/default.nix` - Now imports both theme.nix and dconf.nix
- `modules/gtk/theme.nix` - Renamed from default.nix (no content changes)
- `docs/configuration-guide.md` - Added dconf section

## Benefits

### For Users

1. **One-line setup** - Behavioral settings enabled automatically
2. **Better UX** - Improved font rendering, touchpad behavior
3. **Consistency** - GTK apps follow Signal's theme mode
4. **Flexibility** - All settings configurable or disableable

### For signal-nix

1. **More complete** - Behavioral + visual theming
2. **Standards compliant** - Follows FreeDesktop specs
3. **Well documented** - Clear examples and guides
4. **Future-proof** - Works with GNOME or standalone GTK

## Next Steps

Potential future enhancements:

1. **Cursor settings** - Size and theme configuration
2. **Accessibility** - High contrast, large text options
3. **More app defaults** - Additional GNOME app preferences
4. **Theme-aware values** - Derive some settings from Signal palette
5. **Monitor detection** - Auto-select font settings based on monitor type

## References

- [Arch Wiki: GNOME](https://wiki.archlinux.org/title/GNOME)
- [FreeDesktop Dark Style Preference](https://gitlab.freedesktop.org/xdg/xdg-specs/-/merge_requests/9)
- [Adwaita CSS Variables](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/css-variables.html)
- [GTK Documentation](https://docs.gtk.org/)
- [signal-nix Repository](https://github.com/lewisflude/signal-nix)
