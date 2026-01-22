# VR Quick Start Guide

Quick reference for dual WiVRn + ALVR setup.

## Installation

Already configured in `hosts/jupiter/default.nix`:

```nix
features.vr = {
  enable = true;
  wivrn.enable = true;     # Primary runtime
  alvr.enable = true;      # Secondary runtime
  steamvr = true;          # For 32-bit games
};
```

After rebuilding, both runtimes are available.

## Quick Commands

```bash
# Check which runtime is default
vr-which-runtime

# Switch default to WiVRn
vr-use-wivrn

# Switch default to ALVR
vr-use-alvr

# Show launch options for Steam
vr-launch-options

# Service management
systemctl --user start wivrn
systemctl --user start alvr
systemctl --user status wivrn
systemctl --user status alvr
```

## Steam Launch Options

### Use ALVR for specific game:
```bash
XR_RUNTIME_JSON=/nix/store/.../openxr_alvr.json %command%
```
(Run `vr-launch-options` to get the exact path)

### Use WiVRn for specific game:
```bash
XR_RUNTIME_JSON=/nix/store/.../openxr_wivrn.json %command%
```

### 64-bit OpenVR games with xrizer:
```bash
xrizer PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc %command%
```

### 32-bit games (e.g., Half-Life 2 VR):
```bash
%command%
```
(Uses system default runtime + SteamVR)

## Game Recommendations

**Use WiVRn for:**
- Modern OpenXR games (Half-Life: Alyx, Bonelab)
- 64-bit OpenVR games with xrizer (Beat Saber, Blade & Sorcery)

**Use ALVR for:**
- Half-Life 2: VR Mod (better compatibility)
- Games with WiVRn issues

## Full Documentation

- **Dual Runtime Setup**: `docs/VR_DUAL_RUNTIME.md`
- **Half-Life 2 VR**: `docs/HL2VR_SETUP.md`
