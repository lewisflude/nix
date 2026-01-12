# Nix Configuration Project - Memory Bank

## Project Overview

This is a cross-platform Nix configuration repository that manages system configurations for multiple hosts using Nix Flakes, Home Manager, NixOS, and nix-darwin.

**Purpose**: Declarative, reproducible system configuration across Linux (NixOS) and macOS (nix-darwin) machines with unified home-manager user environments.

## Core Features

### Multi-Platform Support

- **NixOS** - Linux system configurations
- **nix-darwin** - macOS system configurations
- **Home Manager** - Cross-platform user environment management
- **Nix Flakes** - Modern dependency management and reproducibility

### Host Management

Multiple hosts with specific configurations:

- Desktop workstations (gaming, audio production)
- Servers (media, torrenting, home automation)
- Development machines
- Each host defined in `hosts/<hostname>/`

### Feature-Based Configuration

Uses feature flags for modular configuration:

- `features.gaming.enable` - Gaming setup (Steam, Lutris, etc.)
- `features.audio.enable` - Audio production (JACK, PipeWire, plugins)
- `features.development.enable` - Development tools
- `features.media.enable` - Media server applications
- See `docs/FEATURES.md` for complete list

### Automated Tools

**POG Scripts** (Interactive CLI tools in `pkgs/pog-scripts/`):

- `new-module` - Scaffold new configuration modules
- `update-all` - Update all dependencies (flake inputs, ZSH plugins)
- `visualize-modules` - Generate module dependency graphs
- `setup-cachix` - Configure binary cache

**Shell Scripts** (`scripts/`):

- qBittorrent diagnostics and monitoring
- VPN port forwarding automation
- SSH performance testing
- Network diagnostics
- Configuration validation

## Target Users

**Primary User**: System administrator managing personal infrastructure with:

- Multiple NixOS and macOS machines
- Complex requirements (gaming, audio production, media serving)
- Need for reproducibility and version control
- Preference for declarative configuration

**Secondary Users**: Developers and AI coding assistants helping maintain and extend the configuration.

## Technical Highlights

### Architecture Principles

1. **Separation of Concerns**: System vs user configuration strictly separated
2. **Modularity**: Feature-based modules that can be enabled/disabled per host
3. **Cross-Platform**: Shared modules work on both NixOS and nix-darwin
4. **Type Safety**: Nix language provides type checking and validation
5. **Reproducibility**: Flake lock ensures identical builds across machines

### Key Technologies

- **Nix Flakes** - Dependency management and hermetic builds
- **Home Manager** - User environment and dotfile management
- **nixpkgs** - Package repository (follows unstable for latest packages)
- **POG** - Rust-based interactive CLI framework for user-facing tools

### Configuration Structure

```
.
├── flake.nix              # Main flake definition and outputs
├── hosts/                 # Host-specific configurations
│   ├── <hostname>/        # Per-host configuration
│   │   ├── default.nix    # Host configuration entry point
│   │   └── hardware.nix   # Hardware-specific settings
├── home/                  # Home Manager configurations
│   ├── common/apps/       # Cross-platform user applications
│   ├── nixos/             # Linux-specific home config
│   └── darwin/            # macOS-specific home config
├── modules/               # Reusable modules
│   ├── nixos/             # NixOS system modules
│   │   ├── features/      # Feature modules (gaming, audio, etc.)
│   │   └── services/      # System services
│   ├── darwin/            # nix-darwin system modules
│   └── shared/features/   # Cross-platform features
├── pkgs/                  # Custom packages
│   └── pog-scripts/       # Interactive POG applications
├── scripts/               # Shell utility scripts
├── docs/                  # Project documentation
└── lib/                   # Helper functions and constants
    ├── constants.nix      # Port numbers, paths, etc.
    └── validators.nix     # Validation helpers
```

## Current Development Focus

### Active Areas

- Audio production environment optimization (PipeWire, JACK, VST plugins)
- Media server reliability (qBittorrent, *arr apps, Jellyfin)
- VPN integration and port forwarding automation
- Gaming configuration (Steam, Proton, anti-cheat compatibility)

### Recent Improvements

- Feature-based configuration system overhaul
- Module placement standardization
- Linting and formatting automation
- Documentation expansion and organization
- POG-based tooling for better UX

### Ongoing Challenges

- Balancing bleeding-edge packages with stability
- Cross-platform consistency (NixOS vs nix-darwin differences)
- Managing complexity as configuration grows
- Performance optimization for large flake evaluations

## Success Metrics

**Reliability**: Systems rebuild successfully without manual intervention
**Reproducibility**: Identical configurations across multiple machines
**Maintainability**: Clear module organization and comprehensive documentation
**Developer Experience**: Tools and automation reduce cognitive load
**Safety**: Hooks and validation prevent destructive operations

## Related Documentation

- `CLAUDE.md` - AI assistant guidelines (critical for understanding conventions)
- `CONVENTIONS.md` - Coding standards and patterns
- `docs/reference/architecture.md` - Detailed architecture guide
- `docs/FEATURES.md` - Feature flag system documentation
- `docs/DX_GUIDE.md` - Development experience and workflow guide
- `docs/TODO.md` - Future refactoring tasks and improvements
- `docs/QBITTORRENT_GUIDE.md` - Media server setup
- `docs/SOPS_GUIDE.md` - Secret management guide
