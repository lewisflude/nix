# Gaming & VR Configuration Issues - Analysis Report

**Date**: 2026-01-11
**Analysis Target**: `docs/GAMING_VR_STREAMING_OPTIMIZATION_2026.md`
**Analyzer**: Claude Sonnet 4.5
**Status**: In Progress - Issues #1, #3 Completed (2026-01-11)
**Last Updated**: 2026-01-11

---

## Recent Implementations

### Issue #1: Gaming Environment Variables Placement (COMPLETED - 2026-01-11)

**Implementation Summary:**

Successfully moved gaming environment variables from system-level to user-level (home-manager), following NixOS best practices and project architectural guidelines.

**Changes Made:**

1. **Moved to `home/nixos/apps/gaming.nix`**:
   - Added `home.sessionVariables` with gaming-specific environment variables:
     - `PROTON_ENABLE_NVAPI = "1"` - NVIDIA API for game compatibility
     - `PROTON_HIDE_NVIDIA_GPU = "0"` - Don't hide GPU from games
     - `QT_QPA_PLATFORM = "wayland"` - Force Wayland for Qt games
   - Used `osConfig` pattern to conditionally enable when gaming feature is active
   - Follows same pattern as `vr.nix` for consistency

2. **Removed from `modules/nixos/features/gaming.nix`**:
   - Deleted `environment.sessionVariables` block
   - Added comment explaining rationale for move
   - Maintains system-level features (hardware, services) while moving user preferences

**Benefits:**

- ✅ Per-user configuration - doesn't affect non-gaming users
- ✅ Follows separation of concerns (system vs user)
- ✅ Aligns with NixOS/Home Manager best practices
- ✅ Consistent with project's CLAUDE.md architectural guidelines
- ✅ Users can override variables individually if needed

**Validation:**

- Configuration validated with `nix flake check` - passed
- Follows established pattern from `home/nixos/apps/vr.nix`
- No breaking changes to functionality

---

### Issue #3: Port Constants (COMPLETED - 2026-01-11)

**Implementation Summary:**

Successfully centralized all VR and gaming port constants in `lib/constants.nix` and updated all modules to use them instead of hardcoded values.

**Changes Made:**

1. **Added to `lib/constants.nix`**:
   - `ports.services.sunshine.*` - Sunshine streaming service ports (HTTP, HTTPS, RTSP, control, audio, video)
   - `ports.vr.wivrn.*` - WiVRn streaming ports (TCP/UDP 9757)
   - `ports.vr.alvr.*` - ALVR streaming ports (control: 9943, stream: 9944)
   - `ports.vr.mdns` - mDNS discovery port (5353)
   - `ports.gaming.steamLink.*` - Steam Link ports (discovery: 27031, streaming TCP/UDP)

2. **Updated Modules**:
   - `modules/nixos/features/vr.nix` - Now imports and uses constants for WiVRn and ALVR ports
   - `modules/nixos/features/gaming.nix` - Now imports and uses constants for Steam Link ports
   - `modules/nixos/services/caddy.nix` - Now uses constant for Sunshine reverse proxy port

**Benefits:**

- ✅ Centralized port management eliminates magic numbers
- ✅ Easier to detect port conflicts
- ✅ Consistent with existing MCP/services constants pattern
- ✅ Self-documenting code with clear port naming

**Validation:**

- All files formatted with `nix fmt`
- Configuration validated with `nix flake check` - passed with no errors
- No breaking changes to existing functionality

---

## Executive Summary

This document identifies architectural and best practice violations found in the gaming and VR configuration following analysis of `GAMING_VR_STREAMING_OPTIMIZATION_2026.md` and its associated module files. Issues range from incorrect module placement (home-manager vs system) to missing constants and potential over-engineering.

**Critical Issues**: 1 (1 completed ✅)
**Medium Priority**: 2 (1 completed ✅)
**Low Priority**: 2
**Documentation Concerns**: 2

