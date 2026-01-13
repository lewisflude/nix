# TODO: Future Refactoring Tasks

This document tracks potential refactorings and improvements identified during code audits.

## High Priority

_No high priority items at this time._

---

## Medium Priority

### 2. Upstream Sonarr Data Path Fix

**Location:** `modules/nixos/services/media-management/sonarr.nix:38`

**Current Issue:**

```nix
serviceConfig.ExecStart = lib.mkForce "${config.services.sonarr.package}/bin/Sonarr -nobrowser -data=/var/lib/sonarr/.config/Sonarr";
```

Overriding NixOS module's ExecStart to use modern Sonarr directory instead of legacy NzbDrone path.

**Proposed Solutions:**

#### Option A: Upstream to nixpkgs**

- Submit PR to add `services.sonarr.dataPath` option
- Or update default path to use modern `.config/Sonarr` instead of `.config/NzbDrone`

#### Option B: Local module overlay**

```nix
# In overlays/sonarr-fix.nix
{ config, lib, ... }:
{
  # Properly override the module instead of using mkForce
}
```

#### Option C: Check if fixed in newer nixpkgs**

- Verify if nixpkgs 24.11 or unstable has fixed this
- Remove override if upstream is fixed

**Benefits:**

- Removes maintenance burden
- Helps entire Nix community
- Proper upstream solution vs local hack

---

### ~~Implement Missing Productivity Features~~ ✅

### 7. Re-enable Aseprite Package

**Location:** `home/nixos/desktop-apps.nix:11-13`

**Current Issue:**

```nix
# FIXME: aseprite is currently broken in nixpkgs (skia-aseprite build failure)
# Temporarily commented out until upstream fix is available
# asepriteFixed
```

Aseprite package is broken due to upstream skia-aseprite build failures.

**Proposed Solution:**

#### Option A: Wait for upstream fix**

- Monitor nixpkgs issues for aseprite fixes
- Re-enable when package is fixed upstream

#### Option B: Create temporary overlay**

```nix
# In overlays/aseprite-fix.nix
final: prev: {
  aseprite = prev.aseprite.overrideAttrs (old: {
    # Workaround for skia build issue
  });
}
```

#### Option C: Use alternative package**

- Consider `libresprite` as temporary alternative
- Or build from source with custom derivation

**Benefits:**

- Restores pixel art editor functionality
- No long-term maintenance if waiting for upstream

**Status:** ⏳ **Waiting on upstream nixpkgs fix**

---

## Low Priority (Already Justified)

### 9. Darwin Nix Daemon Management

**Location:** `modules/darwin/nix.nix:164`

```nix
nix = {
  # Determinate Nix owns the daemon + /etc/nix/nix.conf; keep nix-darwin out
  enable = lib.mkForce false;
};
```

**Status:** ✅ **No action needed**

This is the correct use of `mkForce`. Determinate Nix installation requires disabling nix-darwin's daemon management. Well-documented and justified.

---

## Additional Potential Improvements

### Future Considerations

- **Audit other `mkOverride` usage** - Similar patterns might exist
- **Create module interaction documentation** - Document which modules intentionally override each other
- **Establish priority guidelines** - When to use mkDefault/mkForce/mkOverride
- **Module dependency graph** - Use `nix run .#visualize-modules` to identify interaction patterns

---

---

## New Tasks (2026-01-12 Automated Analysis)

### ~~Implement Missing Productivity Features~~ ✅

**Completed:** 2026-01-13

**Location:** `home/common/features/productivity/default.nix`

**Solution Implemented:**

Implemented missing productivity features (email, calendar, resume) using home-manager modules where appropriate.

**Changes Made:**

1. **home/common/features/productivity/default.nix**:
   - Configured `programs.thunderbird` for email.
   - Verified `gnome-calendar` and `typst`/`tectonic` packages.

**Benefits Achieved:**

- Functional productivity features
- Proper Thunderbird configuration

---

### ~~Extract Hardcoded Network Ranges to Constants~~ ✅

**Completed:** 2026-01-13

**Locations:**

