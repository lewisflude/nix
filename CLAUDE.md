# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a cross-platform Nix configuration using flakes, supporting both macOS (nix-darwin) and Linux (NixOS) with shared Home Manager configurations and reproducible development environments.

### Key Components
- **Flake-based configuration** (`flake.nix`): Main entry point defining inputs, outputs, and system configurations
- **Host configurations** (`hosts/`): Per-machine configurations for different systems
- **System modules** (`modules/`): Reusable system-level configurations split by platform
- **Home Manager** (`home/`): Cross-platform user environment configurations
- **Development shells** (`shells/`): Reproducible development environments for various tech stacks
- **Secrets management** (`secrets/`): SOPS-encrypted secrets with age keys

### Platform Support
- **macOS**: Uses nix-darwin with Homebrew integration
- **Linux**: Uses NixOS with Hyprland/Niri compositors
- **Shared**: Home Manager for user-level configurations

## Common Commands

### System Management
```bash
# Build and switch system (macOS)
sudo darwin-rebuild switch --flake ~/.config/nix#Lewiss-MacBook-Pro

# Build and switch system (Linux)
sudo nixos-rebuild switch --flake ~/.config/nix#jupiter

# Update flake inputs
nix flake update

# Format Nix code
nix fmt

# Clean up old generations
nix-collect-garbage -d
nix store optimise
```

### Development Environments
```bash
# Interactive shell selector
nix develop ~/.config/nix#shell-selector
select_dev_shell

# Common development shells
nix develop ~/.config/nix#node          # Node.js/TypeScript
nix develop ~/.config/nix#python        # Python
nix develop ~/.config/nix#rust          # Rust
nix develop ~/.config/nix#go            # Go
nix develop ~/.config/nix#web           # Full-stack web
nix develop ~/.config/nix#nextjs        # Next.js projects
nix develop ~/.config/nix#react-native  # Mobile development
nix develop ~/.config/nix#api-backend   # Backend APIs
nix develop ~/.config/nix#devops        # DevOps/Infrastructure
```

### Secrets Management
```bash
# Generate age key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Edit secrets
cd ~/.config/nix/secrets
sops secrets.yaml
```

## Code Organization

### Module Structure

#### System Modules (`modules/`)
- **`modules/common/`**: Pure cross-platform system configurations only
  - `core.nix` - Cross-platform Nix settings and nixpkgs config
  - `sops.nix` - Cross-platform SOPS package installation
  - `dev.nix` - Development tools and environments
  - `docker.nix` - Containerization support
- **`modules/darwin/`**: macOS-specific system modules
  - `nix.nix` - Darwin-specific Nix configuration and custom settings
  - `sops.nix` - macOS secrets management (wheel group)
  - `apps.nix` - Homebrew and App Store applications
  - `system.nix` - macOS system settings and preferences
  - `backup.nix` - Time Machine and backup configurations
- **`modules/nixos/`**: Linux-specific system modules
  - `nix.nix` - NixOS-specific Nix configuration and systemd integration
  - `sops.nix` - Linux secrets management (root group)
  - `boot.nix` - Boot configuration and kernel settings
  - `desktop-environment.nix` - Wayland/X11 desktop environment
  - `graphics.nix` - GPU drivers and graphics configuration

#### Home Manager Structure (`home/`)
- **`home/common/`**: Pure cross-platform user configurations only
  - `apps.nix` - Cross-platform applications and tools
  - `shell.nix` - Shell configuration with platform helpers
  - `terminal.nix` - Terminal applications and settings
  - `theme.nix` - Color schemes and fonts (with Linux conditionals)
  - `development/` - Language-specific development tools
  - `system/` - Cross-platform system integration (YubiKey, video conferencing)
- **`home/darwin/`**: macOS-specific user configurations
  - `apps.nix` - macOS-specific applications
  - `mcp.nix` - Model Context Protocol servers with dynamic paths
  - `yubikey.nix` - macOS YubiKey integration
- **`home/nixos/`**: Linux-specific user configurations
  - `system/` - Linux system integration (USB, keyboard, gaming, auto-update)
  - `browser.nix` - Web browser configuration
  - `hyprland-packages.nix` - Hyprland desktop environment packages
  - `waybar.nix` - Status bar configuration
  - `mako.nix` - Notification daemon

### Platform Detection System