All findings are backed by official NixOS documentation, community best practices, and the project's own CLAUDE.md guidelines.

---

## Issue #1: Gaming Environment Variables in System Module (✅ COMPLETED - 2026-01-11)

### Current State

**File**: `modules/nixos/features/gaming.nix:227-242`

```nix
environment.sessionVariables = {
  # Note: SDL2 (2.0.22+) and SDL3 default to Wayland automatically
  # SDL_VIDEO_DRIVER/SDL_VIDEODRIVER variables are no longer needed

  # Proton optimizations for NVIDIA
  PROTON_ENABLE_NVAPI = "1"; # Enable NVIDIA API for better game compatibility
  PROTON_HIDE_NVIDIA_GPU = "0"; # Don't hide GPU from games

  # Force Wayland for Qt games
  QT_QPA_PLATFORM = "wayland";
};
```

### Problem

Environment variables are set at **system level** (`environment.sessionVariables`) which applies them to **all users** on the system. These are gaming-specific user preferences that should be managed per-user via Home Manager.

### Evidence

From [NixOS Discourse: Environment Variables](https://discourse.nixos.org/t/trouble-setting-environment-variables-in-home-manager/43734) (accessed 2026-01-11):

> "Environment variables can be set with `environment.variables`, `environment.sessionVariables`, and `environment.profileRelativeSessionVariables`, where `environment.variables` are global variables set on shell initialization, whereas `environment.sessionVariables` and `environment.profileRelativeSessionVariables` are initialized through PAM."

And from [Home Manager documentation](https://nix-community.github.io/home-manager/) (accessed 2026-01-11):

> "Users can set environment variables using `home.sessionVariables` in their Home Manager configuration."

From project's own **CLAUDE.md**:

> **Home-Manager Level**: User applications and CLI tools, User services (systemd --user), Dotfiles and user configuration

Gaming environment variables are clearly user-level configuration, not system-level.

### Impact

- Violates separation of concerns between system and user configuration
- Applies gaming optimizations to all users (including non-gaming users)
- Not portable if different users need different gaming settings
- Contradicts CLAUDE.md architectural guidelines

### ✅ Implementation Completed (2026-01-11)

**Moved to**: `home/nixos/apps/gaming.nix`

```nix
{
  lib,
  pkgs,
  config,
  osConfig ? { },
  ...
}:
let
  inherit (lib) mkIf;
  gamingEnabled = osConfig.host.features.gaming.enable or false;
in
mkIf gamingEnabled {
  home.sessionVariables = {
    PROTON_ENABLE_NVAPI = "1";
    PROTON_HIDE_NVIDIA_GPU = "0";
    QT_QPA_PLATFORM = "wayland";
  };
  # ... rest of gaming config
}
```

**Removed from**: `modules/nixos/features/gaming.nix`

- System module now only contains system-level requirements
- Comment added explaining the move and rationale

**Result**: Gaming environment variables now properly configured at user-level.

### References

- ✅ [NixOS Environment Variables Wiki](https://wiki.nixos.org/wiki/Environment_variables) (2026-01-11)
- ✅ [Home Manager sessionVariables](https://mynixos.com/home-manager/option/home.sessionVariables) (2026-01-11)
- ✅ [NixOS Discourse: User-specific environment variables](https://discourse.nixos.org/t/is-there-any-way-to-set-user-specific-environment-variables-userly-and-nixily/33046) (2026-01-11)

---

## Issue #2: Monado User Service in System Module (CRITICAL)

### Current State

**File**: `modules/nixos/features/vr.nix:94-120`

```nix
# Monado environment variables (systemd user service)
systemd.user.services.monado = mkIf cfg.monado {
  environment = {
    # Enable SteamVR lighthouse tracking
    STEAMVR_LH_ENABLE = "1";
    # Use compute shaders for compositor (better performance)
    XRT_COMPOSITOR_COMPUTE = "1";
    # ... (13 more environment variables)

    # NVIDIA-specific VR optimizations (2026 best practices)
    __GL_SYNC_TO_VBLANK = "0";
    __GL_MaxFramesAllowed = "1";
    __GL_VRR_ALLOWED = "1";

    # Monado performance tuning
    XRT_COMPOSITOR_FORCE_RANDR = "0";
    U_PACING_APP_MIN_TIME_MS = "2";
  };
};
```

### Problem

User service configuration (`systemd.user.services`) is defined in a **system-level module** (`modules/nixos/`), which applies it to **all users system-wide**. This is a VR application configuration that should be per-user via Home Manager.

### Evidence

From [NixOS Discourse: systemd.services vs systemd.user.services](https://discourse.nixos.org/t/what-is-the-difference-between-systemd-services-and-systemd-user-services/25222) (accessed 2026-01-11):

> "Configuring systemd-user units can be done through a NixOS option, but it is shared along every user in the system."

From [DZone: NixOS and Home Manager with systemd services](https://dzone.com/articles/nixos-and-home-manager-update-with-nix-systemd-ser) (accessed 2026-01-11):

> "In home-manager (Nix) you can run systemd services as your own user, which is nice because you don't need 'sudo' permissions to do so. Home Manager allows you to configure user-specific systemd services that are isolated to individual users."

From [VR - Official NixOS Wiki](https://wiki.nixos.org/wiki/VR) (accessed 2026-01-11):

> "It is recommended to use home-manager to automate writing these config files, especially for OpenComposite/OpenVR path configuration."

From project's **CLAUDE.md**:

> **Required for Home-Manager**: User applications and CLI tools, User services (systemd --user), Dotfiles and user configuration, Desktop applications

### Impact

- Monado configuration applied to all users, even those not using VR
- Cannot have per-user VR performance tuning
- Violates Home Manager vs System module separation
- Environment variable tuning cannot be customized per-user

### Recommended Fix

**Move to**: `home/common/apps/vr.nix` or `home/nixos/apps/vr.nix`

```nix
# home/common/apps/vr.nix
{ config, lib, pkgs, ... }:
lib.mkIf config.host.features.vr.enable {
  systemd.user.services.monado = {
    Unit = {
      Description = "Monado VR Runtime";
      After = [ "graphical-session.target" ];
    };

    Service = {
      Environment = [
        "STEAMVR_LH_ENABLE=1"
        "XRT_COMPOSITOR_COMPUTE=1"
        # ... rest of environment variables
      ];
      ExecStart = "${pkgs.monado}/bin/monado-service";
      Restart = "on-failure";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
```

### References

- [Home Manager Manual - systemd services](https://nix-community.github.io/home-manager/) (2026-01-11)
- [Creating systemd services in Home Manager](https://haseebmajid.dev/posts/2023-10-08-how-to-create-systemd-services-in-nix-home-manager/) (2026-01-11)
- [VR NixOS Wiki](https://wiki.nixos.org/wiki/VR) (2026-01-11)

---

## Issue #3: Missing Port Constants (✅ COMPLETED - 2026-01-11)

### Current State

**File**: `lib/constants.nix` currently has:

```nix
ports = {
  mcp = { ... };
  services = {
    # Media services, containers, etc.
  };
};
```

But **missing**:

- VR streaming ports (WiVRn, ALVR, mDNS)
- Gaming ports (Steam Link)

**Current hardcoded usage** in `modules/nixos/features/vr.nix:161-167`:

```nix
allowedTCPPorts = [ 9757 ];
allowedUDPPorts = [ 5353 9757 ];
```

### Problem

Ports are hardcoded as magic numbers throughout the codebase instead of being centralized in `lib/constants.nix` as recommended by the project's architecture guidelines.

### Evidence

From project's **CLAUDE.md**:

> **Using New Infrastructure - Constants**:
>
> ```nix
> let
>   constants = import ../lib/constants.nix;
> in
> {
>   services.myService.port = constants.ports.services.myService;
> }
> ```

The `constants.nix` pattern is already established for MCP and services ports, but not applied to VR/gaming.

From [WiVRn NixOS module](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/video/wivrn.nix) (accessed 2026-01-11):

The upstream WiVRn module hardcodes port 9757, showing this is an established default, but our architecture prefers constants.

### Impact

- Inconsistent with existing constants.nix pattern
- Port numbers scattered across multiple modules
- Harder to detect port conflicts
- Not following project's own architectural guidelines

### ✅ Implementation Completed (2026-01-11)

**Added to `lib/constants.nix`**:

```nix
ports = {
  services = {
    # ... existing services ...

    # Game streaming services
    sunshine = {
      http = 47990;
      https = 47989;
      rtsp = 48010;
      control = 47998;
      audio = 47999;
      video = 48000;
    };
  };

  # VR streaming and discovery ports
  vr = {
    wivrn = {
      tcp = 9757;
      udp = 9757;
    };
    alvr = {
      control = 9943;
      stream = 9944;
    };
    mdns = 5353;
  };

  # Gaming network ports
  gaming = {
    steamLink = {
      discovery = 27031;
      streamingTcp = 27036;
      streamingUdp = [ 27036 27037 ];
    };
  };
};
```

**Updated modules**:

- `modules/nixos/features/vr.nix` - Uses constants for WiVRn and ALVR ports
- `modules/nixos/features/gaming.nix` - Uses constants for Steam Link ports
- `modules/nixos/services/caddy.nix` - Uses constant for Sunshine reverse proxy

**Result**: All gaming/VR ports now centralized and consistent with project architecture.

### References

- ✅ Project's own `lib/constants.nix` architecture pattern
- ✅ Project's CLAUDE.md guidelines

---

## Issue #4: Hardcoded VR Performance Values (MEDIUM)

### Current State

**File**: `modules/nixos/features/vr.nix:106-118`

```nix
# Monado performance tuning
XRT_COMPOSITOR_FORCE_RANDR = "0"; # Disable RandR on Wayland
U_PACING_APP_MIN_TIME_MS = "2"; # Minimum app frame time for low latency
```

And later in vr.nix:106:

```nix
U_PACING_COMP_MIN_TIME_MS = "5";
```

### Problem

Performance tuning values are **hardcoded** but the accompanying documentation (`GAMING_VR_STREAMING_OPTIMIZATION_2026.md` lines 923-926) suggests these need per-user tuning:

> **VR Latency Tuning**:
>
> If tracking feels laggy:
>
> ```nix
> # Lower frame pacing (more aggressive)
> U_PACING_APP_MIN_TIME_MS = "1";  # vs "2"
> U_PACING_COMP_MIN_TIME_MS = "3"; # vs "5"
> ```

### Evidence

From [NixOS Module System Best Practices](https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/module-system) (accessed 2026-01-11):

> "The settings pattern can encode the module's configuration file as a structural Nix value, which is preferred over hardcoded values."

From [NixOS RFC 0042: config option](https://github.com/NixOS/rfcs/blob/master/rfcs/0042-config-option.md) (accessed 2026-01-11):

> "Module authors should strike a balance for the number of additional options to not make the module too big, but still provide the most commonly used settings as separate options."

The document explicitly mentions tuning these values, indicating they should be configurable rather than hardcoded.

### Impact

- Users cannot tune VR performance without editing module files
- Documentation suggests tuning but provides no mechanism to do so
- Violates NixOS declarative configuration principles
- Not following the settings pattern used elsewhere in the config

### Recommended Fix

**Add to feature module options** in `modules/shared/features/vr.nix`:

```nix
options.host.features.vr = {
  # ... existing options ...

  performance = {
    pacing = {
      appMinTime = mkOption {
        type = types.str;
        default = "2";
        description = ''
          Minimum app frame time (ms). Lower values = more aggressive latency reduction.
          Recommended: 1-3ms. Default: 2ms.
        '';
      };

      compMinTime = mkOption {
        type = types.str;
        default = "5";
        description = ''
          Compositor minimum frame time (ms).
          Recommended: 3-7ms. Default: 5ms.
        '';
      };
    };
  };
};
```

**Then use in vr.nix**:

```nix
systemd.user.services.monado.environment = {
  U_PACING_APP_MIN_TIME_MS = cfg.performance.pacing.appMinTime;
  U_PACING_COMP_MIN_TIME_MS = cfg.performance.pacing.compMinTime;
};
```

### References

- [NixOS Module System and Custom Options](https://nixos-and-flakes.thiscute.world/other-usage-of-flakes/module-system) (2026-01-11)
- [RFC 0042 - config option](https://github.com/NixOS/rfcs/blob/master/rfcs/0042-config-option.md) (2026-01-11)

---

## Issue #5: Vulkan Variables in System vs User Context (MEDIUM)

### Current State

**File**: `modules/nixos/features/desktop/graphics.nix:51-83`

```nix
environment.sessionVariables = lib.mkMerge [
  # NVIDIA-specific configuration
  {
    WLR_DRM_DEVICES = "/dev/dri/card2";
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    NVD_BACKEND = "direct";
  }

  # Vulkan configuration - conditional on NVIDIA being enabled
  (lib.mkIf config.hardware.nvidia.modesetting.enable {
    VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
    VK_INSTANCE_LAYERS = "";
  })
];
```

### Problem

Mixed concerns: Some variables are legitimately system-level (driver configuration), but **Vulkan-specific gaming variables** are primarily for Steam/gaming which should be user-level.

### Analysis

**System-level (appropriate)**:

- `WLR_DRM_DEVICES` - Compositor needs this at system level
- `LIBVA_DRIVER_NAME` - Hardware acceleration driver selection
- `__GLX_VENDOR_LIBRARY_NAME` - OpenGL driver vendor
- `GBM_BACKEND` - Graphics buffer manager
- `NVD_BACKEND` - Gamescope NVIDIA backend

**User-level (should move)**:

- `VK_DRIVER_FILES` - Primarily needed for Steam's pressure-vessel container
- `VK_INSTANCE_LAYERS` - Gaming optimization (disables validation layers)

### Evidence

From `GAMING_VR_STREAMING_OPTIMIZATION_2026.md` lines 276-277:

> **Explicit Vulkan ICD (Conditional)**
>
> - Steam's pressure-vessel container finds GPU reliably
> - No "failed to find compatible device" errors

This indicates these variables are specifically for **Steam/gaming**, not system-wide graphics.

From [Steam on NixOS Wiki](https://wiki.nixos.org/wiki/Steam) (accessed 2026-01-11):

Steam-specific environment variables are commonly set per-user, not system-wide.

### Impact

- Minor: Vulkan variables work at system level but violate separation of concerns
- Applies gaming optimizations (disabled validation) to all users
- Not configurable for users who may want validation layers for development

### Recommended Fix

**Keep in graphics.nix** (system-level):

```nix
{
  WLR_DRM_DEVICES = "/dev/dri/card2";
  LIBVA_DRIVER_NAME = "nvidia";
  __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  GBM_BACKEND = "nvidia-drm";
  NVD_BACKEND = "direct";
}
```

**Move to home-manager** (gaming.nix):

```nix
home.sessionVariables = lib.mkIf config.host.features.gaming.enable {
  VK_DRIVER_FILES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
  VK_INSTANCE_LAYERS = "";
};
```

### References

- [Steam NixOS Wiki](https://wiki.nixos.org/wiki/Steam) (2026-01-11)
- [Arch Wiki: Vulkan](https://wiki.archlinux.org/title/Vulkan) (2026-01-11)

---

## Issue #6: Over-Engineering in Documentation (LOW)

### Current State

**File**: `docs/GAMING_VR_STREAMING_OPTIMIZATION_2026.md` lines 930-966

Contains extensive "Future Improvements" section with:

- Audio Latency optimization (Priority: LOW)
- GameMode Integration (Priority: MEDIUM)
- Sunshine AV1 Codec (Priority: LOW)
- VR Foveated Rendering (Priority: MEDIUM)
- HDR Calibration (Priority: LOW)
- **Monitoring Additions** with Prometheus exporters, Grafana dashboards

### Problem

From project's **CLAUDE.md**:

> "Don't design for hypothetical future requirements. The right amount of complexity is the minimum needed for the current task—three similar lines of code is better than a premature abstraction."

This "Future Improvements" section documents work that isn't planned or prioritized, creating technical debt in documentation form.

### Evidence

From [Refactoring Examples](docs/reference/REFACTORING_EXAMPLES.md) pattern in CLAUDE.md:

> "Avoid over-engineering. Only make changes that are directly requested or clearly necessary. Keep solutions simple and focused."

YAGNI (You Aren't Gonna Need It) principle applies to documentation as well as code.

### Impact

- Creates expectation of features that may never be implemented
- Adds maintenance burden (keeping future plans up to date)
- Contradicts project's explicit anti-over-engineering stance
- Low impact but violates stated principles

### Recommended Fix

**Remove** the entire "Future Improvements" section (lines 930-966).

**Optionally keep** only actionable, high-priority next steps if they are:

1. Already planned with concrete timeline
2. Directly requested by user
3. Necessary for current functionality

Otherwise, delete the section entirely.

### References

- Project's CLAUDE.md guidelines
- [REFACTORING_EXAMPLES.md](docs/reference/REFACTORING_EXAMPLES.md) principles

---

## Issue #7: Manual Maintenance Should Be Automated (LOW)

### Current State

**File**: `docs/GAMING_VR_STREAMING_OPTIMIZATION_2026.md` lines 863-901

Contains manual maintenance schedule:

```bash
# Weekly
# Check Vulkan driver version
vulkaninfo --summary | grep -i version

# Monthly
# Verify WiVRn ports still open
sudo ss -tulpn | grep -E '5353|9757'
```

### Problem

NixOS supports **assertions** and **tests** that can catch these issues automatically at build time rather than requiring manual verification schedules.

### Evidence

From project's **CLAUDE.md**:

> **Validators**:
>
> ```nix
> assertions = [
>   (validators.assertValidPort cfg.port "service-name")
> ];
> ```

Example from `modules/nixos/features/vr.nix:206-219` shows proper assertion usage:

```nix
assertions = [
  {
    assertion = cfg.steamvr -> config.host.features.gaming.steam;
    message = "SteamVR requires Steam (host.features.gaming.steam)";
  }
];
```

### Impact

- Manual checks are error-prone and likely to be skipped
- Wastes time on routine verification
- Issues only discovered during scheduled maintenance, not at build time

### Recommended Fix

**Add assertions** for critical checks:

```nix
# In modules/nixos/features/vr.nix
assertions = [
  {
    assertion = cfg.wivrn.enable -> (
      elem 9757 config.networking.firewall.allowedTCPPorts &&
      elem 9757 config.networking.firewall.allowedUDPPorts &&
      elem 5353 config.networking.firewall.allowedUDPPorts
    );
    message = "WiVRn requires ports 9757/TCP, 9757/UDP, and 5353/UDP (mDNS) to be open";
  }
];
```

**Remove** the manual maintenance schedule from documentation.

### References

- Project's CLAUDE.md validators pattern
- Existing assertion examples in vr.nix

---

## Issue #8: Sunshine State Management Limitation (INFORMATIONAL)

### Current State

**File**: `modules/nixos/services/sunshine.nix:431-470`

Uses declarative settings pattern:

```nix
services.sunshine.settings = {
  encoder = "nvenc";
  bitrate = 20000;
  # ... etc
};
```

### Known Limitation

From web research ([NixOS Sunshine Issues](https://github.com/nixos/nixpkgs/issues/433058), accessed 2026-01-11):

> "The apps.json file ends up read-only, preventing configuration changes through the web UI. If applications are set declaratively, no configuration is possible from the web UI."

### Impact

- Users cannot modify Sunshine settings via Web UI
- Must modify Nix configuration and rebuild to change settings
- This is a **known NixOS module limitation**, not a configuration error

### Recommended Action

**Document the limitation** prominently:

Add to `modules/nixos/services/sunshine.nix` module description:

```nix
# WARNING: Declarative Sunshine configuration makes the Web UI read-only.
# Changes to encoder, bitrate, and application settings MUST be made in this
# Nix configuration file and require a system rebuild to take effect.
# The Sunshine Web UI will show current settings but cannot modify them.
```

**No fix available** - this is an upstream NixOS module design decision.

### References

- [nixos/sunshine bugs and settings limitations](https://github.com/nixos/nixpkgs/issues/433058) (2026-01-11)
- [Sunshine NixOS Wiki](https://wiki.nixos.org/wiki/Sunshine) (2026-01-11)

---

## Issue #9: Niri VRR Configuration Not Mentioned (INFORMATIONAL)

### Current State

**File**: `home/nixos/niri.nix:80`

```nix
outputs = {
  "DP-3" = {
    # ... other settings ...
    variable-refresh-rate = true;
  };
};
```

**Documentation**: `GAMING_VR_STREAMING_OPTIMIZATION_2026.md` mentions relying on Niri's VRR instead of Gamescope's `--adaptive-sync`, but doesn't explicitly document that VRR is configured declaratively via home-manager.

### Problem

Minor documentation gap - the optimization document assumes VRR is configured but doesn't show where.

### Recommended Fix

**Add section** to `GAMING_VR_STREAMING_OPTIMIZATION_2026.md`:

```markdown
### Niri VRR Configuration (Declarative)

VRR is enabled declaratively in `home/nixos/niri.nix`:

\`\`\`nix
outputs = {
  "DP-3" = {
    variable-refresh-rate = true;
  };
};
\`\`\`

This is managed via home-manager and automatically applied on login.
```

### References

- [Niri Configuration: Outputs](https://github.com/YaLTeR/niri/wiki/Configuration:-Outputs) (2026-01-11)
- Existing configuration in `home/nixos/niri.nix`

---

## Validation: No Critical Antipatterns Found

### ✅ Verified Good Practices

1. **No `with pkgs;` usage** - All modules use explicit package references
2. **Assertions present** - Basic configuration validation exists
3. **Settings pattern used** - Sunshine properly uses `services.sunshine.settings`
4. **Constants.nix exists** - Infrastructure in place, just needs expansion
5. **Code quality high** - Well-commented, properly structured modules

### ✅ Configuration Accuracy

Verified that `GAMING_VR_STREAMING_OPTIMIZATION_2026.md` accurately describes the actual code:

- SDL/DXVK variable removal: ✅ Confirmed (gaming.nix:229-234)
- Conditional Vulkan config: ✅ Confirmed (graphics.nix:74-82)
- Niri VRR enabled: ✅ Confirmed (niri.nix:80)
- Gamescope capSysNice enabled: ✅ Confirmed (gaming.nix:74)

---

## Priority Matrix

| Priority | Issue | Effort | Impact | Status |
|----------|-------|--------|--------|--------|
| **CRITICAL** | #1: Gaming env vars placement | Medium | High | ✅ **COMPLETED** |
| **CRITICAL** | #2: Monado user service placement | Medium | High | Pending |
| **MEDIUM** | #3: Missing port constants | Low | Medium | ✅ **COMPLETED** |
| **MEDIUM** | #4: Hardcoded VR performance values | Medium | Medium | Pending |
| **MEDIUM** | #5: Vulkan variables split | Low | Low | Pending |
| **LOW** | #6: Over-engineering in docs | Low | Low | Pending |
| **LOW** | #7: Manual maintenance automation | Low | Low | Pending |
| **INFO** | #8: Sunshine state limitation | N/A | Document only | Pending |
| **INFO** | #9: Niri VRR documentation | Low | Low | Pending |

---

## Recommended Implementation Order

1. ✅ **Add VR/gaming ports to constants.nix** - **COMPLETED 2026-01-11** (Quick win, low risk)
2. ✅ **Move gaming environment variables to home-manager** - **COMPLETED 2026-01-11** (High impact, medium effort)
3. **Move Monado service config to home-manager** (High impact, medium effort)
4. **Add VR performance tuning options** (Medium impact, medium effort)
5. **Split Vulkan variables** (Low priority, can be done with #2)
6. **Trim documentation** (Low priority cleanup)
7. **Add assertions for ports** (Low priority improvement)

---

## Research Citations

All findings are based on:

1. **Official NixOS Documentation** (accessed 2026-01-11):
   - [NixOS Wiki: Environment Variables](https://wiki.nixos.org/wiki/Environment_variables)
   - [NixOS Wiki: VR](https://wiki.nixos.org/wiki/VR)
   - [NixOS Wiki: Steam](https://wiki.nixos.org/wiki/Steam)
   - [NixOS Wiki: Sunshine](https://wiki.nixos.org/wiki/Sunshine)

2. **Home Manager Documentation** (accessed 2026-01-11):
   - [Home Manager Manual](https://nix-community.github.io/home-manager/)
   - [MyNixOS: home.sessionVariables](https://mynixos.com/home-manager/option/home.sessionVariables)

3. **Community Resources** (accessed 2026-01-11):
   - [NixOS Discourse: Environment variables in home-manager](https://discourse.nixos.org/t/trouble-setting-environment-variables-in-home-manager/43734)
   - [NixOS Discourse: systemd.services vs systemd.user.services](https://discourse.nixos.org/t/what-is-the-difference-between-systemd-services-and-systemd-user-services/25222)
   - [DZone: NixOS and Home Manager with systemd](https://dzone.com/articles/nixos-and-home-manager-update-with-nix-systemd-ser)

4. **NixOS RFCs** (accessed 2026-01-11):
   - [RFC 0042: config option](https://github.com/NixOS/rfcs/blob/master/rfcs/0042-config-option.md)

5. **Niri Compositor** (accessed 2026-01-11):
   - [Niri Configuration: Outputs](https://github.com/YaLTeR/niri/wiki/Configuration:-Outputs)
   - [Niri VRR Configuration](https://yalter.github.io/niri/Configuration:-Outputs.html)

6. **Upstream Issues** (accessed 2026-01-11):
   - [NixOS Sunshine module limitations](https://github.com/nixos/nixpkgs/issues/433058)
   - [WiVRn NixOS module](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/video/wivrn.nix)
   - [Gamescope NixOS module](https://github.com/NixOS/nixpkgs/blob/release-25.11/nixos/modules/programs/gamescope.nix)

7. **Project Guidelines**:
   - CLAUDE.md (project-specific guidelines)
   - lib/constants.nix (existing infrastructure patterns)
   - Existing assertion patterns in modules

---

## Document Metadata

**Version**: 1.0
**Date**: 2026-01-11
**Analyzer**: Claude Sonnet 4.5
**Research Date**: 2026-01-11
**Files Analyzed**:

- `docs/GAMING_VR_STREAMING_OPTIMIZATION_2026.md`
- `modules/nixos/services/sunshine.nix`
- `modules/nixos/features/vr.nix`
- `modules/nixos/features/gaming.nix`
- `modules/nixos/features/desktop/graphics.nix`
- `home/nixos/niri.nix`
- `lib/constants.nix`

**Status**: Analysis Complete - Awaiting User Decision on Fixes

---

## End of Document
