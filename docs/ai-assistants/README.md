# AI Assistant Guide

This guide provides context and instructions for AI assistants (Claude, ChatGPT, Cursor AI) working with this Nix configuration repository.

## 🏗️ Project Overview

This is a **cross-platform Nix configuration** using flakes, supporting both **macOS** (nix-darwin) and **Linux** (NixOS) with shared Home Manager configurations and reproducible development environments.

### Key Architecture Components

| Component | Path | Purpose |
|-----------|------|---------|
| **Flake Entry** | `flake.nix` | Main configuration defining inputs/outputs |
| **Host Configs** | `hosts/` | Per-machine system configurations |
| **System Modules** | `modules/` | Reusable system-level configurations |
| **User Configs** | `home/` | Cross-platform Home Manager configurations |
| **Dev Environments** | `shells/` | Reproducible development shells |
| **Secrets** | `secrets/` | SOPS-encrypted secrets with age keys |
| **Utilities** | `lib/` | Helper functions and utilities |
| **Scripts** | `scripts/` | Maintenance, build, and utility scripts |

### Platform Support
- **macOS:** nix-darwin with Homebrew integration
- **Linux:** NixOS with Niri compositor  
- **Shared:** Home Manager for user-level configurations

## 🔧 Common Commands Reference

### System Management
```bash
# Build and switch system
sudo darwin-rebuild switch --flake ~/.config/nix#<hostname>  # macOS
sudo nixos-rebuild switch --flake ~/.config/nix#<hostname>   # Linux

# Test build without switching
darwin-rebuild build --flake ~/.config/nix#<hostname>        # macOS
nixos-rebuild build --flake ~/.config/nix#<hostname>         # Linux

# Update and maintenance
nix flake update                    # Update all flake inputs
nix fmt                            # Format Nix code
nix flake check                    # Verify builds work
nix-collect-garbage -d             # Clean up old generations
nix store optimise                 # Optimize Nix store
```

### Development Environments
```bash
# Interactive shell selector
nix develop ~/.config/nix#shell-selector
select_dev_shell

# Direct shell usage
nix develop ~/.config/nix#node          # Node.js/TypeScript
nix develop ~/.config/nix#python        # Python with pip/poetry
nix develop ~/.config/nix#rust          # Rust with cargo
nix develop ~/.config/nix#go            # Go development
nix develop ~/.config/nix#web           # Full-stack web development
nix develop ~/.config/nix#nextjs        # Next.js projects  
nix develop ~/.config/nix#react-native  # Mobile development
nix develop ~/.config/nix#api-backend   # Backend API development
nix develop ~/.config/nix#devops        # DevOps/Infrastructure

# Project-based with direnv
cp ~/.config/nix/shells/envrc-templates/<template> .envrc
direnv allow
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

## 📐 Code Organization Patterns

### Module Structure & Platform Separation

#### System Modules (`modules/`)

```
modules/
├── shared/           # Pure cross-platform system configurations
│   ├── core.nix      # Cross-platform Nix settings 
│   ├── sops.nix      # Secrets management
│   ├── dev.nix       # Development tools
│   └── docker.nix    # Containerization
├── darwin/           # macOS-specific system modules
│   ├── nix.nix       # macOS Nix configuration
│   ├── apps.nix      # Homebrew/App Store apps
│   └── system.nix    # macOS system settings
└── nixos/            # Linux-specific system modules
    ├── core/         # Essential system modules
    ├── desktop/      # UI & desktop environment
    ├── hardware/     # Hardware-specific configs
    ├── services/     # Background services  
    ├── development/  # Dev environments & virtualization
    └── system/       # System configuration & management
```

#### Home Manager Structure (`home/`)

```
home/
├── common/           # Pure cross-platform user configurations
│   ├── apps/         # Cross-platform applications
│   ├── development/  # Language-specific dev tools
│   ├── shell/        # Shell configuration
│   └── system/       # Cross-platform system integration
├── darwin/           # macOS-specific user configs
│   ├── apps.nix      # macOS-specific applications
│   └── mcp.nix       # Model Context Protocol servers
└── nixos/            # Linux-specific user configs
    ├── browser.nix   # Web browser configuration
    ├── waybar.nix    # Status bar  
    └── system/       # Linux system integration
