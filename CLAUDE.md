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
- **`modules/common/`**: Shared system configurations (core packages, development tools, docker)
- **`modules/darwin/`**: macOS-specific modules (system settings, apps, backup)
- **`modules/nixos/`**: Linux-specific modules (desktop environment, audio, graphics, networking)
- **`home/common/`**: User-level configurations (apps, shell, development tools, themes)

### Configuration Variables
- **`config-vars.nix`**: User preferences, theme settings, and system-specific configurations
- Key variables: email, fullName, timezone, editor, shell, theme, language versions

### Development Shells
- **Project-specific**: `nextjs`, `react-native`, `api-backend`
- **Language-specific**: `node`, `python`, `rust`, `go`
- **Purpose-specific**: `web`, `solana`, `devops`
- **Utility**: `shell-selector` for interactive environment selection

## Key Conventions

### Nix Style
- Use 2-space indentation
- Organize attributes logically
- Use meaningful names for attributes and variables
- Follow nixpkgs conventions for packaging

### File Organization
- Host-specific configurations in `hosts/<hostname>/`
- Shared modules in `modules/common/`
- Platform-specific modules in `modules/{darwin,nixos}/`
- User configurations in `home/common/`

### Development Environment Integration
- Use direnv with `.envrc` templates from `shells/envrc-templates/`
- Automatic dependency installation (npm/pnpm for Node.js, pip/poetry for Python)
- Consistent environment variables and aliases across shells

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