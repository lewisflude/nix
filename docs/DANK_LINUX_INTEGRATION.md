# Dank Linux Feature Integration

This document describes the Dank Linux ecosystem features integrated into this NixOS configuration.

## Overview

The configuration now includes all available Dank Linux components from the danklinux.com ecosystem, providing a complete Material Design 3 desktop experience on Niri.

## Integrated Components

### ✅ DankMaterialShell (DMS)

**Status**: Fully Configured

**Location**: `home/nixos/dank-material-shell.nix`

**Features Enabled**:
- System monitoring widgets (via dgop backend)
- VPN management widget
- Dynamic theming (wallpaper-based Material Design 3)
- Audio visualization
- Calendar events integration
- Clipboard paste support

**Built-in Components** (no separate packages needed):
- **Dank Dash**: Dashboard with media controls, weather, calendar, system info
- **Launcher**: Application launcher with filesystem search (fuzzel-based)
- **Control Center**: System settings and quick toggle interface

These are integral parts of DMS and activate automatically when DMS is running.

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

  # Niri integration - Use includes (recommended over enableKeybinds)
  niri = {
    enableSpawn = true;
    includes = {
      enable = true;      # Generate DMS config files (recommended)
      override = true;    # DMS settings take precedence
    };
  };

  # Feature toggles
  enableSystemMonitoring = true;   # dgop-powered widgets
  enableVPN = true;                 # VPN management
  enableDynamicTheming = true;      # Material Design 3 theming
  enableAudioWavelength = true;     # Audio visualization
  enableCalendarEvents = true;      # Calendar via khal
  enableClipboardPaste = true;      # Clipboard support
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

These DMS features are **already active** in your configuration:

✅ System monitoring (CPU, RAM, GPU, network, disk)
✅ VPN management widget
✅ Dynamic Material Design 3 theming from wallpaper
✅ Audio visualization
✅ Calendar events display
✅ Clipboard paste functionality
✅ Application launcher (fuzzel-based)
✅ Dashboard with media/weather/system info
✅ Control center for quick settings

## What's New

✅ **DMS Greeter** - Material Design 3 login screen
✅ **dgop CLI** - Standalone system monitoring tool
✅ **dsearch** - Fast filesystem search utility

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
