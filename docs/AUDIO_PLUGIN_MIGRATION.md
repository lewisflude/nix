# Audio Plugin Migration Guide

This guide covers migrating VSTs, Audio Units, and other audio plugins from one Mac to another.

## Overview

Audio plugins on macOS are stored in several locations:

1. **Plugin binaries** - The actual plugin files (.vst, .component, .vst3)
2. **Plugin presets and settings** - User-created presets and configurations
3. **Plugin licenses** - License files and activation data
4. **Sample libraries** - Large sample libraries (e.g., Superior Drummer, Kontakt libraries)

## Plugin Locations

### System-Wide Plugins (All Users)

**Standard Locations:**

- **VST**: `/Library/Audio/Plug-Ins/VST/`
- **VST3**: `/Library/Audio/Plug-Ins/VST3/`
- **Audio Units**: `/Library/Audio/Plug-Ins/Components/`
- **AAX (Pro Tools)**: `/Library/Application Support/Avid/Audio/Plug-Ins/`

**Additional Locations (Less Common):**

- `/usr/local/lib/vst/` - Unix-style VST installations
- `/usr/local/lib/vst3/` - Unix-style VST3 installations
- `/opt/local/lib/vst/` - MacPorts VST installations
- `/opt/local/lib/vst3/` - MacPorts VST3 installations

### User-Specific Plugins

- **VST**: `~/Library/Audio/Plug-Ins/VST/`
- **VST3**: `~/Library/Audio/Plug-Ins/VST3/`
- **Audio Units**: `~/Library/Audio/Plug-Ins/Components/`

### Plugin Data & Presets

Most plugins store their data in `~/Library/Application Support/`:

- **FabFilter**: `~/Library/Application Support/FabFilter/`
- **Toontrack**: `~/Library/Application Support/Toontrack/`
- **Native Instruments**: `~/Library/Application Support/Native Instruments/`
- **iZotope**: `~/Library/Application Support/iZotope/`
- **Waves**: `~/Library/Application Support/Waves/`
- **Plugin Alliance**: `~/Library/Application Support/Plugin Alliance/`
- **Universal Audio**: `~/Library/Application Support/Universal Audio/`
- **Sonarworks**: `~/Library/Application Support/Sonarworks/`

### Sample Libraries

Sample libraries are often stored in:

- `~/Library/Audio/Sounds/`
- `~/Music/` (vendor-specific folders)
- External drives (check your DAW's sample library paths)

### License Files

License locations vary by vendor:

- **iLok**: `~/Library/Preferences/com.paceap.eden.iLokLicenseManager.plist`
- **Native Instruments**: `~/Library/Preferences/com.native-instruments.*`
- **Waves**: `~/Library/Preferences/com.WavesAudio.*`
- **Plugin Alliance**: `~/Library/Preferences/com.plugin-alliance.*`

## Migration Methods

### Method 1: Manual Migration (Recommended)

1. **Identify all plugin locations** on your source Mac
2. **Copy plugin binaries** from both system and user locations
3. **Copy plugin data** from `~/Library/Application Support/`
4. **Copy license files** from `~/Library/Preferences/`
5. **Re-authorize plugins** on the new Mac (many require re-activation)

### Method 2: Using Migration Script

Use the provided `scripts/migrate-audio-plugins.sh` script (see below).

### Method 3: Time Machine / Migration Assistant

macOS Migration Assistant can transfer user data, but may miss:

- System-wide plugins in `/Library/Audio/Plug-Ins/`
- Some license files
- Large sample libraries on external drives

## Important Notes

### Re-Activation Required

Most commercial plugins require re-activation on the new Mac:

- **iLok**: Transfer licenses via iLok License Manager
- **Native Instruments**: Re-authorize via Native Access
- **Waves**: Re-authorize via Waves Central
- **Plugin Alliance**: Re-authorize via Plugin Alliance installer
- **Universal Audio**: Re-authorize via UA Connect

### Plugin Managers

Many vendors use plugin managers that handle installation:

- **Native Access** (Native Instruments)
- **Waves Central** (Waves)
- **Plugin Alliance Installer** (Plugin Alliance)
- **UA Connect** (Universal Audio)
- **iLok License Manager** (PACE/iLok)

### DAW-Specific Considerations

- **Logic Pro**: Scans `/Library/Audio/Plug-Ins/Components/` and `~/Library/Audio/Plug-Ins/Components/`
- **Ableton Live**: Scans VST, VST3, and AU locations
- **Pro Tools**: Primarily uses AAX plugins in `/Library/Application Support/Avid/Audio/Plug-Ins/`
- **Reaper**: Scans all standard plugin locations

## Verification Checklist

After migration:

- [ ] All plugin binaries copied
- [ ] Plugin presets and settings transferred
- [ ] Sample libraries accessible
- [ ] Licenses transferred/re-activated
- [ ] DAW recognizes all plugins
- [ ] Plugins load without errors
- [ ] Presets load correctly

## Additional Plugin Locations

Some plugins may be installed in non-standard locations:

- **Custom DAW folders**: Some DAWs allow custom plugin search paths
- **External drives**: Sample libraries and some plugins may be on external drives
- **Homebrew/MacPorts**: Plugins installed via package managers may be in `/usr/local/` or `/opt/`
- **Custom installations**: Some vendors install plugins in custom locations

If you have plugins in custom locations, you may need to manually copy them or add the paths to your DAW's plugin search directories.

## Troubleshooting

### Plugins Not Showing in DAW

1. **Rescan plugins** in your DAW's preferences
2. **Check plugin format compatibility** (VST2 vs VST3 vs AU)
3. **Verify plugin locations** are in standard paths
4. **Check file permissions** (plugins should be executable)

### Missing Presets

1. **Verify Application Support folders** were copied
2. **Check DAW preset locations** (some DAWs store presets separately)
3. **Re-import presets** if needed

### License Issues

1. **Use vendor's plugin manager** to re-authorize
2. **Transfer iLok licenses** if applicable
3. **Deactivate on old Mac** if license allows only one machine
4. **Contact vendor support** if activation fails
