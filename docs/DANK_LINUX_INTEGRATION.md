# Dank Linux Feature Integration

This document describes the Dank Linux ecosystem features integrated into this NixOS configuration.

## Overview

The configuration now includes all available Dank Linux components from the danklinux.com ecosystem, providing a complete Material Design 3 desktop experience on Niri.

## Integrated Components

### ✅ DankMaterialShell (DMS)

**Status**: Fully Configured

**Location**: `home/nixos/dank-material-shell.nix`

**Core Features Enabled**:
- System monitoring widgets (via dgop backend)
- VPN management widget
- Dynamic theming (wallpaper-based Material Design 3 via matugen)
- Audio visualization (via cava)
- Calendar events integration (via khal)
- Clipboard paste support (via wtype)

**Desktop Features** (available via DMS runtime settings):
- **Browser Picker**: Modal dialog for choosing browser when opening URLs
- **Lock Screen**: Integrated screen locker with media controls
- **Night Light**: Gamma control for blue light reduction
- **Power Management**: Idle handling, suspend automation, fullscreen inhibit

**Clipboard Manager** (built-in):
- History tracking (text and images)
- Pinning items
- Persistent across sessions

**Note**: Desktop features like Night Light and Power Management are configured via the DMS Settings UI or CLI (`dms settings`), not through Nix options.

**Built-in Components** (no separate packages needed):
- **Dank Dash**: Dashboard with media controls, weather, calendar, system info
- **Launcher**: Application launcher with filesystem search (fuzzel-based)
- **Control Center**: System settings and quick toggle interface

These are integral parts of DMS and activate automatically when DMS is running.

### ✅ DMS Plugins

**Status**: Configured

