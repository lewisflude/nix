# Module Organization

This directory contains all system and user configuration modules organized by platform and purpose.

## Structure

```
modules/
├── shared/          Cross-platform modules (Darwin + NixOS)
├── darwin/          macOS-specific modules
└── nixos/           NixOS-specific modules
```

## Shared Modules (Cross-Platform)

Located in `modules/shared/`

### Core Configuration
- **`host-options.nix`** - Host configuration options schema
- **`core.nix`** - Core Nix settings (experimental features, trusted users)
- **`shell.nix`** - Shell environment configuration
- **`dev.nix`** - Development environment setup
- **`environment.nix`** - Environment variables
- **`overlays.nix`** - Nixpkgs overlay management
- **`cachix.nix`** - Binary cache configuration
- **`sops.nix`** - Secrets management (SOPS)

### Feature Modules
Cross-platform features controlled by `host.features.*` options:

- **`features/development.nix`** - Development tools (rust, python, go, node, lua)
- **`features/security.nix`** - Security tools (GPG, YubiKey, VPN)
- **`features/productivity.nix`** - Productivity apps (office, notes, email)
- **`features/desktop.nix`** - Desktop basics and theming

## Darwin Modules (macOS)

Located in `modules/darwin/`

macOS-specific system configuration:
- System preferences and defaults
- Homebrew integration
- macOS-specific services

## NixOS Modules

Located in `modules/nixos/`

### Core System
- **`core/`** - Boot, networking, security, power management
- **`hardware/`** - Bluetooth, keyboard, mouse, USB, YubiKey
- **`system/`** - System utilities, maintenance, XDG integration

### Desktop Environment
- **`desktop/`** - Graphics, audio, theming, window managers
  - `niri.nix` - Niri compositor
  - `hyprland.nix` - Hyprland compositor
  - `audio/` - PipeWire and audio configuration

### Features
NixOS-specific features:

- **`features/gaming.nix`** - Gaming (Steam, performance optimizations)
- **`features/virtualisation.nix`** - VMs and containers (Docker, Podman, QEMU)
- **`features/audio.nix`** - Audio production and real-time optimization
- **`features/home-server.nix`** - Home server services (Home Assistant, Samba, backups)

### Services
- **`services/`** - System services
  - `home-assistant.nix` - Home automation
  - `music-assistant.nix` - Music streaming
  - `samba.nix` - File sharing
  - `ssh.nix` - SSH server

## Usage

### Enabling Features

Features are enabled in host configurations (`hosts/*/default.nix`):

```nix
{
  username = "user";
  hostname = "machine";
  system = "x86_64-linux";
  
  features = {
    development = {
      enable = true;
      rust = true;
      python = true;
      go = true;
    };
    
    gaming = {
      enable = true;
      steam = true;
      performance = true;
    };
    
    security = {
      enable = true;
      yubikey = true;
      gpg = true;
    };
  };
}
```

### Platform Detection

Modules automatically detect the platform and apply appropriate configuration:

```nix
# In a shared module
{
  config,
  lib,
  pkgs,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;
in {
  # Platform-specific config
  config = lib.mkMerge [
    (lib.mkIf isLinux {
      # Linux-only configuration
    })
    (lib.mkIf isDarwin {
      # Darwin-only configuration
    })
  ];
}
```

## Feature System

The feature system provides a declarative way to enable/disable major functionality:

### Feature Categories

1. **development** - Programming languages and tools
2. **gaming** - Gaming platforms and optimizations (NixOS only)
3. **virtualisation** - Containers and VMs
4. **desktop** - Desktop environment and theming
5. **security** - Security tools and hardware
6. **productivity** - Office and productivity apps
7. **audio** - Audio production and real-time (NixOS only)
8. **homeServer** - Self-hosting services (NixOS only)

### Creating New Features

To add a new feature:

1. Add option to `modules/shared/host-options.nix`:
```nix
features.myFeature = {
  enable = mkEnableOption "my feature";
  option1 = mkOption { ... };
};
```

2. Create module in appropriate location:
   - Cross-platform: `modules/shared/features/my-feature.nix`
   - NixOS-only: `modules/nixos/features/my-feature.nix`

3. Import in `default.nix`

4. Use in host config:
```nix
features.myFeature = {
  enable = true;
  option1 = "value";
};
```

## Best Practices

1. **Keep modules focused** - One module per feature/service
2. **Use feature flags** - Control via `host.features.*` options
3. **Platform detection** - Use `pkgs.stdenv.isLinux` / `isDarwin`
4. **Assertions** - Add validation for invalid configurations
5. **Documentation** - Comment complex logic and explain options

## Testing

Test modules with:
```bash
# Check configuration validity
nix flake check

# Build specific configuration
nix build .#nixosConfigurations.jupiter.config.system.build.toplevel
nix build .#darwinConfigurations.Lewiss-MacBook-Pro.system

# Run integration tests (NixOS only)
nix build .#checks.x86_64-linux.basic-boot
nix build .#checks.x86_64-linux.development
```

## Migration Guide

When moving from old to new structure:

1. Update host config to use new format (remove legacy options)
2. Enable features explicitly in `features = { ... }`
3. Remove any direct imports of old module paths
4. Test the configuration builds successfully
