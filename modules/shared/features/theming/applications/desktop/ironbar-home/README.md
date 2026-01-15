# Ironbar Design System Implementation

**Status**: Complete ✅  
**Profile**: Relaxed (1440p+)  
**Theme**: Signal (Dark Mode)  
**Design Version**: 1.0  
**Date**: 2026-01-15

## Overview

This module provides a complete, production-ready implementation of the Ironbar status bar following a formal design specification. The implementation uses **Atomic Design methodology** and integrates seamlessly with the Niri window manager.

## Architecture

The module is structured in layers following atomic design principles:

```
ironbar-home/
├── tokens.nix          # Design tokens (colors, spacing, typography, etc.)
├── config.nix          # Widget configuration generator
├── style.css           # Complete CSS implementation (atoms → templates)
├── default.nix         # Home-manager module entry point
└── README.md           # This file
```

### Design System Hierarchy

```
🔹 Design Tokens
   └── Colors, spacing, typography, opacity, shadows, transitions
       ↓
🔹 Atoms (5 primitives)
   └── Text Label, Icon, Accent Bar, Spacer, Divider
       ↓
🔹 Molecules (6 functional units)
   └── Icon-Label Pair, Numeric Display, Workspace Button,
       Control Button, Tray Icon, Badge
       ↓
🔹 Organisms (10 widgets)
   └── Workspaces, Window Title, Layout Indicator, Brightness,
       Volume, System Tray, Battery, Notifications, Clock, Power
       ↓
🔹 Templates (7 containers)
   └── Island (base), Start Island, Center Island, End Island,
       Bar Container, Popup Container, Clock Popup
       ↓
🔹 State Patterns (6 patterns)
   └── Active, Hover, Default, Warning, Critical, Urgent
       ↓
🔹 Animations (3 keyframes)
   └── Pulse, Urgent Pulse, Fade In
```

## Features

### ✅ Implemented Features

- **Complete Design System**: All layers from atoms to templates
- **10 Functional Widgets**: All organisms from design spec
- **Niri Synchronization**: Border radii and gaps match Niri windows
- **GTK CSS Compliance**: Works within GTK4 CSS limitations
- **Profile System**: Relaxed profile optimized for 1440p+ displays
- **State Management**: Consistent interaction patterns across all widgets
- **Accessibility**: Minimum 24px touch targets throughout
- **Layout Stability**: Fixed-width elements prevent reflow
- **Hot Reload**: CSS changes apply immediately without restart

### 🎨 Widgets Included

**Start Island:**
- Workspaces (Niri integration, circled Unicode numbers ①-⑩)

**Center Island:**
- Window Title (with application icon, truncates at 50 chars)

**End Island:**
1. Layout Indicator (fullscreen, maximized, floating, etc.)
2. Brightness Control (click to adjust, middle-click reset)
3. Volume Control (dynamic icon, scroll to adjust)
4. System Tray (dynamic expansion/contraction)
5. Battery Indicator (warning/critical states with animation)
6. Notification Button (swaync integration, badge count)
7. Clock (24-hour format, popup with full date)
8. Power Button (fuzzel power menu)

## Usage

### Basic Setup

The module is already wired up in `home/nixos/apps/ironbar.nix` and imported in `home/nixos/default.nix`.

To enable:

```nix
# Already enabled by default when imported
programs.ironbar.enable = true;
```

### Configuration Override

To customize the default configuration:

```nix
programs.ironbar = {
  enable = true;
  
  # Override specific widgets or settings
  extraConfig = {
    # Example: Change bar height
    height = 42;
    
    # Example: Add custom widget to end island
    end = [
      # Default widgets remain, add custom ones here
      {
        type = "custom";
        name = "my-widget";
        # ...
      }
    ];
  };
};
```

### Styling Customization

The stylesheet at `style.css` can be customized by copying it to your config:

```nix
xdg.configFile."ironbar/style.css".text = ''
  /* Your custom CSS here */
  @import url('path/to/base/style.css');
  
  /* Override specific styles */
  .clock {
    font-size: 20px;
  }
'';
```

## Design Tokens

All design values are centralized in `tokens.nix`:

```nix
tokens = {
  bar.height = 48;              # Bar height (px)
  bar.margin = 12;              # Synced with Niri gaps
  
  colors = {
    text.primary = "#c0c3d1";
    accent.focus = "#5a7dcf";
    # ...
  };
  
  spacing.md = 12;              # Comfortable spacing
  radius.lg = 16;               # Island radius (synced with Niri)
  
  # ... (see tokens.nix for complete list)
};
```

