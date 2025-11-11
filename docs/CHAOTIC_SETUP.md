# Chaotic Nyx Configuration

This document describes how Chaotic Nyx bleeding-edge packages are configured in this repository.

## Overview

We use Chaotic Nyx's official modules to get access to bleeding-edge versions of packages. Instead of using custom overlays or centralized configuration modules, we **directly specify `_git` package versions** where they're used throughout the codebase. This approach is:

- ? **Explicit**: You can see exactly what version each package uses
- ? **Simple**: No extra abstraction layers
- ? **Maintainable**: Easy to track in git history

## Current Chaotic Packages

### Development Tools

- **Helix Editor** (`helix_git`): `home/common/apps/helix.nix`
- **Zed Editor** (`zed-editor_git`): `home/common/apps/zed-editor.nix`

### Desktop Applications

- **Discord** (`discord-krisp`): `home/nixos/desktop-apps.nix` (includes Krisp noise suppression)
- **Telegram** (`telegram-desktop_git`): `home/nixos/desktop-apps.nix`

### Gaming/Graphics

- **MangoHud** (`mangohud_git`): `home/nixos/apps/gaming.nix`

### Kernel (Optional)

- **CachyOS Kernel** (`linuxPackages_cachyos`): Available via feature flag (see below)

## CachyOS Kernel Setup

The CachyOS kernel is available but **not enabled by default** to ensure ZFS compatibility. To enable:

```nix
# In your host configuration (e.g., hosts/jupiter/configuration.nix)
{
  host.features.cachyos-kernel = {
    enable = true;  # Enable CachyOS EEVDF-BORE kernel

    # Optional: Enable sched-ext schedulers (requires kernel 6.12+)
    enableSchedExt = true;
    schedExtScheduler = "scx_rustland";  # or: scx_rusty, scx_lavd, scx_bpfland
    schedExtPackage = pkgs.scx_git.full;  # Use bleeding-edge schedulers
  };
}
```

**Important Notes:**

- CachyOS kernel includes ZFS support via `zfs_cachyos` module
- Automatic ZFS compatibility checking is built-in
- Alternative variants available: `cachyos-lto`, `cachyos-hardened`, `cachyos-server`, `cachyos-lts`
- Module location: `modules/nixos/features/chaotic-kernel.nix`

## Why NOT mesa-git?

**We deliberately skip `chaotic.mesa-git`** because this system uses NVIDIA GPUs. From Chaotic's documentation:

> WARNING: It will break NVIDIA's libgbm, don't use with NVIDIA Optimus setups.

Our system uses NVIDIA RTX 4090 with proprietary drivers, so mesa-git would break graphics support.

## Chaotic Nyx Modules

We use these official Chaotic modules (configured automatically):

```nix
# In lib/system-builders.nix
chaotic.nixosModules.default      # NixOS: Adds overlay, cache, registry
chaotic.homeManagerModules.default # Home Manager: Package access
```

These modules automatically provide:

- ? Binary cache configuration (`chaotic-nyx.cachix.org`)
- ? Package overlay (all `_git` packages available as `pkgs.*_git`)
- ? Nix registry entry (`nix run chaotic#package`)
- ? nixPath entry (legacy compatibility)

## Available Options

### Cache Control

```nix
chaotic.nyx.cache.enable = true;  # Default: automatically configured
```

### Overlay Control

```nix
chaotic.nyx.overlay.enable = true;  # Default: enabled
chaotic.nyx.overlay.onTopOf = "flake-nixpkgs";  # Default: use Chaotic's nixpkgs (cache-friendly)
```

### Other System-Level Features

Not currently used, but available if needed:

- `chaotic.mesa-git.enable` - Latest Mesa drivers (AMD/Intel only, breaks NVIDIA)
- `chaotic.hdr.enable` - HDR support (AMD only)
- `chaotic.nordvpn.enable` - NordVPN daemon
- `chaotic.duckdns.enable` - DuckDNS dynamic DNS
- `chaotic.appmenu-gtk3-module.enable` - GTK3 appmenu support

See [Chaotic Nyx documentation](https://nyx.chaotic.cx) for full list.

## Adding New Chaotic Packages

To use a bleeding-edge package:

1. Check if `packagename_git` exists: [Chaotic packages list](https://nyx.chaotic.cx/#lists-of-options-and-packages)
2. Update the file where you use the package:

   ```nix
   # Before
   home.packages = [ pkgs.alacritty ];

   # After
   home.packages = [ pkgs.alacritty_git ]; # Chaotic Nyx bleeding-edge version
   ```

3. Add a comment explaining it's from Chaotic Nyx
4. Binary cache automatically provides pre-built binaries ?

## Removing Chaotic Packages

To switch back to stable:

1. Remove the `_git` suffix:

   ```nix
   # Before
   home.packages = [ pkgs.helix_git ]; # Chaotic Nyx bleeding-edge version

   # After
   home.packages = [ pkgs.helix ];
   ```

2. Remove the Chaotic comment

## Troubleshooting

### Package Building from Source

If a Chaotic package is building from source instead of using the binary cache:

1. Check if the cache is working:

   ```bash
   curl -L 'https://chaotic-nyx.cachix.org/<store-path>.narinfo'
   ```

2. Verify cache is configured:

   ```bash
   grep chaotic /etc/nix/nix.conf
   ```

   Should show chaotic-nyx.cachix.org in substituters and trusted keys.

3. Try clearing Nix's HTTP cache:

   ```bash
   rm -rf ~/.cache/nix
   ```

### ZFS + CachyOS Kernel Issues

If you get ZFS compatibility errors:

1. Use `cachyos-lts` variant (longer support cycle)
2. Check ZFS version compatibility
3. Temporarily use stable kernel until ZFS catches up

## References

- [Chaotic Nyx GitHub](https://github.com/chaotic-cx/nyx)
- [Chaotic Nyx Documentation](https://nyx.chaotic.cx)
- [Package List](https://nyx.chaotic.cx/#lists-of-options-and-packages)
- [CachyOS Kernel](https://github.com/CachyOS/linux-cachyos)
- [sched-ext Schedulers](https://github.com/sched-ext/scx)
