# nix-darwin System Preferences Implementation

## Summary
All recommended nix-darwin system preferences have been implemented following best practices and your existing folder structure.

## New Modules Created

### 1. `system-preferences.nix`
- **Window behavior**: Faster animations, Linux-style window dragging
- **Save/Print panels**: Auto-expand for better UX
- **Document handling**: Save to disk by default (not iCloud)
- **UI improvements**: Always show scrollbars, jump-to-click
- **Dark mode**: Automatic switching
- **Text input**: Key repeat enabled, control characters visible
- **Regional settings**: 24-hour clock, metric system
- **Activity Monitor**: Show all processes, CPU usage sorting
- **Terminal & TextEdit**: Security and plain text defaults

### 2. `dock-preferences.nix`
- **Auto-hide**: Enabled with no delay and faster animation
- **Hot corners**: Configured for productivity
  - Bottom left: Show Desktop
  - Bottom right: Mission Control
  - Top left: Launchpad
  - Top right: Notification Center
- **App management**: Hide recent apps, show indicators
- **Mission Control**: Don't rearrange spaces, group by app
- **Visual**: Icon magnification enabled (80px on hover)
- **Animations**: Faster and using scale effect

### 3. `finder-preferences.nix`
- **File display**: Always show extensions, status bar, path bar
- **Organization**: Folders first in sorting
- **Search**: Default to current folder
- **Trash**: Auto-empty after 30 days
- **View**: List view by default with POSIX paths
- **Desktop**: Show all drive types
- **Spotlight**: Optimized for apps and documents

### 4. `documentation.nix`
- **Man pages**: Enabled with index caching
- **Info pages**: GNU info documentation enabled
- **Doc files**: Package documentation in /share/doc
- **Darwin config**: Set to ~/.config/nix

### 5. `security-preferences.nix`
- **Firewall**: Enabled with signed app allowance
- **Software Updates**: Manual control, auto-check enabled
- **Login window**: Guest account disabled, no auto-login
- **Safari**: Do Not Track, fraud warnings, developer tools
- **Privacy**: Personalized ads disabled

## Updated Modules

### `nix.nix`
- **Performance**: Auto-optimize store, use all CPU cores
- **Caching**: Added nix-community cache
- **Build settings**: Keep outputs and derivations for better rebuilds

### `system.nix`
- **Cleaned up**: Removed duplicate settings now in dedicated modules
- **Control Center**: Added battery percentage and Bluetooth
- **Screenshot**: Enhanced settings with thumbnails

### `backup.nix`
- **Time Machine**: Expanded exclusion list for development directories
- **Removed duplicates**: DoNotOfferNewDisksForBackup moved to system.nix

### `default.nix`
- **Organized imports**: Grouped by category with comments
- **All new modules**: Properly imported in logical order

## Features & Options

All modules use feature flags for easy enable/disable:
- `host.features.systemPreferences.enable`
- `host.features.dockPreferences.enable`
- `host.features.finderPreferences.enable`
- `host.features.documentation.enable`
- `host.features.securityPreferences.enable`

All are enabled by default but can be disabled if needed.

## To Apply Changes

```bash
# Test the configuration
darwin-rebuild check

# Apply the changes
darwin-rebuild switch

# Some settings may require logout/login to fully apply
```

## Rollback

If needed, you can rollback using:
```bash
darwin-rebuild switch --rollback
```

## Notes
- All settings follow nix-darwin best practices
- Modular design allows easy customization
- Feature flags provide granular control
- No breaking changes to existing configuration
- All linting checks passed successfully