### Niri Synchronization

Critical values synchronized with Niri:

| Ironbar | Niri Setting | Value |
|---------|--------------|-------|
| `radius.lg` | `geometry-corner-radius` | 16px |
| `bar.margin` | `layout.gaps` | 12px |

Ensure these match in your Niri config for visual harmony.

## Widget Integration

### Niri Integration

Workspaces and window title widgets use Niri IPC for real-time updates:

```nix
# Workspaces automatically integrate with Niri
{
  type = "workspaces";
  compositor = "niri";
  # Real-time workspace state updates
}
```

### swaync Integration

Notification button integrates with SwayNC:

```bash
# Opens notification center on click
swaync-client -t
```

### Volume/Brightness Control

Uses standard Linux tools:

- **Volume**: `wpctl` (WirePlumber)
- **Brightness**: `brightnessctl`

## GTK CSS Limitations

This implementation works within GTK CSS constraints:

| Feature | Standard CSS | GTK CSS | Workaround |
|---------|--------------|---------|------------|
| Transform | ✅ | ❌ | Opacity animations only |
| Drop shadows | ✅ | ❌ | Inset highlights |
| OKLCH colors | ✅ | ❌ | Pre-converted to hex |
| :empty | ✅ | ❌ | Widget visibility logic |

All limitations are documented and handled appropriately.

## File Structure

```
modules/shared/features/theming/applications/desktop/ironbar-home/
├── default.nix       # Home-manager module entry point
├── tokens.nix        # Complete design token system
├── config.nix        # JSON config generator (all 10 widgets)
├── style.css         # Full CSS implementation (atoms → templates)
└── README.md         # This documentation

home/nixos/apps/
└── ironbar.nix       # NixOS-specific app module (enables ironbar)
```

## Testing

### Reload Configuration

After making changes:

```bash
# Ironbar hot-reloads CSS automatically
# For config changes:
ironbar reload
```

### Validate Flake

```bash
nix flake check
```

### Inspect Widgets

```bash
# GTK Inspector for CSS debugging
ironbar inspect
```

## Design Principles

### Visual Hierarchy

1. **Clock** (visual anchor) - Highest emphasis
2. **Window Title** (current context) - High emphasis
3. **Interactive Controls** - Medium emphasis
4. **System Tray** (passive info) - Lower emphasis

### Gestalt Principles Applied

- **Common Region**: Islands group related widgets via background
- **Proximity**: Widgets within islands are close; islands separated
- **Similarity**: All islands share visual treatment
- **Continuity**: Horizontal layout guides left-to-right scanning

### State Pattern Consistency

All interactive elements use the **Active State Pattern**:

```css
/* 3px left accent bar */
border-left: 3px solid <accent-color>;
border-top-left-radius: 0;
border-bottom-left-radius: 0;
padding-left: original - 3px;
```

This creates visual consistency across:
- Workspace buttons
- Window title
- Control buttons
- Tray icons
- Battery indicator (warning/critical)
- Power button (danger variant)

## Troubleshooting

### Bar not visible

Check systemd service:

```bash
systemctl --user status ironbar
journalctl --user -u ironbar -f
```

### Styling not applied

Verify CSS file location:

```bash
ls -la ~/.config/ironbar/style.css
```

### Widgets not working

Check feature flags in `home/nixos/apps/ironbar.nix`:

```nix
features = [
  "tray"
  "workspaces"
  "volume"
  "notifications"
  "upower"
];
```

## Contributing

When modifying this design system:

1. **Follow the hierarchy**: Changes should respect atomic design structure
2. **Use tokens**: Never use magic numbers, reference `tokens.nix`
3. **Document rationale**: Explain design decisions in comments
4. **Test thoroughly**: Verify on 1440p+ displays
5. **Maintain sync**: Keep Niri values synchronized

## References

- **Design Spec**: `/tmp/ironbar-design-spec.md` (source)
- **Ironbar Docs**: https://github.com/JakeStanger/ironbar
- **GTK CSS**: https://docs.gtk.org/gtk4/css-overview.html
- **Atomic Design**: https://atomicdesign.bradfrost.com/

## Version History

- **v1.0** (2026-01-15): Initial complete implementation
  - All 10 widgets from design spec
  - Complete CSS (atoms through templates)
  - Full design token system
  - Niri synchronization
  - GTK CSS compliance

## License

Follows the license of the parent repository (NixOS configuration).

---

**Implementation Status**: Production Ready ✅  
**Quality Level**: Professional-grade following formal design specification  
**Maintenance**: Active
