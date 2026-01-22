# VR Dual Runtime Setup - Changelog

**Date**: 2026-01-21
**Summary**: Added ALVR support alongside WiVRn for dual OpenXR runtime capability

## What Was Added

### 1. Configuration Options
Added ALVR configuration options to `modules/shared/host-options/features/vr.nix`:

```nix
features.vr.alvr = {
  enable          # Enable ALVR
  autoStart       # Start ALVR service on boot
  defaultRuntime  # Set ALVR as default OpenXR runtime
  openFirewall    # Open firewall ports for ALVR
};
```

### 2. ALVR Module
Created `modules/nixos/features/vr/alvr.nix`:
- Enables `programs.alvr` from nixpkgs
- Handles auto-start configuration
- Opens firewall ports when requested

### 3. Helper Commands
Added to `home/nixos/apps/vr.nix`:

```bash
vr-use-wivrn        # Switch default runtime to WiVRn
vr-use-alvr         # Switch default runtime to ALVR
vr-which-runtime    # Show current default runtime
vr-launch-options   # Display Steam launch options for both runtimes
```

### 4. Host Configuration
Updated `hosts/jupiter/default.nix`:

```nix
features.vr = {
  enable = true;
  wivrn = {
    enable = true;
    autoStart = true;
    defaultRuntime = true;   # WiVRn is default
    openFirewall = true;
  };
  alvr = {
    enable = true;
    autoStart = false;       # Start manually when needed
    defaultRuntime = false;  # Override per-game
    openFirewall = true;
  };
  steamvr = true;           # For 32-bit games
  performance = true;
};
```

### 5. Documentation
Created comprehensive documentation:

- **`docs/VR_DUAL_RUNTIME.md`** - Complete dual runtime setup guide
  - Configuration examples
  - Usage instructions for both methods (per-game launch options and system default switching)
  - Game-specific recommendations
  - Troubleshooting section
  - Architecture diagrams

- **`docs/VR_QUICK_START.md`** - Quick reference guide
  - Essential commands
  - Steam launch options
  - Game recommendations

## Key Features

### Per-Game Runtime Selection
Use Steam launch options to choose runtime without changing system default:

```bash
# Use ALVR for this game
XR_RUNTIME_JSON=/nix/store/.../openxr_alvr.json %command%

# Use WiVRn for this game
XR_RUNTIME_JSON=/nix/store/.../openxr_wivrn.json %command%
```

### System Default Switching
Change the default runtime used by all games:

```bash
vr-use-wivrn   # Make WiVRn default
vr-use-alvr    # Make ALVR default
```

### Both Services Can Run Simultaneously
- WiVRn uses ports 9757-9758
- ALVR uses ports 9943-9944
- No conflicts, both can be active

## Why This Setup?

Based on [VR Linux DB community reports](https://db.vronlinux.org/games/658920.html):

- **Half-Life 2: VR Mod** works better with ALVR
- **Modern OpenXR games** work better with WiVRn
- Having both provides maximum compatibility

## Files Modified

### Core Configuration
- `modules/shared/host-options/features/vr.nix` - Added ALVR options
- `modules/nixos/features/vr/alvr.nix` - New ALVR module (created)
- `modules/nixos/features/vr/default.nix` - Imported ALVR module, added assertion
- `home/nixos/apps/vr.nix` - Added helper scripts and runtime switching
- `hosts/jupiter/default.nix` - Enabled ALVR alongside WiVRn

### Documentation
- `docs/VR_DUAL_RUNTIME.md` - Comprehensive setup guide (created)
- `docs/VR_QUICK_START.md` - Quick reference (created)
- `docs/VR_DUAL_RUNTIME_CHANGELOG.md` - This file (created)

## Validation

Configuration validated with:
```bash
nix flake check --no-build
```

All checks pass successfully.

## Next Steps

1. Rebuild your system:
   ```bash
   nh os switch
   ```

2. Start ALVR when needed:
   ```bash
   systemctl --user start alvr
   ```

3. Test with Half-Life 2: VR Mod:
   - Add launch option: `XR_RUNTIME_JSON=/nix/store/.../openxr_alvr.json %command%`
   - Get exact path with: `vr-launch-options`

4. Use WiVRn as default for other games (already configured)

## Technical Notes

### Runtime Selection Priority
1. `XR_RUNTIME_JSON` environment variable (highest priority)
2. `~/.config/openxr/1/active_runtime.json` (system default)

### Module Architecture
- **System-level**: Service configuration, firewall rules
- **Home-Manager**: Runtime files, helper scripts, user packages
- **Separation**: ALVR and WiVRn modules are independent and can coexist

### Assertion
Added assertion to prevent both runtimes being set as default simultaneously:
```nix
assertion = !(cfg.wivrn.defaultRuntime && cfg.alvr.defaultRuntime);
message = "Cannot set both WiVRn and ALVR as default OpenXR runtime";
```

## References

- [VR Linux DB - Half-Life 2: VR Mod](https://db.vronlinux.org/games/658920.html)
- [NixOS ALVR Option](https://search.nixos.org/options?query=programs.alvr)
- WiVRn: <https://github.com/WiVRn/WiVRn>
- ALVR: <https://github.com/alvr-org/ALVR>
