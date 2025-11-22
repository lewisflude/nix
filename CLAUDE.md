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

**qBittorrent & VPN:**

- `scripts/diagnose-qbittorrent-seeding.sh` - Comprehensive qBittorrent seeding diagnostics
- `scripts/test-qbittorrent-seeding-health.sh` - Full health check with API integration
- `scripts/test-qbittorrent-connectivity.sh` - Network connectivity verification
- `scripts/protonvpn-natpmp-portforward.sh` - Automated NAT-PMP port forwarding
- `scripts/monitor-protonvpn-portforward.sh` - Monitor VPN and port forwarding status
- `scripts/verify-qbittorrent-vpn.sh` - Complete verification following setup guide
- `scripts/test-vpn-port-forwarding.sh` - Quick port forwarding status check
- `scripts/monitor-hdd-storage.sh` - Monitor HDD storage usage and health

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

## Module Placement Guidelines

When creating or modifying modules, follow these rules to maintain proper separation between home-manager and system configuration:

### System-Level (NixOS/nix-darwin)

Place in `modules/nixos/` or `modules/darwin/`:

**Required for System Level**:

- System services (systemd, launchd)
- Kernel modules and drivers
- Hardware configuration
- System daemons (running as root)
- Container runtimes (Docker daemon, Podman system service)
- Graphics drivers
- Network configuration (system-wide)
- Boot configuration

**Examples**:

```nix
# ✅ CORRECT: modules/nixos/features/virtualisation.nix
virtualisation.podman.enable = true;

# ✅ CORRECT: modules/nixos/features/desktop/graphics.nix
hardware.graphics.extraPackages = [ pkgs.mesa ];
```

### Home-Manager Level

Place in `home/common/apps/` or `home/{nixos,darwin}/`:

**Required for Home-Manager**:

- User applications and CLI tools
- User services (systemd --user)
- Dotfiles and user configuration
- Development tools (LSPs, formatters, linters)
- Desktop applications
- User tray applets
- Shell configuration
- Editor configurations

**Examples**:

```nix
# ✅ CORRECT: home/nixos/hardware-tools/audio.nix
home.packages = [ pkgs.pwvucontrol pkgs.playerctl ];

# ✅ CORRECT: home/common/apps/helix.nix
programs.helix.enable = true;
```

### Common Antipatterns to Avoid

#### ❌ WRONG: Container Tools in Home-Manager

```nix
# ❌ WRONG - Don't do this
home.packages = [ pkgs.podman pkgs.podman-compose ];
```

**Fix**: Container runtimes belong at system-level.

#### ❌ WRONG: System Packages Duplicated in Home

```nix
# ❌ WRONG - Don't do this
home.packages = [ pkgs.vulkan-tools pkgs.mesa-demos ];
```

**Fix**: Graphics libraries should only be in system config.

#### ❌ WRONG: Hardcoded Values in Modules

```nix
# ❌ WRONG - Don't do this
time.timeZone = "Europe/London";
```

**Fix**: Use per-host configuration or constants from `lib/constants.nix`.

#### ❌ WRONG: Using 'with pkgs;'

```nix
# ❌ WRONG - Antipattern
home.packages = with pkgs; [ curl wget tree ];
```

**Fix**: Use explicit package references:

```nix
# ✅ CORRECT - Modern pattern
home.packages = [ pkgs.curl pkgs.wget pkgs.tree ];
```

### Decision Checklist

When adding a package or service:

1. **Does it require root/system privileges?** → System module
2. **Does it run as a system service?** → System module
3. **Is it hardware configuration?** → System module
4. **Is it a user application?** → Home-Manager module
5. **Does it configure dotfiles?** → Home-Manager module
6. **Is it a tray applet?** → Home-Manager module

### Module Organization

- **System Services**: `modules/nixos/services/` or `modules/darwin/`
- **User Applications**: `home/common/apps/` or `home/{nixos,darwin}/apps/`
- **Features**: `modules/shared/features/` or `modules/nixos/features/`
- **Hardware**: `modules/nixos/hardware/`

### Using New Infrastructure

**Constants**:

```nix
let
  constants = import ../lib/constants.nix;
in
{
  services.myService.port = constants.ports.services.myService;
}
```

**Validators**:

```nix
let
  validators = import ../lib/validators.nix { inherit lib; };
in
{
  assertions = [
    (validators.assertValidPort cfg.port "service-name")
  ];
}
```

## Documentation

- **Architecture**: `docs/reference/architecture.md`
- **Features**: `docs/FEATURES.md`
- **DX Guide**: `docs/DX_GUIDE.md`
- **Contributing**: `CONTRIBUTING.md`
- **qBittorrent Setup**: `docs/QBITTORRENT_GUIDE.md` - Complete setup, optimization, and troubleshooting
- **ProtonVPN Port Forwarding**: `docs/PROTONVPN_PORT_FORWARDING_SETUP.md` - Detailed VPN configuration
- **SOPS Secret Management**: `docs/SOPS_GUIDE.md` - Comprehensive secrets management, key rotation, and best practices
- **Refactoring Patterns**: `docs/reference/REFACTORING_EXAMPLES.md` - Examples of over-engineering to avoid

## Important Notes

- Never run system rebuild commands
- Always suggest commands for the user to run
- Check documentation before suggesting solutions
- Use existing patterns and conventions
- Format code before suggesting changes