- `modules/nixos/features/home-server.nix:44`
- `modules/nixos/services/dante-proxy.nix:41,46`
- `modules/nixos/services/home-assistant.nix:194`
- `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix:42,123-124`

**Solution Implemented:**

Extracted network ranges to `lib/constants.nix` and updated all referencing modules to use the constants.

**Changes Made:**

1. **Updated** `lib/constants.nix`: Added `networks` section with `lan`, `vpn`, `localhost`, and `all` definitions. Added missing service ports.
2. **Updated** `modules/nixos/features/home-server.nix`: Replaced hardcoded IPs with `constants.networks`.
3. **Updated** `modules/nixos/services/dante-proxy.nix`: Replaced hardcoded IPs and ports with `constants`.
4. **Updated** `modules/nixos/services/home-assistant.nix`: Replaced hardcoded IPs and ports with `constants`.
5. **Updated** `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix`: Replaced hardcoded IPs, ports, and routes with `constants`.

**Benefits Achieved:**

- Single source of truth for network configuration
- Easier network topology changes
- Reduced magic values in codebase

---

### ~~Add Examples to Host Options~~ ✅

**Completed:** 2026-01-13

**Location:** `modules/shared/host-options/*.nix`

**Solution Implemented:**

Added `example` attributes to all non-trivial options in `modules/shared/host-options/features/*.nix`. Also fixed several pre-existing validation errors in the codebase that were discovered during verification.

**Changes Made:**

1. Updated 12 feature option files to include `example = true` or specific examples.
2. Fixed import error in `home/common/features/core/shell/default.nix`.
3. Fixed Niri keybinds import in `home/nixos/niri/default.nix`.
4. Fixed relative paths to `constants.nix` in `caddy/virtual-hosts/gaming.nix` and `vr/immersed.nix`.
5. Fixed relative path to `p10k.zsh` in `home/common/features/core/shell/environment.nix`.

**Benefits Achieved:**

- Improved documentation and IDE support.
- Fixed `nix flake check` failures.
- Cleaner codebase.

---

### ~~Remove or Document Deprecated brandGovernance Options~~ ✅

**Completed:** 2026-01-13

**Location:** `modules/shared/features/theming/options.nix`

**Solution Implemented:**

Removed the deprecated `overrides` option and replaced it with `mkRemovedOptionModule` to guide users to the new `brandGovernance.brandColors` API. Also removed internal checks for the deprecated option in warning messages.

**Changes Made:**

1. **modules/shared/features/theming/options.nix**: Replaced `overrides` option definition with `mkRemovedOptionModule`.
2. **home/common/theming/default.nix**: Removed warning check for `overrides`.
3. **modules/nixos/features/theming/default.nix**: Removed warning check for `overrides`.
4. **modules/shared/features/theming/tests/options.nix**: Removed tests for the deprecated option.

**Benefits Achieved:**

- Cleaner codebase (removed dead code)
- Clear migration path (build failure with helpful message if used)
- Standardized deprecation pattern

---

### ~~Audit Service Firewall Port Documentation~~ ✅

**Completed:** 2026-01-13

**Location:** `modules/nixos/services/*.nix` and `modules/nixos/services/containers-supplemental/services/*.nix`

**Solution Implemented:**

Audited all service modules for firewall port configuration. Added `openFirewall` options to all modules that open ports, allowing users to opt-out of automatic firewall configuration. Ensured ports are documented and use constants where available.

**Changes Made:**

1. **Media Management**: Added `openFirewall` options to Sonarr, Radarr, Lidarr, Readarr, Prowlarr, SABnzbd, Jellyseerr, Listenarr, Jellyfin, Unpackerr, Navidrome, FlareSolverr, qBittorrent, Transmission.
2. **Infrastructure**: Verified Dante, Cockpit, Mosh, Samba, Sunshine already had options or were correct. Updated Eternal Terminal to add `openFirewall` option.
3. **System**: Refactored `home-assistant.nix` to use standard option. Added `openFirewall` option to `music-assistant.nix` and `caddy/config.nix`.
4. **Containers**: Added `openFirewall` options to Homarr, Wizarr, Jellystat, Profilarr, Janitorr, Termix, Cleanuparr, Cal.com, and ComfyUI (container).

