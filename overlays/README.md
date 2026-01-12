# Package Overlays

This directory contains package overlays that modify or replace packages from nixpkgs.

## Active Overlays

### System Overlays

- **nh**: Nix helper tool overlay
- **nix-topology**: Network topology visualization
- **flake-editors**: Latest Zed editor from flake (with cache)
- **fenix-overlay**: Rust toolchains from fenix
- **flake-git-tools**: Lazygit using nixpkgs for binary cache
- **flake-cli-tools**: Atuin using nixpkgs for binary cache
- **niri**: Niri compositor (Linux only)
- **nixpkgs-xr**: VR/AR/XR packages (Linux only)
- **comfyui**: Native Nix ComfyUI package
- **audio-nix**: Bitwig Studio and audio plugins with webkit compatibility
- **llm-agents**: Pre-built binaries from llm-agents.nix with cache
- **onetbb-fix**: Disable tests on i686-linux due to flakiness
- **immersed-latest**: Use latest Immersed VR from static download URL

### Immersed VR Override

The `immersed-latest` overlay pulls the latest version directly from Immersed's static download URL instead of using archived versions. This ensures you get the most recent release.

**Current version**: `11.0.0-latest` (fetched from <https://static.immersed.com/dl/>)

**Hash verification**:

- x86_64-Linux: `sha256-GbckZ/WK+7/PFQvTfUwwePtufPKVwIwSPh+Bo/cG7ko=`
- aarch64-Linux: `sha256-3BokV30y6QRjE94K7JQ6iIuQw1t+h3BKZY+nEFGTVHI=` (from nixpkgs)
- macOS: `sha256-lmSkatB75Bztm19aCC50qrd/NV+HQX9nBMOTxIguaqI=` (from nixpkgs)

**Note**: To update to a new version when Immersed releases updates:

1. Download the new AppImage: `curl -L https://static.immersed.com/dl/Immersed-x86_64.AppImage -o /tmp/immersed.AppImage`
2. Calculate the hash: `nix hash file /tmp/immersed.AppImage`
3. Update the hash in `overlays/default.nix`
4. Update the version string if needed
5. Rebuild: `nh os switch` (or `sudo nixos-rebuild switch`)

## Disabled Overlays

- **claude-code-overlay**: Disabled due to runtime errors (Bun Segmenter initialization errors)
- **filesystem**: Disabled for security

## Usage

Overlays are automatically applied via `lib/functions.nix:mkOverlays` and used in:

- `flake-parts/per-system/pkgs.nix` - Per-system package sets
- `lib/system-builders.nix` - NixOS and Darwin configurations

## Adding New Overlays

1. Add the overlay function to `overlays/default.nix`
2. Format: `nix fmt overlays/default.nix`
3. Test: `nix flake check`
4. Rebuild system to apply changes
