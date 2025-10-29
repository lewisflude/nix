# Modules Index

This directory contains NixOS, nix-darwin, and home-manager modules for this configuration.

## Directory Structure

- **`darwin/`** - nix-darwin specific modules for macOS
- **`nixos/`** - NixOS specific modules for Linux
- **`shared/`** - Shared modules used across both platforms
- **`examples/`** - Example module templates

## Module Categories

### NixOS Modules (`nixos/`)

- **Core** - Base system configuration (security, networking, etc.)
- **Desktop** - Desktop environment and window manager configuration
- **Services** - System services, containers, media management
- **Features** - Optional features (virtualization, development tools, etc.)

### Darwin Modules (`darwin/`)

- System preferences and security settings
- macOS-specific application configuration
- Homebrew integration

### Shared Modules (`shared/`)

- Cross-platform modules that work on both NixOS and Darwin
- Common configuration patterns
- Host options and system-level configuration

## Usage

Modules are automatically imported based on the host configuration in `hosts/`.
Each module is self-contained and can be enabled/disabled through the host's configuration.

For creating new modules, see the templates in the `templates/` directory or use the `new-module` script:

```bash
nix run .#new-module
```

## Documentation

For more details on module structure and conventions, see:
- `../docs/DX_GUIDE.md` - Development experience guide
- `../CONTRIBUTING.md` - Contributing guidelines
- `../templates/` - Module templates
