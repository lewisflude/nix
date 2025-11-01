# Manual Code Replacement Opportunities

This document identifies manual code implementations that could potentially be replaced by native or third-party Nix/NixOS/nix-darwin/Home Manager packages or modules.

## Summary

After reviewing the codebase, most services are already using native NixOS modules correctly. However, there are a few areas where custom implementations could potentially be replaced:

1. **GNOME Keyring systemd services** (Medium Priority)
2. **Cursor package** (Low Priority - may be justified)
3. **Cockpit Podman extension** (Low Priority - may be justified)
4. **Home Assistant custom component (home-llm)** (Low Priority - may be justified)

## Detailed Analysis

### 1. GNOME Keyring Systemd Services ✅ **FIXED**

**Location**: `modules/nixos/core/security.nix` (lines 55-88)

**Previous Implementation**:

- Custom `systemd.user.services.gnome-keyring-daemon` service
- Custom `systemd.user.services.unlock-login-keyring` service
- Manual configuration for auto-unlocking the keyring

**Replacement Applied**:

- ✅ **Migrated to Home Manager's `services.gnome-keyring` module**
- Added `home/nixos/system/gnome-keyring.nix` with Home Manager configuration
- Removed custom `gnome-keyring-daemon` systemd service (now handled by Home Manager)
- Kept `unlock-login-keyring` service as it's specific to auto-login scenarios and complements Home Manager's module

**Changes Made**:

1. Created `home/nixos/system/gnome-keyring.nix` with Home Manager's gnome-keyring service
2. Updated `home/nixos/system/default.nix` to import the new module
3. Removed custom `gnome-keyring-daemon` service from `modules/nixos/core/security.nix`
4. Updated `unlock-login-keyring` service to depend on Home Manager's service

**Status**: ✅ **Complete** - Now using Home Manager's native module

---

### 2. Cursor Package 📦 **JUSTIFIED - KEEP**

**Location**: `pkgs/cursor/` (Linux and Darwin packages)

**Current Implementation**:

- Custom AppImage wrapping for Linux
- Custom DMG extraction for Darwin
- Manual desktop entry creation
- Runtime library dependencies

**Potential Replacement**:

- ✅ **Verified**: `cursor` package does NOT exist in nixpkgs
- Only cursor themes exist in nixpkgs (catppuccin-cursors, rose-pine-cursor)
- Not found in standard nixpkgs search

**Recommendation**:

- ✅ **Keep custom implementation** - No alternative exists in nixpkgs
- Consider checking NUR if you want to explore community alternatives
- Your implementation is well-structured and maintainable

**Action**: ✅ Verified - Keep custom implementation

---

### 3. Cockpit Podman Extension 📦 **JUSTIFIED - KEEP**

**Location**: `pkgs/cockpit-extensions/podman-containers.nix`

**Current Implementation**:

- Custom package derivation for cockpit-podman extension
- Manual fetchzip and build configuration

**Potential Replacement**:

- ✅ **Verified**: `cockpit-podman` package does NOT exist in nixpkgs
- No search results found in nixpkgs

**Recommendation**:

- ✅ **Keep custom implementation** - No alternative exists in nixpkgs
- Your implementation is clean and follows standard Nix packaging practices

**Action**: ✅ Verified - Keep custom implementation

---

### 4. Home Assistant Custom Component (home-llm) 📦 **JUSTIFIED - KEEP**

**Location**: `modules/nixos/services/home-assistant/custom-components/home-llm.nix`

**Current Implementation**:

- Custom build using `buildHomeAssistantComponent`
- Workaround for ninja build issue
- Manual dependency management

**Potential Replacement**:

- ✅ **Verified**: `home-llm` does NOT exist in nixpkgs
- `home-assistant-custom-components` namespace exists in nixpkgs with many other components
- But `home-llm` specifically is not available

**Recommendation**:

- ✅ **Keep custom implementation** - No alternative exists in nixpkgs
- Your workaround for the ninja build issue is necessary
- Consider contributing to nixpkgs if you want to share this with the community

**Action**: ✅ Verified - Keep custom implementation

---

## Already Using Native Modules ✅

These services are correctly using native NixOS modules:

- ✅ **Samba** (`services.samba`, `services.samba-wsdd`, `services.avahi`) - Using native modules
- ✅ **SSH** (`services.openssh`) - Using native modules
- ✅ **Cockpit** (`services.cockpit`) - Using native modules
- ✅ **Music Assistant** (`services.music-assistant`) - Using native modules
- ✅ **Media Management** (Sonarr, Radarr, Prowlarr, etc.) - Using native modules
- ✅ **Home Assistant** (`services.home-assistant`) - Using native modules with custom components

---

## Overlays Status ✅

These overlays are legitimate fixes/workarounds and should be kept:

- ✅ **mpd-fix.nix** - Fixes io_uring build issue (necessary workaround)
- ✅ **pamixer.nix** - Fixes ICU C++17 compilation issue (necessary workaround)
- ✅ **webkitgtk-compat.nix** - Compatibility alias for removed package (necessary workaround)

---

## Additional Notes

### qBittorrent VPN Configuration

The qBittorrent module has complex VPN and proxy configuration. While some parts could potentially be simplified, the custom implementation appears necessary for the specific use case (VPN confinement + proxy services).

### Container Services

Container-based services (Homarr, Wizarr, Doplarr, etc.) are intentionally kept as containers because they don't have native NixOS modules yet. This is documented and intentional.

---

## Action Items

1. ✅ **GNOME Keyring services** - Migrated to Home Manager's module - **COMPLETE**
2. ✅ **Cursor package** - Verified not in nixpkgs - Keep custom implementation
3. ✅ **Cockpit Podman extension** - Verified not in nixpkgs - Keep custom implementation
4. ✅ **Home Assistant home-llm component** - Verified not in nixpkgs - Keep custom implementation

---

## Verification Results

✅ **Completed verification**:

- `cursor` - NOT in nixpkgs (only themes exist)
- `cockpit-podman` - NOT in nixpkgs
- `home-llm` - NOT in nixpkgs (other custom components exist)

✅ **Completed migration**:

- GNOME Keyring daemon service - Now using Home Manager's `services.gnome-keyring` module

---

## Conclusion

**Status**: ✅ **All issues addressed**

**Completed Actions**:

- ✅ **GNOME Keyring** - Successfully migrated to Home Manager's native module
- ✅ **Custom packages** - All verified as necessary and well-implemented

**Final Recommendation**:

- ✅ Configuration now uses Home Manager's native gnome-keyring module
- ✅ Custom packages (Cursor, Cockpit Podman, home-llm) remain as they're not available in nixpkgs
- ✅ Auto-unlock service kept as it's specific to auto-login scenarios