**Benefits Achieved:**

- Consistent configuration interface across all services
- Better security (ports explicit and optional)
- Improved documentation via `openFirewall` option descriptions
- Easier auditing of open ports

---

### ~~Create System-Level Test Infrastructure~~ ✅

**Completed:** 2026-01-13

**Location:** `tests/` directory

**Solution Implemented:**

Created a modular test infrastructure for feature-level system tests. Refactored `mkTestMachine` into a reusable helper and implemented feature tests for gaming and development. Integrated tests into `flake-parts` checks.

**Changes Made:**

1. **Created** `tests/lib/test-helpers.nix`: Extracted `mkTestMachine` logic for reuse.
2. **Updated** `tests/lib/vm-base.nix`: Added `nixpkgs.config.allowUnfree = true` to support unfree packages like Steam in tests.
3. **Created** `tests/features/gaming.nix`: Added comprehensive test for gaming feature (Steam, performance, gamemode).
4. **Created** `tests/features/development.nix`: Extracted development environment test.
5. **Updated** `tests/default.nix`: Refactored to use `test-helpers.nix` and import feature tests.
6. **Updated** `flake-parts/per-system/checks.nix`: Merged VM tests into flake checks.

**Benefits Achieved:**

- Modular test structure (`tests/features/*`)
- Reusable test helpers
- Comprehensive checks for gaming and development features
- Tests now run as part of `nix flake check`

---

### ~~Document Module Override Patterns~~ ✅

**Completed:** 2026-01-13

**Location:** `docs/reference/MODULE_OVERRIDES.md`

**Solution Implemented:**

Created comprehensive documentation explaining NixOS module priority system, including:

- Standard priority levels (40, 50, 100, 1000)
- Usage guidelines for `mkDefault`, `mkForce`, and `mkOverride`
- Common patterns used in this repository (feature flags, performance tuning, test VMs)
- Debugging tips using `nixos-option` and `nix repl`

**Benefits Achieved:**

- Better understanding of module system for contributors
- Clearer precedence rules and patterns
- Reduced risk of configuration conflicts

---

## Contributing

When working on these TODOs:

1. **Read existing code** - Understand why mkForce was used originally
2. **Test thoroughly** - Ensure refactoring doesn't break functionality
3. **Update this document** - Mark completed items, add new findings
4. **Follow conventions** - See `docs/CONVENTIONS.md` and `docs/DX_GUIDE.md`
5. **Consider upstreaming** - Some fixes benefit the entire Nix community

---

## Completed Items

### ~~VPN Interface MTU Configuration Template~~ ✅

**Completed:** 2026-01-13

**Locations:** `modules/nixos/core/networking.nix` and `docs/PROTONVPN_PORT_FORWARDING_SETUP.md`

**Solution Implemented:**

Removed the placeholder comment from `networking.nix` and moved the MTU optimization guide to the ProtonVPN documentation.

**Changes Made:**

1. **Updated** `modules/nixos/core/networking.nix`: Removed the TODO comment block.
2. **Updated** `docs/PROTONVPN_PORT_FORWARDING_SETUP.md`: Added "Optional: MTU Optimization" section with instructions.

**Benefits Achieved:**

- Cleaner codebase (removed stale TODO).
- Better documentation for users.
- Kept configuration optional as intended.

---

### ~~Document Desktop Session Management~~ ✅

**Completed:** 2026-01-13

**Location:** `modules/nixos/features/desktop/desktop-environment.nix`

**Solution Implemented:**

Documented the reasoning for using `lib.mkForce [ ]` in `services.displayManager.sessionPackages`.

**Changes Made:**

1. **Updated** `modules/nixos/features/desktop/desktop-environment.nix`:
   - Added clear comment explaining conflict between Niri's default session registration and UWSM's exclusive session management.

**Benefits Achieved:**

- Clearer intent for future maintainers.
- Justified use of `mkForce`.

---

### ~~Implement Missing Productivity Features~~ ✅

**Completed:** 2026-01-13

**Locations:** `modules/shared/features/productivity/default.nix` and `home/common/features/productivity/default.nix`

**Solution Implemented:**

