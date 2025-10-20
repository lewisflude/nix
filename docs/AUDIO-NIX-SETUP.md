# Audio.nix Integration

This document describes the integration of [polygon/audio.nix](https://github.com/polygon/audio.nix) into the NixOS configuration.

## Overview

Audio.nix provides audio production packages for NixOS, including:
- **Bitwig Studio** - Digital Audio Workstation (DAW)
- **Audio Plugins** - VST/LV2 plugins for music production
- **Neural Tools** - AI-powered audio processing

## Configuration

### Flake Setup

The audio.nix flake is added as an input in `flake.nix`:

```nix
audio-nix = {
  url = "github:polygon/audio.nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

The overlay is automatically applied via `overlays/default.nix`:

```nix
# Audio production packages (Linux-only)
audio-nix = mkConditional isLinux inputs.audio-nix.overlays.default;
```

### Host Configuration

Enable audio.nix packages in your host configuration (e.g., `hosts/jupiter/default.nix`):

```nix
audio = {
  enable = true;
  realtime = true;  # Real-time kernel optimizations
  audioNix = {
    enable = true;
    bitwig = true;   # Install Bitwig Studio
    plugins = true;  # Install audio plugins
  };
};
```

### Available Options

- `host.features.audio.audioNix.enable` - Enable audio.nix packages
- `host.features.audio.audioNix.bitwig` - Install Bitwig Studio (stable latest)
- `host.features.audio.audioNix.plugins` - Install audio plugins

## Currently Available Packages

### DAW
- ✅ **bitwig-studio-stable-latest** - Bitwig Studio 5.3.12 (stable)

### Plugins
- ✅ **neuralnote** - AI-powered audio transcription
- ✅ **paulxstretch** - Extreme audio time-stretching

### Packages with Compatibility Issues

The following packages require `gcc11Stdenv` which has been removed from nixpkgs-unstable:

#### CHOW Plugins
- ⏳ chow-tape-model - Analog tape emulation
- ⏳ chow-centaur - Klon Centaur overdrive
- ⏳ chow-kick - Kick drum synthesizer
- ⏳ chow-phaser - Phaser effect
- ⏳ chow-multitool - Multi-effects tool

#### Synths & Instruments
- ⏳ vital - Wavetable synthesizer
- ⏳ atlas2 - Sample player
- ⏳ papu - Chip tune synthesizer

## Workarounds

### Running Packages Directly from audio.nix

You can still run these packages standalone without installing them:

```bash
# Run Vital synthesizer
nix run github:polygon/audio.nix#vital

# Run Paul's Extreme Time Stretch
nix run github:polygon/audio.nix#paulxstretch

# Run any CHOW plugin
nix run github:polygon/audio.nix#chow-tape-model
```

### Using in Bitwig

For packages that don't install system-wide, you can:

1. Build them with `nix build`
2. Sym link the VST/LV2 plugins to your plugin directory
3. Configure Bitwig to scan that directory

Example:
```bash
# Build vital and link it
nix build github:polygon/audio.nix#vital
ln -s ./result/lib/vst3/vital.vst3 ~/.vst3/
```

## Future Updates

These packages will become available once:
1. The upstream audio.nix flake updates to use gcc13Stdenv or later
2. OR nixpkgs re-introduces gcc11Stdenv (unlikely)

To check for updates:
```bash
nix flake update audio-nix
```

## Technical Details

### Why the Compatibility Issue?

- nixpkgs-unstable removed `gcc11Stdenv` in August 2025 (marked as unmaintained)
- audio.nix packages were built against an older nixpkgs that had gcc11
- Even though we set `inputs.nixpkgs.follows = "nixpkgs"`, some packages in audio.nix explicitly reference gcc11Stdenv in their build expressions

### Module Structure

- **Options defined in**: `modules/shared/host-options.nix`
- **Implementation in**: `modules/nixos/features/audio.nix`
- **Overlay configured in**: `overlays/default.nix`

## References

- [audio.nix GitHub](https://github.com/polygon/audio.nix)
- [audio.nix README](https://github.com/polygon/audio.nix#readme)
- [Bitwig Studio](https://www.bitwig.com/)
