# AI Assistant Guidelines

This document provides guidelines for AI assistants working with this Nix configuration repository.

## System Rebuilds

**CRITICAL**: Never rebuild NixOS or nix-darwin systems directly. Always ask the user to build instead, as you do not have permissions to run commands like:

- `nh os switch`
- `sudo nixos-rebuild switch`
- `sudo darwin-rebuild switch`

Instead, suggest commands for the user to run manually.

## Repository Structure

This is a cross-platform Nix configuration supporting:

- **NixOS** (Linux) - hosts defined in `hosts/`
- **nix-darwin** (macOS) - hosts defined in `hosts/`
- **Home Manager** - user configuration in `home/`
- **Modules** - system-level modules in `modules/`
- **POG Scripts** - CLI tools in `pkgs/pog-scripts/` (run with `nix run .#<name>`)
- **Shell Scripts** - utility scripts in `scripts/`

## Available Tools

### POG Apps (Interactive CLI Tools)

These are modern CLI tools built with pog library:

- `nix run .#new-module` - Create new modules interactively
- `nix run .#update-all` - Update flake inputs and ZSH plugins
- `nix run .#visualize-modules` - Generate module dependency graphs
- `nix run .#setup-cachix` - Configure Cachix binary cache

### Shell Scripts

Located in `scripts/`:

**qBittorrent Diagnostics:**
- `scripts/diagnose-qbittorrent-seeding.sh` - Comprehensive qBittorrent seeding diagnostics
- `scripts/test-qbittorrent-seeding-health.sh` - Full health check with API integration
- `scripts/test-qbittorrent-connectivity.sh` - Network connectivity verification
- `scripts/update-qbittorrent-protonvpn-port.sh` - Update qBittorrent port with VPN forwarding

**ProtonVPN Port Forwarding:**
- `scripts/get-protonvpn-forwarded-port.sh` - NAT-PMP based port detection
- `scripts/find-protonvpn-forwarded-port.sh` - Scan for correct forwarded port
- `scripts/test-protonvpn-port-forwarding.sh` - Test if port forwarding is working

**SSH Performance:**
- `scripts/test-ssh-performance.sh` - Comprehensive SSH performance benchmarking
- `scripts/diagnose-ssh-slowness.sh` - SSH connection troubleshooting

**Network Testing:**
- `scripts/test-vlan2-speed.sh` - Network speed testing through VLAN 2
- `scripts/test-sped.sh` - Simple speed test wrapper

See `scripts/README.md` for detailed documentation of each script.

## Best Practices

1. **Always check existing patterns** before suggesting new code
2. **Use templates** when creating modules: `nix run .#new-module`
3. **Follow conventional commits** - see `docs/DX_GUIDE.md`
4. **Format code** using `nix fmt` or `treefmt`
5. **Check for existing modules** before creating new ones
6. **Document changes** in relevant documentation files

## Common Tasks

### Adding a Package

- Check if it exists in `home/common/apps/` or `modules/nixos/features/`
- Use feature-based configuration when appropriate
- See `docs/FEATURES.md` for feature patterns

### Creating a Module

- Use `nix run .#new-module` for scaffolding
- Follow naming conventions in `docs/reference/architecture.md`
- Add documentation to module options

### Updating Dependencies

- Use `nix run .#update-all` to update everything
- Or manually: `nix flake update`

## Documentation

- **Architecture**: `docs/reference/architecture.md`
- **Features**: `docs/FEATURES.md`
- **DX Guide**: `docs/DX_GUIDE.md`
- **Contributing**: `CONTRIBUTING.md`

## Important Notes

- Never run system rebuild commands
- Always suggest commands for the user to run
- Check documentation before suggesting solutions
- Use existing patterns and conventions
- Format code before suggesting changes