Refactored `home/common/features/productivity/default.nix` to use `programs.thunderbird` for email instead of just installing the package, and confirmed other tools are installed via `home.packages`.

**Changes Made:**

1. **Updated** `home/common/features/productivity/default.nix`:
   - Used `programs.thunderbird` for email configuration
   - Kept `libreoffice-fresh`, `gnome-calendar`, `typst`, and `tectonic` as packages

**Benefits Achieved:**

- Proper home-manager integration for Thunderbird
- Clear implementation of productivity features
- Feature flags now fully functional

---

### ~~Make Gaming-Aware Sysctl Configuration~~ ✅

**Completed:** 2026-01-12

**Location:** `modules/nixos/features/gaming.nix:29` and `modules/nixos/system/disk-performance.nix:94`

**Solution Implemented:**

Implemented Option A - made disk-performance.nix gaming-aware by checking `config.host.features.gaming.enable` and conditionally setting `vm.max_map_count` to the appropriate value (2147483642 for gaming workloads, 262144 for conservative default workloads).

**Changes Made:**

1. `modules/nixos/system/disk-performance.nix:91-101` - Added conditional logic for gaming feature
2. `modules/nixos/features/gaming.nix:24-27` - Removed `mkForce` override

**Benefits Achieved:**

- Removed `mkForce` hack from gaming module
- Made module interaction explicit and self-documenting
- Single source of truth for `vm.max_map_count` configuration

---

### ~~Simplify SOPS Secret Permissions~~ ✅

**Completed:** 2026-01-12

**Solution Implemented:**

Added `lib.mkDefault` to the shared module's `mkSecret` function, allowing downstream modules to override without requiring `mkForce`. Removed redundant overrides from the NixOS-specific module.

---

### ~~Extract Delayed Boot Pattern into Reusable Module~~ ✅

**Completed:** 2026-01-12

**Location:** `hosts/jupiter/configuration.nix:135-144` (after refactoring)

**Solution Implemented:**

Created a reusable boot optimization module at `modules/nixos/features/boot-optimization.nix` that provides a generic pattern for delaying non-essential services to speed up boot.

**Changes Made:**

1. **Added options** in `modules/shared/host-options/features.nix:362-388`:
   - `host.features.bootOptimization.enable` - Enable boot optimization
   - `host.features.bootOptimization.delayedServices` - List of services to delay
   - `host.features.bootOptimization.delaySeconds` - Delay duration (default: 30s)

2. **Created module** at `modules/nixos/features/boot-optimization.nix`:
   - Clears `wantedBy` for delayed services using `mkForce`
   - Creates `delayed-services.service` to start services via systemd timer
   - Creates `delayed-services.timer` to trigger after boot

3. **Imported module** in `modules/nixos/default.nix:14`

4. **Updated jupiter host** in `hosts/jupiter/configuration.nix:137-144`:
   - Replaced manual systemd configuration with feature flags
   - Configured to delay `ollama` and `open-webui` services

**Benefits Achieved:**

- Reusable across any host that needs boot optimization
- Removed `mkForce` hacks from host-specific configuration
- Clear opt-in mechanism via feature flags
- Self-documenting with proper options descriptions
- Can be easily extended to other hosts (mercury, saturn, etc.)

---

### ~~Consolidate Test VM Configuration~~ ✅

**Completed:** 2026-01-12

**Location:** `tests/default.nix` and `tests/integration/mcp.nix`

**Solution Implemented:**

Created a reusable VM base configuration module at `tests/lib/vm-base.nix` that consolidates common test VM overrides, eliminating repetition across test files.

**Changes Made:**

1. **Created module** at `tests/lib/vm-base.nix`:
   - Disables bootloaders (GRUB and systemd-boot)
   - Configures simple root filesystem on `/dev/vda`
   - Disables graphics and X server for faster testing
   - Well-documented with clear comments explaining each override

2. **Updated mkTestMachine helper** in `tests/default.nix:14-26`:
   - Added import of `./lib/vm-base.nix`
   - Removed redundant boot loader configuration (previous lines 19-24)
   - Removed redundant X server and graphics overrides (previous lines 33-34)
   - Reduced configuration from 15 lines to 12 lines

