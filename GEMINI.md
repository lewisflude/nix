# Nix Configuration Project - Gemini Code Assist Rules

This file provides context and rules for Gemini Code Assist when working with this Nix configuration repository.

## Project Overview

This is a cross-platform Nix configuration repository supporting:
- **NixOS** (Linux) - hosts in `hosts/`
- **nix-darwin** (macOS) - hosts in `hosts/`
- **Home Manager** - user configuration in `home/`
- **System Modules** - in `modules/nixos/` and `modules/darwin/`
- **POG Scripts** - interactive CLI tools in `pkgs/pog-scripts/`
- **Shell Scripts** - utility scripts in `scripts/`

## Critical Rules

### Module Placement (MOST IMPORTANT)

When creating or modifying modules, proper placement is critical:

**System-Level** (`modules/nixos/` or `modules/darwin/`):
- System services (systemd, launchd)
- Kernel modules and drivers
- Hardware configuration
- System daemons (running as root)
- Container runtimes (Docker daemon, Podman system service)
- Graphics drivers
- Network configuration (system-wide)
- Boot configuration

**Home-Manager Level** (`home/common/apps/` or `home/{nixos,darwin}/`):
- User applications and CLI tools
- User services (systemd --user)
- Dotfiles and user configuration
- Development tools (LSPs, formatters, linters)
- Desktop applications
- User tray applets
- Shell configuration
- Editor configurations

### Code Style Requirements

1. **NEVER use `with pkgs;` antipattern**
   ```nix
   # ❌ WRONG
   home.packages = with pkgs; [ curl wget tree ];

   # ✅ CORRECT
   home.packages = [ pkgs.curl pkgs.wget pkgs.tree ];
   ```

2. **Use constants from `lib/constants.nix`**
   ```nix
   let
     constants = import ../lib/constants.nix;
   in
   {
     services.myService.port = constants.ports.services.myService;
   }
   ```

3. **Follow conventional commits**
   - See `docs/DX_GUIDE.md` for commit message format
   - Examples: `feat:`, `fix:`, `refactor:`, `docs:`

### Commands You Must NEVER Run

**CRITICAL**: Never rebuild NixOS or nix-darwin systems directly. Always ask the user to build instead:

- `nh os switch`
- `sudo nixos-rebuild switch`
- `sudo darwin-rebuild switch`
- `rm -rf` (especially in system directories)
- `sudo rm`

Instead, suggest commands for the user to run manually.

### Always Format Code

After editing any `.nix` file, always run:
```bash
nix fmt
# or
treefmt
```

## Available Tools

### POG Apps (Interactive CLI Tools)

Run these with `nix run .#<name>`:
- `new-module` - Create new modules interactively
- `update-all` - Update flake inputs and ZSH plugins
- `visualize-modules` - Generate module dependency graphs
- `setup-cachix` - Configure Cachix binary cache

### Shell Scripts

Located in `scripts/` - see `scripts/README.md` for full list:
- **qBittorrent & VPN**: diagnostics, monitoring, port forwarding
- **SSH Performance**: benchmarking and troubleshooting
- **Network Testing**: VLAN speed tests

## Common Antipatterns to Avoid

1. ❌ Container tools in home-manager (use system modules)
2. ❌ System packages duplicated in home config
3. ❌ Hardcoded values (use `lib/constants.nix`)
4. ❌ Using `with pkgs;` (use explicit references)

## Documentation Structure

- **Architecture**: `docs/reference/architecture.md`
- **Features**: `docs/FEATURES.md`
- **DX Guide**: `docs/DX_GUIDE.md`
- **Contributing**: `CONTRIBUTING.md`
- **AI Guidelines**: `CLAUDE.md`

## Decision Checklist

When adding a package or service:

1. Does it require root/system privileges? → System module
2. Does it run as a system service? → System module
3. Is it hardware configuration? → System module
4. Is it a user application? → Home-Manager module
5. Does it configure dotfiles? → Home-Manager module
6. Is it a tray applet? → Home-Manager module

## Best Practices

1. Always check existing patterns before suggesting new code
2. Use templates when creating modules: `nix run .#new-module`
3. Follow conventional commits
4. Format code using `nix fmt` or `treefmt`
5. Check for existing modules before creating new ones
6. Document changes in relevant documentation files
