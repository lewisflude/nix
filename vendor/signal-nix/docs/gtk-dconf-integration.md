# GTK dconf Integration

## Overview

Signal-nix provides comprehensive GTK theming in two layers:

1. **Visual Theming** (`modules/gtk/theme.nix`) - Colors, CSS, Adwaita palette mapping
2. **Behavioral Settings** (`modules/gtk/dconf.nix`) - Interface behavior, font rendering, system preferences

This document describes the dconf behavioral settings layer.

## Background

The [Arch Wiki GNOME documentation](https://wiki.archlinux.org/title/GNOME) details numerous dconf/gsettings configurations that control GTK application behavior. While Signal already provides excellent visual theming, these behavioral settings complement the visual layer by configuring:

- **color-scheme preference** - FreeDesktop Dark Style Preference spec
- **Font rendering** - Antialiasing and hinting for various monitor types
- **Interface behaviors** - Animations, clock format, etc.
- **Touchpad settings** - Tap-to-click, natural scroll, click methods
- **Night Light** - Blue light filter temperature
- **Application defaults** - File manager, text editor preferences

## What Was Implemented

### Module: `modules/gtk/dconf.nix`

A structured dconf configuration module that provides sensible defaults for GTK applications, automatically enabled when GTK theming is active.

### Key Features

#### 1. Color Scheme Preference

Automatically sets `org.gnome.desktop.interface.color-scheme` based on Signal's theme mode:

```nix
color-scheme = if themeMode == "light" then "prefer-light" else "prefer-dark";
```

This tells GTK applications (and the xdg-desktop-portal-gnome that your config uses) whether to use light or dark variants of their UI.

#### 2. Font Rendering

Configurable antialiasing and hinting for optimal text clarity:

```nix
fontAntialiasing = "rgba";  # Subpixel antialiasing (LCD monitors)
fontHinting = "slight";     # Subtle hinting (modern fonts)
```

Recommendations:
- **LCD monitors**: `rgba` + `slight`
- **High-DPI/Retina**: `grayscale` + `slight`
- **Projectors**: `rgba` + `medium`

#### 3. Touchpad Settings

Laptop-friendly defaults that work well with niri's gesture support:

```nix
touchpad = {
  tapToClick = true;         # Tap to click
  clickMethod = "fingers";   # Two-finger right-click
  naturalScroll = false;     # Traditional scroll direction
};
```

#### 4. Night Light Support

Optional blue light filter for evening computing:

```nix
nightLight = {
  enable = false;        # Disabled by default
  temperature = 4500;    # Warm color temperature (Kelvin)
};
```

Temperature range: 2700K (very warm) to 6500K (neutral).

#### 5. Application Defaults

Sensible defaults for GNOME applications:

- **Nautilus** (Files): List view by default, hidden files off
- **GNOME Text Editor**: Signal color scheme, line numbers enabled

## Configuration

### Default Behavior

dconf settings are **enabled by default** when GTK theming is active:

```nix
theming.signal.gtk.enable = true;  # Also enables dconf by default
```

### Full Configuration

```nix
theming.signal.gtk.dconf = {
  enable = true;

  # Clock settings
  clockFormat = "24h";
  clockShowWeekday = false;

  # Interface
  enableAnimations = true;

  # Font rendering
  fontAntialiasing = "rgba";
  fontHinting = "slight";

  # Touchpad
  touchpad = {
    tapToClick = true;
    clickMethod = "fingers";
    naturalScroll = false;
  };

  # Night Light
  nightLight = {
    enable = false;
    temperature = 4500;
  };
};
```

### Disabling dconf

For visual theming only without behavioral settings:

```nix
theming.signal.gtk = {
  enable = true;
  dconf.enable = false;  # No behavioral settings
};
```

## Integration with niri

Since you use niri (not GNOME Shell), these dconf settings are still valuable because:

1. **xdg-desktop-portal-gnome** - You use this portal which reads dconf settings
2. **GTK applications** - All GTK apps respect these settings
3. **color-scheme preference** - Portal file picker dialogs follow the preference
4. **Font rendering** - System-wide font clarity improvement
5. **Touchpad settings** - Complement niri's built-in touchpad support

## What These Settings Don't Control

The dconf module does **not** configure:

- ❌ **GNOME Shell extensions** (not applicable with niri)
- ❌ **GDM settings** (system-level, requires NixOS module)
- ❌ **Mutter window manager** (you use niri)
- ❌ **GNOME Settings daemon plugins** (not running with niri)
- ❌ **Power management** (handled by system-level NixOS config)

These are system-level concerns handled by your existing NixOS configuration.

## Benefits for Your Setup

### Current Setup (niri + xdg-desktop-portal-gnome)

1. **File pickers** from portal follow Signal's dark/light mode
2. **GTK file dialogs** use Signal colors and proper font rendering
3. **Nautilus** (if used) gets Signal theming + sensible defaults
4. **Font clarity** improved system-wide for GTK text
5. **Consistent UX** between niri and GTK applications

### Future: If Switching to GNOME

The dconf settings are forward-compatible. If you later decide to use GNOME instead of niri, these settings will immediately apply to:

- GNOME Shell interface
- System Settings panels
- All GNOME core applications
- GTK widgets throughout the desktop

## Related Arch Wiki Sections

This implementation was informed by these Arch Wiki GNOME sections:

- **Configuration → System settings → Color** - `color-scheme` preference
- **Configuration → System settings → Night Light** - Temperature setting
- **Configuration → System settings → Mouse and touchpad** - Touchpad settings
- **Configuration → Fonts** - Antialiasing and hinting
- **Configuration → System settings → Date & time** - Clock format

## Examples

See [`examples/gtk-complete.nix`](../examples/gtk-complete.nix) for a complete configuration showcasing both visual and behavioral GTK theming.

## Testing

To verify dconf settings are applied:

```bash
# Check color-scheme
gsettings get org.gnome.desktop.interface color-scheme

# Check font rendering
gsettings get org.gnome.desktop.interface font-antialiasing
gsettings get org.gnome.desktop.interface font-hinting

# Check touchpad settings
gsettings get org.gnome.desktop.peripherals.touchpad tap-to-click
gsettings get org.gnome.desktop.peripherals.touchpad click-method

# Check Night Light
gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled
gsettings get org.gnome.settings-daemon.plugins.color night-light-temperature
```

## Future Enhancements

Potential additions based on user feedback:

1. **Cursor settings** - Cursor size and theme
2. **Accessibility** - High contrast, large text options
3. **Window button layout** - CSD button order preference
4. **File manager** - More Nautilus/Files preferences
5. **Text editor** - Additional GNOME Text Editor settings

## References

- [Arch Wiki: GNOME](https://wiki.archlinux.org/title/GNOME)
- [Adwaita CSS Variables](https://gnome.pages.gitlab.gnome.org/libadwaita/doc/main/css-variables.html)
- [FreeDesktop Dark Style Preference](https://gitlab.freedesktop.org/xdg/xdg-specs/-/merge_requests/9)
- [GTK Font Rendering](https://docs.gtk.org/gtk3/css-properties.html)
- [Signal Palette](https://github.com/lewisflude/signal-palette)