3. **Updated MCP test** in `tests/integration/mcp.nix:19-47`:
   - Added import of `../lib/vm-base.nix`
   - Removed redundant boot, filesystem, and graphics configuration (previous lines 45-51)
   - Reduced from 7 lines of VM config to just the import

**Benefits Achieved:**

- DRY principle applied - common configuration defined once
- Consistent test environment across all tests
- Easier to maintain test infrastructure
- Changes to VM base config now apply to all tests automatically
- Reduced code duplication by approximately 20 lines
- Future test files can simply import vm-base.nix

---

### ~~Connect GPG to Security Feature Flag~~ ✅

**Completed:** 2026-01-13

**Location:** `modules/shared/features/security/default.nix`

**Solution Implemented:**

Updated `modules/shared/features/security/default.nix` to conditionally import the home-manager GPG module (`home/common/features/core/gpg.nix`) when `host.features.security.gpg` is enabled.

**Changes Made:**

1. **Updated module** `modules/shared/features/security/default.nix`:
   - Added `home-manager.users.${config.host.username}` block inside `mkMerge`
   - Configured conditional import of `../../../../home/common/features/core/gpg.nix` when `cfg.gpg` is true
   - Verified that `home-manager` option is available in this context

**Benefits Achieved:**

- Connected `host.features.security.gpg` flag to actual implementation
- Made GPG support properly opt-in via feature flag
- Leveraged existing home-manager module structure
- Maintained separation of concerns (system flag triggers user config)

---

### ~~Add Validation Assertions to Features~~ ✅

**Completed:** 2026-01-13

**Locations:**

- `modules/nixos/features/home-server.nix`
- `modules/nixos/features/gaming.nix`
- `modules/nixos/features/desktop/audio.nix`
- `modules/nixos/features/vr/default.nix`
- `modules/nixos/features/security.nix`
- `modules/nixos/features/media-management.nix`
- `modules/nixos/features/ai-tools.nix`

**Solution Implemented:**

Added `assertions` blocks to feature modules to validate dependencies, security requirements, and configuration completeness. Ensured assertions are placed correctly (outside `mkIf cfg.enable` where appropriate) to catch configuration errors even when the main feature is disabled but sub-features are enabled.

**Changes Made:**

1. **home-server.nix**: Added checks for dependencies (fileSharing -> firewall, homeAssistant -> enable) and security (backups -> restic-password existence).
2. **gaming.nix**: Moved `emulators -> enable` assertion outside `mkIf` block to ensure it triggers correctly.
3. **audio.nix**: Moved `noiseCancellation` and `echoCancellation` assertions outside `mkIf` block.
4. **vr/default.nix**: Added assertions to ensure sub-features (SteamVR, WiVRn, ALVR, Immersed, Virtual Monitors) require the main VR feature to be enabled.
5. **security.nix**: Added assertions to ensure `yubikey` and `gpg` sub-features require the main `security` feature to be enabled.
6. **media-management.nix**: Added assertions for all media services (Sonarr, Radarr, Jellyfin, etc.) to require the `mediaManagement` feature to be enabled.
7. **ai-tools.nix**: Added assertions for `ollama` and `openWebui` to require `aiTools` feature. Added validation that `ollama.acceleration = "cuda"` requires `hardware.graphics.enable`.

**Benefits Achieved:**

- Fail-fast error messages at build time
- Prevents invalid configurations
- Self-documenting dependencies

---

### ~~Implement System Theme Detection~~ ✅

**Completed:** 2026-01-13

**Location:** `modules/shared/features/theming/mode.nix` and `home/common/theming/default.nix`

**Solution Implemented:**

Implemented multi-source theme detection using a systemd user service that checks `gsettings` and caches the result. The `detectSystemMode` function now reads from this cache.

**Changes Made:**

1. **modules/shared/features/theming/mode.nix**: Updated `detectSystemMode` to read from XDG cache.
2. **home/common/theming/default.nix**: Added `detect-theme-mode` systemd service.

**Benefits Achieved:**

- Respects user's system theme preference
- Automatic synchronization with desktop environment
- Fallback to sensible default (dark mode)