```

### Platform Detection System

**Use centralized helpers** from `lib/functions.nix`:

```nix
let
  platformLib = import ../../lib/functions.nix { inherit lib system; };
in
{
  # Conditional packages
  home.packages = platformLib.platformPackages [linuxPackages] [darwinPackages];
  
  # Dynamic paths
  home.homeDirectory = platformLib.homeDir username;
  
  # Platform detection
  services.someService = platformLib.mkIf platformLib.isLinux { enable = true; };
}
```

**Available Helper Functions:**
- `isLinux`, `isDarwin`, `isAarch64`, `isX86_64` - Platform detection
- `platformPackages` - Conditional package inclusion  
- `platformModules` - Conditional module imports
- `homeDir`, `configDir`, `dataDir`, `cacheDir` - Dynamic path helpers
- `rootGroup` - Platform-specific root group (`wheel` vs `root`)
- `systemRebuildCommand` - Platform-specific rebuild commands

## 🎯 Best Practices for AI Assistants

### Platform Separation Rules
1. **Common modules** should contain ONLY cross-platform configurations
2. **Platform-specific logic** must be in `darwin/` or `nixos/` directories
3. **Use centralized helpers** from `lib/functions.nix` for platform detection
4. **Avoid conditional imports** in common modules - use platform-specific modules instead

### Module Development Guidelines  
1. **Import platform helpers:** Always use `lib/functions.nix` for consistency
2. **Single responsibility:** Each module should handle one specific area
3. **Avoid duplication:** Check for existing package installations before adding new ones
4. **Dynamic paths:** Use `platformLib.homeDir`, `platformLib.dataDir` instead of hardcoded paths
5. **Clear naming:** Use descriptive names like `desktop-environment.nix` not `de.nix`

### File Organization Principles
- Host-specific configurations in `hosts/<hostname>/`
- Pure cross-platform modules in `modules/shared/` and `home/common/`
- Platform-specific modules in `modules/{darwin,nixos}/` and `home/{darwin,nixos}/`
- Development tools organized by purpose in `home/common/development/`
- System integration in platform-specific directories

### Code Quality Standards
- **Format:** Always run `nix fmt` before committing
- **Validation:** Use `nix flake check` to ensure builds succeed  
- **Documentation:** Document non-obvious configuration choices
- **Testing:** Test builds before committing (`nixos-rebuild build` / `darwin-rebuild build`)
- **Style:** Follow consistent 2-space indentation and logical attribute organization

## 🚨 Common Issues & Solutions

### Build Failures
- **Check logs:** `journalctl -u nix-daemon` (Linux) or system logs (macOS)
- **Permission issues:** Ensure user is in `nix-users` group
- **Path issues:** Verify relative paths are correct after file moves
- **Module conflicts:** Check for duplicate imports or conflicting options

### Development Environment Issues
- **Missing dependencies:** Check if tools are included in shell definition
- **Environment variables:** Verify shellHook configuration in `shells/`
- **Direnv not working:** Ensure `direnv allow` is run in project directory
- **Node.js version conflicts:** Use the version specified in shells config (Node.js 24)

### Home Manager Issues
- **State conflicts:** Use `--backup-extension .bak` flag
- **Platform detection:** Ensure platform helpers are used correctly
- **Path references:** Check that file paths are correct for the platform

## 📚 External Dependencies

### Key Flake Inputs
- **nixpkgs:** Main package repository
- **nix-darwin:** macOS system configuration  
- **home-manager:** User environment management
- **sops-nix:** Secrets management
- **catppuccin:** Consistent theming
- **niri:** Wayland compositor (Linux)
- **cursor:** Cursor editor integration

### Integration Points
- **Homebrew:** Managed through nix-homebrew (macOS)
- **systemd:** Service management (Linux)
- **Niri compositor:** Window management (Linux)
- **Age/SOPS:** Secrets encryption
- **direnv:** Automatic environment loading

---

For more detailed information, see:
- [Project Context](project-context.md) - Deep dive into architecture
- [Common Tasks](common-tasks.md) - Frequent development patterns and tasks