The following plugins from the [DMS Plugin Registry](https://github.com/AvengeMedia/dms-plugin-registry) are enabled:

| Plugin | Description |
|--------|-------------|
| Media Player | Media controls widget |
| Docker Manager | Container management |
| Weather Widget | Dashboard weather forecasts |
| Command Runner | Quick shell command execution |
| Web Search | 23+ search engines |
| Emoji Launcher | 300+ emojis and unicode characters |
| System Resources | Enhanced system stats |

**Adding More Plugins**:
```bash
# Via CLI
dms plugins list
dms plugins install <plugin-name>

# Or via DMS Settings UI → Plugins
```

### ✅ Dank Greeter

**Status**: Enabled (replaces regreet)

**Location**: `modules/nixos/features/desktop/dms-greeter.nix`

**Configuration**:
```nix
programs.dank-material-shell.greeter = {
  enable = true;
  compositor.name = "niri";
  logs.save = true;
  logs.path = "/tmp/dms-greeter.log";
};
```

**Switching Back to ReGreet**:
If you need to switch back to the old regreet login screen:

```nix
# In hosts/jupiter/default.nix
host.features.desktop.greeter = "regreet"; # Default is "dms"
```

### ✅ dgop (Dank GOP)

**Status**: Provided by DMS (via `enableSystemMonitoring = true`)

**Package**: Included with DankMaterialShell

**Description**: System and process monitoring API & CLI for CPU, RAM, GPU metrics and temperatures.

**Usage**:
```bash
# CLI usage (available when DMS system monitoring is enabled)
dgop              # Show system stats
dgop cpu          # CPU monitoring
dgop memory       # Memory stats
dgop gpu          # GPU metrics
dgop process      # Process monitoring
```

**Note**: No separate installation needed - dgop is automatically provided by DMS when `enableSystemMonitoring = true`.

### ✅ danksearch (dsearch)

**Status**: Installed with home-manager module

**Package**: `github:AvengeMedia/danksearch`

**Description**: Blazingly fast indexed filesystem search in Go.

**Configuration**:
```nix
programs.dsearch = {
  enable = true;
};
```

**Usage**:
```bash
# Search for files
dsearch <query>

# Index files (if needed)
dsearch index

# Update index
dsearch update
```

### ❌ dcal (Dank Calendar)

**Status**: NOT AVAILABLE

**Reason**: Repository does not have a flake.nix yet - not flake-enabled.

**Alternative**: DMS calendar events use `khal` instead (already configured via `enableCalendarEvents = true`).

### ❌ Hyprland, Sway, labwc, MangoWC

**Status**: NOT ENABLED

**Reason**: Using Niri compositor exclusively as configured in your setup.

**Note**: DMS supports these compositors if you want to try different workflows. To enable Hyprland:
```nix
# In host config
host.features.desktop.hyprland = true;
```

## File Changes Summary

### New Files Created
- `modules/nixos/features/desktop/dms-greeter.nix` - DMS greeter configuration

### Modified Files
- `flake.nix` - Added danksearch flake input
- `lib/system-builders.nix` - Integrated danksearch module
- `modules/nixos/features/desktop/regreet.nix` - Added greeter selection option
- `modules/nixos/features/desktop/desktop-environment.nix` - Imported dms-greeter module
- `home/nixos/dank-material-shell.nix` - Added danksearch package, documentation
- `flake.lock` - Updated with new inputs

## Configuration Options

### Greeter Selection

Choose between regreet and DMS greeter:

```nix
# In hosts/jupiter/default.nix
host.features.desktop.greeter = "dms";     # DMS greeter (default)
host.features.desktop.greeter = "regreet"; # ReGreet greeter
```

### DMS Features

All DMS features are in `home/nixos/dank-material-shell.nix`:

```nix
programs.dank-material-shell = {
  enable = true;

  # Niri integration - All include modules enabled
  niri = {
    enableSpawn = true;
    includes = {
      enable = true;
      override = true;
      alttab = true;   # Window switching
      binds = true;    # Keybindings
      colors = true;   # Theme colors
      layout = true;   # Gaps, borders
      outputs = true;  # Monitor config
      wpblur = true;   # Wallpaper blur
    };
  };

  # Core feature toggles
  enableSystemMonitoring = true;
  enableVPN = true;
  enableDynamicTheming = true;
  enableAudioWavelength = true;
  enableCalendarEvents = true;
  enableClipboardPaste = true;

  # Desktop features configured via DMS Settings UI or CLI:
  # - Browser Picker: dms settings browser-picker
  # - Lock Screen: dms settings lock-screen
  # - Night Light: dms settings night-light
  # - Power Management: dms settings power

  # Plugins - enable via Nix or CLI
  plugins = {
    mediaPlayer.enable = true;
    dockerManager.enable = true;
    # See full list with: dms plugins list
  };
};
```

### Niri Keybinds Configuration

**Method Used: `includes` (Recommended)**

DMS generates config files in `~/.config/niri/dms/` after building:
- `binds.kdl` - All keybindings (window management, DMS features)
- `colors.kdl` - Material Design 3 colors
- `layout.kdl` - Gaps, window radius
- `alttab.kdl` - Alt-tab configuration

**Viewing Keybinds:**
```bash
# View all keybinds
cat ~/.config/niri/dms/binds.kdl

# Or use CLI
dms keybinds show niri

# Or DMS Settings UI → Keyboard Shortcuts
```

**Customizing Keybinds:**
1. **DMS Settings UI** - Graphical editor (searchable)
2. **CLI**: `dms keybinds set niri <key> <action>`
3. **Direct editing**: Edit `~/.config/niri/dms/binds.kdl`
4. **Override**: Add custom binds to `~/.config/niri/config.kdl`

**Why not `enableKeybinds`?**
- ❌ Static preset keybinds (less flexible)
- ❌ May conflict with `includes`
- ❌ Not recommended by DMS docs
- ✅ Use `includes` instead (generates readable config files)

## Applying Changes

To apply these changes, rebuild your system:

```bash
# Build and switch (requires user confirmation)
nh os switch

# Or manually
sudo nixos-rebuild switch --flake .#jupiter
```

## Troubleshooting

### Greeter Not Showing

Check greeter logs:
```bash
cat /tmp/dms-greeter.log
journalctl -u greetd
```

### DMS Not Starting

Check DMS logs:
```bash
dms logs
journalctl --user -u dms
```

### Search Not Working

Rebuild dsearch index:
```bash
dsearch index
```

## What's Already Working

These DMS features are **active** in your configuration:

**Core Features:**
✅ System monitoring (CPU, RAM, GPU, network, disk)
✅ VPN management widget
✅ Dynamic Material Design 3 theming from wallpaper
✅ Audio visualization
✅ Calendar events display
✅ Clipboard manager with history and persistence
✅ Application launcher (fuzzel-based)
✅ Dashboard with media/weather/system info
✅ Control center for quick settings

**Desktop Features:**
✅ Browser Picker - choose browser when opening URLs
✅ Lock Screen - with media controls
✅ Night Light - coordinates-based gamma control
✅ Power Management - idle/suspend with fullscreen inhibit

**Plugins:**
✅ Media Player widget
✅ Docker Manager
✅ Weather Widget
✅ Command Runner
✅ Web Search (23+ engines)
✅ Emoji Launcher
✅ System Resources monitor

**Niri Integration:**
✅ All include modules (alttab, binds, colors, layout, outputs, wpblur)
✅ Auto-start with Niri
✅ DMS settings override Niri defaults

## What's Been Replaced

The following standalone tools have been disabled in favor of DMS:

| Old | New (DMS) | Notes |
|-----|-----------|-------|
| wlsunset | Night Light | Configure via `dms settings night-light` |
| swaylock-effects | Lock Screen | Built-in with Material Design theming |
| swayidle | Power Management | Configure via `dms settings power` |
| streaming-mode script | Fullscreen inhibit | Automatic via DMS power management |

**Note**: DMS handles these features at runtime. If DMS is not running, these features won't be available.

## Tools

✅ **DMS Greeter** - Material Design 3 login screen
✅ **dgop CLI** - Standalone system monitoring tool
✅ **dsearch** - Fast filesystem search utility

## DMS CLI Suite

The `dms` command provides terminal tools for scripting and control:

```bash
# Browser picker - open URL with browser selection dialog
dms open <url>

# System diagnostics - check for missing dependencies
dms doctor

# Screenshots - integrated with shell UI
dms screenshot

# Color picker - on-screen color selection
dms color-picker

# Process manager - view and manage processes
dms process

# Lock screen
dms lock

# Power management
dms power inhibit on   # Disable auto-lock
dms power inhibit off  # Re-enable auto-lock

# Plugin management
dms plugins list
dms plugins install <name>
dms plugins remove <name>

# Keybinds
dms keybinds show niri
dms keybinds set niri <key> <action>

# Logs
dms logs
```

## Resources

- **Dank Linux Website**: https://danklinux.com/
- **DMS GitHub**: https://github.com/AvengeMedia/DankMaterialShell
- **dgop GitHub**: https://github.com/AvengeMedia/dgop
- **danksearch GitHub**: https://github.com/AvengeMedia/danksearch
- **DMS Plugin Registry**: https://github.com/AvengeMedia/dms-plugin-registry

## Future Additions

When these become flake-ready:
- **dcal** - Calendar application (currently using khal instead)
- Additional DMS plugins from the plugin registry
