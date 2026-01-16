# Niri Keybinds Organization

This directory organizes keybinds by functional category for maintainability and discoverability.

## Directory Structure

```
keybinds/
├── default.nix              # Entry point - merges all keybind modules
├── README.md               # This file
├── launchers.nix           # Application shortcuts (Mod+T, Mod+D, Mod+B, etc.)
├── window-management.nix   # Window operations (close, maximize, fullscreen, floating)
├── window-navigation.nix   # Focus and move windows within columns (J/K, Up/Down)
├── column-layout.nix       # Column width/height and manipulation (R, +/-, brackets)
├── workspace.nix           # Workspace navigation and movement (U/I, Page Up/Down)
├── monitor.nix             # Multi-monitor navigation and column movement
├── screenshots.nix         # Screenshot capture with various modifiers
├── media.nix               # Audio controls, brightness, media playback
├── system.nix              # Power management, notifications, system actions
└── mouse.nix               # Mouse/wheel bindings ("tape scrolling")
```

## Core Categories

### launchers.nix
Application shortcuts and quick launchers:
- `Mod+T` - Terminal (Ghostty)
- `Mod+D` - Launcher (Fuzzel)
- `Mod+B` - Browser (Chromium)
- `Mod+E` - File manager (Yazi in terminal)
- `Mod+M` - Email (Thunderbird)
- `Mod+V` - Clipboard history
- `F13` - Terminal (programmable keyboard shortcut)

### window-management.nix
Window state and operations:
- `Mod+Q` - Close window
- `Mod+Shift+Q` - Force kill window
- `Mod+Grave` - Toggle floating
- `Mod+F` - Maximize column
- `Mod+Shift+F` - Fullscreen window
- `Mod+Ctrl+F` - Expand column to available width

### window-navigation.nix
Focus and move windows within columns:
- `Mod+J/K` or `Mod+Down/Up` - Focus window down/up
- `Mod+Ctrl+J/K` - Move window down/up within column

### column-layout.nix
Column width/height and manipulation:
- `Mod+R` - Cycle preset column widths
- `Mod+Shift+R` - Cycle preset window heights
- `Mod+Minus/Equal` - Decrease/increase column width
- `Mod+C` - Center column
- `Mod+H/L` or `Mod+Left/Right` - Focus column left/right
- `Mod+Ctrl+H/L` - Move column left/right
- `Mod+W` - Toggle tabbed display
- `Mod+Comma/Period` - Consume/expel window into/from column

### workspace.nix
Workspace navigation and management (dynamic workspaces):
- `Mod+U/I` or `Mod+Page_Up/Down` - Focus workspace up/down
- `Mod+Ctrl+U/I` - Move column to workspace up/down
- `Mod+Shift+U/I` - Move workspace position up/down
- `Mod+O` - Toggle overview
- `Alt+Tab` - Focus window or workspace down

### monitor.nix
Multi-monitor navigation:
- `Mod+Shift+H/J/K/L` - Focus monitor in direction
- `Mod+Shift+Ctrl+H/J/K/L` - Move column to monitor
- `Mod+Alt+O` - Show output info

### screenshots.nix
Screenshot capture with annotation support:
- `Print` - Full screen (save + copy)
- `Shift+Print` - Area with satty annotation
- `Ctrl+Print` - Full screen with satty annotation
- `Alt+Print` - Area to clipboard only
- `Mod+Shift+S` - Region capture (Windows/macOS style)
- `Mod+Shift+C` - Color picker

### media.nix
Audio controls, brightness, and media playback:
- `XF86AudioPlay/Next/Prev` - Media controls
- `XF86MonBrightnessUp/Down` - Brightness adjustment
- `XF86AudioRaiseVolume/LowerVolume` - Volume control
- `XF86AudioMute` - Toggle mute
- `Mod+Alt+V` - Audio mixer GUI (pwvucontrol)
- `Mod+Ctrl+V` - Audio mixer TUI (pulsemixer)

### system.nix
Power management, notifications, and system actions:
- `Mod+Shift+Slash` - Show hotkey overlay
- `Super+Alt+L` - Lock screen
- `Mod+Shift+P` - Power off monitors
- `Mod+Shift+D` - Toggle displays (off/on)
- `Mod+X` - Power menu (logout/suspend/hibernate/reboot/shutdown)
- `Mod+N` - Dismiss notification
- `Mod+Shift+N` - Dismiss all notifications
- `Mod+Ctrl+Shift+R` - Reload niri config

### mouse.nix
Mouse and wheel bindings ("tape scrolling" metaphor):
- `Mod+WheelUp/Down` - Focus column left/right
- `Mod+Ctrl+WheelUp/Down` - Move column left/right
- `Mod+Shift+WheelUp/Down` - Focus workspace up/down

## Keybind Patterns

### Modifier Hierarchy

Niri uses a consistent modifier hierarchy for related actions:

- **Mod** (Super) - Base action (focus/show)
- **Mod+Ctrl** - Move/modify action (move instead of focus)
- **Mod+Shift** - Secondary action or move workspace
- **Mod+Ctrl+Shift** - Move to different workspace/monitor

### Directional Keys

Multiple input methods for different preferences:

- **H/J/K/L** - Vim-style navigation (left/down/up/right)
- **Left/Down/Up/Right** - Arrow key navigation
- **U/I** - Workspace up/down (positioned above J/K on keyboard)

### Function Keys

Programmable keyboard shortcuts:

- **F13** - Terminal (custom keyboard mapping)
- **F16** - Maximize column
- **F17/F19** - Set column to 50% width
- **F18** - Center column

## Adding New Keybinds

1. **Determine the functional category** - Choose the appropriate file
2. **Add to the file** - Follow existing patterns for consistency
3. **Use helpers when possible** - Shell commands, launchers, etc.
4. **Follow modifier hierarchy** - Mod for base, Ctrl for move, etc.
5. **Document complex bindings** - Add inline comments for shell scripts

## Helper Libraries

The keybinds use helper libraries from `../lib/`:

### shell-commands.nix
Provides reusable shell command builders:
- `cmd.screenshot.*` - Screenshot operations
- `cmd.window.*` - Window management commands
- `cmd.system.*` - System control commands
- `cmd.monitor.*` - Monitor information commands

### Usage Example
```nix
let
  cmd = import ../lib/shell-commands.nix { inherit pkgs lib; };
in
{
  "Print".action.spawn = cmd.screenshot.fullScreenCopy;
}
```

### Launcher Helpers (launchers.nix)
Provides helpers for application launching:
- `uwsmApp` - Launch GUI app via uwsm
- `termWith` - Launch terminal with command
- `termWithArgs` - Launch terminal with multiple arguments

## Implementation Notes

- **No breaking changes** - All existing keybinds are preserved
- **Modular structure** - Easy to add/remove/modify categories
- **Reduced duplication** - Shell commands and launchers use helpers
- **Self-documenting** - Clear naming and organization
- **Consistent patterns** - Follow established conventions

## References

- Niri documentation: https://github.com/YaLTeR/niri/wiki
- Window rules: `../window-rules.nix`
- Animation config: `../animations.nix`
- Layout config: `../layout.nix`
