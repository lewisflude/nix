# VR Dual Runtime Setup - WiVRn + ALVR

**Last Updated**: 2026-01-21
**System**: NixOS with dual OpenXR runtime support

---

## Overview

This configuration supports running both **WiVRn** and **ALVR** simultaneously, allowing you to choose which runtime to use on a per-game basis. This is particularly useful because:

- **WiVRn**: Better for native OpenXR games, excellent Wayland/Niri integration, embedded Monado runtime
- **ALVR**: Better compatibility with some games (e.g., Half-Life 2 VR Mod), especially older 32-bit titles

## Why Both?

Based on community reports ([VR Linux DB](https://db.vronlinux.org)):
- Some games work better with ALVR (e.g., Half-Life 2 VR Mod)
- WiVRn has better desktop integration and performance for modern games
- Having both lets you choose the best runtime for each game

## Configuration

### Enable Both Runtimes

In your host configuration (`hosts/jupiter/default.nix`):

```nix
features.vr = {
  enable = true;
  
  # WiVRn - Primary runtime for most games
  wivrn = {
    enable = true;
    autoStart = true;
    defaultRuntime = true;  # Set as system default
    openFirewall = true;
  };
  
  # ALVR - Secondary runtime for compatibility
  alvr = {
    enable = true;
    autoStart = false;      # Start manually when needed
    defaultRuntime = false; # Override per-game with launch options
    openFirewall = true;
  };
  
  steamvr = true;    # Required for 32-bit games
  performance = true;
};
```

### Rebuild System

```bash
nh os switch
```

---

## Usage

### Helper Commands

After rebuilding, you'll have these commands available:

```bash
# Show which runtime is currently default
vr-which-runtime

# Switch default runtime to WiVRn
vr-use-wivrn

# Switch default runtime to ALVR
vr-use-alvr

# Show Steam launch options for both runtimes
vr-launch-options
```

### Method 1: Per-Game Launch Options (Recommended)

This is the best approach - keep one runtime as default and override specific games.

#### Using ALVR for a Specific Game

1. Right-click game in Steam → **Properties** → **Launch Options**
2. Add:
   ```bash
   XR_RUNTIME_JSON=/nix/store/.../share/openxr/1/openxr_alvr.json %command%
   ```
3. Or use the helper to get the exact path:
   ```bash
   vr-launch-options  # Copy the ALVR line shown
   ```

#### Using WiVRn for a Specific Game

If you've set ALVR as default but want WiVRn for a game:

```bash
XR_RUNTIME_JSON=/nix/store/.../share/openxr/1/openxr_wivrn.json %command%
```

### Method 2: Switch System Default

If you want to change which runtime is used by default:

```bash
# Make WiVRn default
vr-use-wivrn

# Make ALVR default
vr-use-alvr

# Check current default
vr-which-runtime
```

---

## Service Management

### Starting/Stopping Services

```bash
# WiVRn
systemctl --user start wivrn
systemctl --user stop wivrn
systemctl --user status wivrn

# ALVR
systemctl --user start alvr
systemctl --user stop alvr
systemctl --user status alvr
```

### Running Both at Once

**Yes, both can run simultaneously!** They use different ports and don't conflict. You can:

1. Have WiVRn auto-start (for most games)
2. Manually start ALVR when needed for specific games
3. Your Quest headset connects to whichever runtime the game is using

---

## Game-Specific Recommendations

### Use WiVRn For:

- **Native OpenXR games** (64-bit):
  - Half-Life: Alyx
  - Bonelab
  - Most modern VR titles
  - Launch option: `PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc %command%`

- **OpenVR games (64-bit)** with xrizer:
  - Beat Saber
  - Blade & Sorcery
  - Launch option: `xrizer PRESSURE_VESSEL_FILESYSTEMS_RW=$XDG_RUNTIME_DIR/wivrn/comp_ipc %command%`

### Use ALVR For:

- **Half-Life 2: VR Mod** (confirmed working better with ALVR)
  - Launch option: `XR_RUNTIME_JSON=/nix/store/.../openxr_alvr.json %command%`
  - Use `vr-launch-options` to get exact path

- **Games with WiVRn compatibility issues**
  - Test with ALVR if you encounter problems

### 32-bit Games (Special Case):

For 32-bit OpenVR games like Half-Life 2 VR, you **must use SteamVR** as the OpenVR runtime, but you can choose between ALVR or WiVRn for streaming:

**With ALVR:**
```bash
XR_RUNTIME_JSON=/nix/store/.../openxr_alvr.json %command%
```

**With WiVRn:**
```bash
%command%  # If WiVRn is default
```

See `docs/HL2VR_SETUP.md` for full 32-bit game setup details.

---

## Troubleshooting

### Game Won't Launch with Either Runtime

1. Check which runtime is active:
   ```bash
   vr-which-runtime
   ```

2. Try the other runtime using launch options

3. Verify the service is running:
   ```bash
   systemctl --user status wivrn
   systemctl --user status alvr
   ```

### "Runtime Not Found" Error

The runtime paths in launch options are Nix store paths, which change when packages update. Use the helper command to get current paths:

```bash
vr-launch-options
```

### Only One Runtime Seems to Work

1. Check firewall is open for both:
   ```bash
   sudo nft list ruleset | grep -E '9943|9944'  # WiVRn ports
   sudo nft list ruleset | grep 9943             # ALVR port
   ```

2. Ensure both are enabled in your config:
   ```nix
   features.vr.wivrn.enable = true;
   features.vr.alvr.enable = true;
   ```

### Quest Can't Find Server

**For WiVRn:**
- Server name: `jupiter` (your hostname)
- Should auto-discover via Avahi

**For ALVR:**
- Open ALVR dashboard to see connection status
- May need manual IP entry in ALVR client

---

## How It Works

### OpenXR Runtime Selection

OpenXR applications check for the active runtime in this order:

1. **`XR_RUNTIME_JSON` environment variable** (highest priority)
   - Used in Steam launch options
   - Overrides system default

2. **`~/.config/openxr/1/active_runtime.json`** (system default)
   - Set by `defaultRuntime = true` in config
   - Changed by `vr-use-wivrn` / `vr-use-alvr` commands

### Architecture

```
┌─────────────────────────────────────────────────────┐
│ PC (NixOS)                                          │
│                                                     │
│  ┌────────────┐              ┌────────────┐        │
│  │   WiVRn    │              │    ALVR    │        │
│  │  (Monado)  │              │            │        │
│  │ Port 9757  │              │ Port 9943  │        │
│  └──────┬─────┘              └──────┬─────┘        │
│         │                           │              │
│         └───────────┬───────────────┘              │
│                     │                              │
│         Per-game runtime selection                 │
│         (XR_RUNTIME_JSON or default)               │
│                     │                              │
└─────────────────────┼──────────────────────────────┘
                      │ WiFi 6
                      ▼
              ┌───────────────┐
              │  Quest Client │
              │  (WiVRn/ALVR) │
              └───────────────┘
```

### Port Usage

- **WiVRn**: 9757 (control), 9758 (video)
- **ALVR**: 9943, 9944
- Both can be open simultaneously without conflict

---

## Configuration Reference

### Full Example Config

```nix
# hosts/jupiter/default.nix
{
  features.vr = {
    enable = true;
    
    wivrn = {
      enable = true;
      autoStart = true;
      defaultRuntime = true;
      openFirewall = true;
    };
    
    alvr = {
      enable = true;
      autoStart = false;  # Start manually
      defaultRuntime = false;
      openFirewall = true;
    };
    
    steamvr = true;      # For 32-bit games
    performance = true;  # VR optimizations
  };
}
```

### Module Options

All options are in `modules/shared/host-options/features/vr.nix`:

```nix
features.vr.wivrn = {
  enable            # Enable WiVRn
  autoStart         # Start on boot
  defaultRuntime    # Set as system default OpenXR runtime
  openFirewall      # Open firewall ports
};

features.vr.alvr = {
  enable            # Enable ALVR
  autoStart         # Start on boot
  defaultRuntime    # Set as system default OpenXR runtime
  openFirewall      # Open firewall ports
};
```

**Note**: Cannot set both `defaultRuntime = true` - this will cause a build error.

---

## Related Documentation

- **HL2 VR Setup**: `docs/HL2VR_SETUP.md` - Half-Life 2 VR Mod specific setup
- **VR Features**: `modules/nixos/features/vr/` - Module implementations
- **Community Reports**: [VR Linux DB](https://db.vronlinux.org/games/658920.html)

---

## FAQ

### Q: Which runtime should I use as default?

**A**: Keep **WiVRn** as default if you play mostly modern OpenXR games. Use ALVR launch options for games that need it.

### Q: Can both services run at the same time?

**A**: Yes! They use different ports and don't conflict.

### Q: Do I need to restart anything when switching?

**A**: No. The game will use whichever runtime is specified in its launch options or the system default.

### Q: What if a game doesn't work with either runtime?

**A**: Try SteamVR as a fallback. Some older games may require it.

### Q: How do I know which runtime a game is actually using?

**A**: Check the logs:
```bash
journalctl --user -u wivrn -f  # WiVRn logs
journalctl --user -u alvr -f   # ALVR logs
```

### Q: Does this work for PCVR streaming from other PCs?

**A**: Yes! Both WiVRn and ALVR support streaming from any PC to your Quest headset.

---

## Contributing

Found an issue or improvement? Please update this guide or open an issue.

**Last tested**: 2026-01-21 with:
- NixOS 25.05
- WiVRn 25.12
- ALVR (latest from nixpkgs)
- Meta Quest 3