#### Centralized Helpers (`lib/functions.nix`)
```nix
let
  platformLib = import ../../lib/functions.nix { inherit lib system; };
in
{
  # Use consistent helpers throughout configuration
  home.packages = platformLib.platformPackages [linuxPackages] [darwinPackages];
  home.homeDirectory = platformLib.homeDir username;
}
```

**Available Helpers:**
- `isLinux`, `isDarwin`, `isAarch64`, `isX86_64` - Platform detection
- `platformPackages` - Conditional package inclusion
- `platformModules` - Conditional module imports  
- `homeDir`, `configDir`, `dataDir`, `cacheDir` - Dynamic path helpers
- `rootGroup` - Platform-specific root group
- `systemRebuildCommand` - Platform-specific rebuild commands

### Configuration Variables
- **`config-vars.nix`**: User preferences, theme settings, and system-specific configurations
- Key variables: email, fullName, timezone, editor, shell, theme, language versions

### Development Shells
- **Project-specific**: `nextjs`, `react-native`, `api-backend`
- **Language-specific**: `node`, `python`, `rust`, `go`
- **Purpose-specific**: `web`, `solana`, `devops`
- **Utility**: `shell-selector` for interactive environment selection

## Best Practices

### Platform Separation Rules
1. **Common modules** should contain ONLY cross-platform configurations
2. **Platform-specific logic** must be in `darwin/` or `nixos/` directories
3. **Use centralized helpers** from `lib/functions.nix` for platform detection
4. **Avoid conditional imports** in common modules - use platform-specific modules instead

### Module Development Guidelines
1. **Import platform helpers**: Always use `lib/functions.nix` for consistency
2. **Single responsibility**: Each module should handle one specific area
3. **Avoid duplication**: Check for existing package installations before adding new ones
4. **Dynamic paths**: Use `platformLib.homeDir`, `platformLib.dataDir` instead of hardcoded paths
5. **Clear naming**: Use descriptive names like `desktop-environment.nix` not `de.nix`

### File Organization Principles
- Host-specific configurations in `hosts/<hostname>/`
- Pure cross-platform modules in `modules/common/` and `home/common/`
- Platform-specific modules in `modules/{darwin,nixos}/` and `home/{darwin,nixos}/`
- Development tools organized by purpose in `home/common/development/`
- System integration in `home/{platform}/system/`

### Development Environment Integration
- Use direnv with `.envrc` templates from `shells/envrc-templates/`
- Automatic dependency installation (npm/pnpm for Node.js, pip/poetry for Python)
- Consistent environment variables and aliases across shells
- Platform-specific tools included via `platformLib.platformPackages`

## Testing Changes

### Build Testing
```bash
# Test build without switching (macOS)
darwin-rebuild build --flake ~/.config/nix#Lewiss-MacBook-Pro

# Test build without switching (Linux)
nixos-rebuild build --flake ~/.config/nix#jupiter

# Test Home Manager changes
home-manager switch --flake ~/.config/nix#<hostname>
```

### Shell Testing
```bash
# Test specific development shell
nix develop ~/.config/nix#<shell-name>

# Test with direnv
cd /path/to/project
cp ~/.config/nix/shells/envrc-templates/<template> .envrc
direnv allow
```

## External Dependencies

### Key Flake Inputs
- **nixpkgs**: Main package repository
- **nix-darwin**: macOS system configuration
- **home-manager**: User environment management
- **sops-nix**: Secrets management
- **catppuccin**: Consistent theming
- **hyprland**: Wayland compositor (Linux)
- **cursor**: Cursor editor integration

### Homebrew Integration (macOS)
- Managed through nix-homebrew
- Configuration in `modules/darwin/apps.nix`
- Taps: homebrew-cask, homebrew-core, homebrew-nx, etc.

## Troubleshooting

### Common Issues
- **Build failures**: Check `journalctl -u nix-daemon` on Linux
- **Permission issues**: Ensure user is in `nix-users` group
- **Home Manager conflicts**: Use `--backup-extension .bak` flag
- **Direnv not working**: Ensure `direnv allow` is run in project directory

### Development Shell Issues
- **Missing dependencies**: Check if tools are included in the shell definition
- **Environment variables**: Verify shellHook configuration
- **Node.js version conflicts**: Use the version specified in shells configuration (Node.js 24)