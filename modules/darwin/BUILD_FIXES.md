# nix-darwin Build Fixes

## Summary
Successfully fixed all build errors in the new nix-darwin configuration modules. The configuration now builds without errors.

## Issues Fixed

### 1. ✅ Invalid `documentation.man.generateCaches` Option
**File**: `documentation.nix`
**Issue**: `generateCaches` is not a valid option for `documentation.man` in nix-darwin
**Fix**: Changed from nested structure to flat `man.enable = true`

### 2. ✅ Invalid Software Update Settings
**File**: `security-preferences.nix`
**Issue**: `system.defaults.SoftwareUpdate.*` options don't exist in nix-darwin
**Fix**: Removed these settings with a note that they must be configured manually in System Preferences

### 3. ✅ Deprecated Firewall Settings
**File**: `security-preferences.nix`
**Issue**: `system.defaults.alf.*` options have been moved to `networking.applicationFirewall.*`
**Fix**: Updated to use the new networking.applicationFirewall interface:
- `alf.globalstate` → `networking.applicationFirewall.enable`
- `alf.allowsignedenabled` → `networking.applicationFirewall.allowSigned`
- `alf.allowdownloadsignedenabled` → `networking.applicationFirewall.allowSignedApp`
- `alf.stealthenabled` → `networking.applicationFirewall.enableStealthMode`

### 4. ✅ Garbage Collection Conflict
**File**: `nix.nix`
**Issue**: `nix.gc.automatic` requires `nix.enable = true`, but your config has `nix.enable = false`
**Fix**: Disabled automatic GC with `lib.mkIf false` and added a comment explaining manual GC options

### 5. ✅ Invalid Control Center Options
**File**: `system.nix`
**Issue**: `BatteryShowPercentage` and `Bluetooth` are not valid `controlcenter` options
**Fix**: Removed invalid options, kept only `NowPlaying` and `Sound`

## Build Status
✅ **Configuration builds successfully**

```bash
# Build succeeded with:
darwin-rebuild build --flake .
```

## Next Steps

To apply these changes to your system:

```bash
# Apply the configuration (requires sudo)
darwin-rebuild switch --flake .

# Note: Some settings may require logout/login to take effect
```

## Notes
- The warnings about FlakeHub authentication are harmless - it's an optional cache
- Since `nix.enable = false`, nix-darwin doesn't manage the Nix daemon
- Manual garbage collection can be run with: `nix-collect-garbage --delete-older-than 7d`
- Some macOS settings (like Software Update preferences) must be configured manually
