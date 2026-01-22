# Scripts Directory

**⚠️ IMPORTANT**: Do not add new scripts to this directory without explicit permission. This directory was intentionally cleaned from 63→21 scripts. For new CLI tools, use POG apps in `pkgs/pog-scripts/` instead of shell scripts.

Utility scripts for NixOS configuration management, diagnostics, automation, and AI tool integration. Scripts are organized by category for easy discovery and maintenance.

## 📂 Directory Structure

```
scripts/
├── hooks/            7 scripts  - Claude Code integration hooks
├── media/            9 scripts  - qBittorrent, VPN, storage monitoring
├── network/          3 scripts  - Network testing and optimization
├── diagnostics/      7 scripts  - System troubleshooting tools
├── validation/       2 scripts  - Configuration validation
└── templates/                  - Script templates for new scripts
```

**Total**: 28 scripts across 5 categories

## 🚀 Quick Start

```bash
# List scripts by category
ls scripts/*/

# Find a script
find scripts/ -name "*vpn*"

# Run a diagnostic
./scripts/diagnostics/diagnose-ssh-slowness.sh hostname

# Validate configuration
./scripts/validation/validate-config.sh

# Test network MTU
sudo ./scripts/network/optimize-mtu.sh
```

## 📚 Categories

### [Hooks](hooks/README.md) - Claude Code Integration (7 scripts)

AI-powered automation hooks for code quality, safety, and context management.

**Key Scripts**:

- `block-dangerous-commands.sh` - Prevents dangerous operations
- `auto-format-nix.sh` - Automatic Nix formatting
- `strict-lint-check.sh` - Enforce coding standards
- `load-context.sh` - Load project context at session start

**Integration**: `.claude/settings.json` (automated)

[📖 Full Documentation](hooks/README.md)

---

### [Media](media/README.md) - qBittorrent & VPN (9 scripts)

Port forwarding, VPN management, and storage monitoring for media services.

**Key Scripts**:

- `protonvpn-natpmp-portforward.sh` - Automated port forwarding (integrated)
- `monitor-protonvpn-portforward.sh` - VPN monitoring
- `verify-qbittorrent-vpn.sh` - Complete verification
- `diagnose-qbittorrent-seeding.sh` - Seeding diagnostics
- `monitor-hdd-storage.sh` - Storage monitoring

**Integration**: NixOS modules in `modules/nixos/services/media-management/`

[📖 Full Documentation](media/README.md)

---

### [Network](network/README.md) - Testing & Optimization (3 scripts)

Network performance testing, MTU optimization, and speed benchmarking.

**Key Scripts**:

- `optimize-mtu.sh` - MTU discovery and optimization ⭐
- `test-sped.sh` - Internet speed test

**Integration**: Standalone diagnostic tools

[📖 Full Documentation](network/README.md)

---

### [Diagnostics](diagnostics/README.md) - Troubleshooting (7 scripts)

Interactive diagnostic tools for identifying system issues.

**Key Scripts**:

- `check-gaming-setup.sh` - Comprehensive gaming configuration validation ⭐
- `check-audio-setup.sh` - PipeWire/WirePlumber audio configuration diagnostics ⭐ NEW
- `diagnose-ssh-slowness.sh` - SSH performance diagnostics
- `test-ssh-performance.sh` - SSH benchmarking
- `check-xfs-features.sh` - XFS feature verification and upgrade suggestions ⭐
- `benchmark-xfs-before-after.sh` - XFS performance benchmarking

**Integration**: Standalone diagnostic tools

[📖 Full Documentation](diagnostics/README.md)

---

### [Validation](validation/README.md) - Configuration Testing (1 script)

Validate system configuration before deployment.

**Key Scripts**:

- `validate-config.sh` - Validate Nix configuration

**Integration**: Standalone validation tools (use in pre-commit hooks)

[📖 Full Documentation](validation/README.md)

---

## 🔍 Finding the Right Script

### By Use Case

| I need to... | Script | Category |
|--------------|--------|----------|
| Check gaming setup and optimizations | `check-gaming-setup.sh` | diagnostics |
| Check VPN port forwarding | `monitor-protonvpn-portforward.sh` | media |
| Diagnose slow SSH | `diagnose-ssh-slowness.sh` | diagnostics |
| Check XFS filesystem features | `check-xfs-features.sh` | diagnostics |
| Test network speed | `test-sped.sh` | network |
| Validate config before rebuild | `validate-config.sh` | validation |
| Verify qBittorrent setup | `verify-qbittorrent-vpn.sh` | media |
| Monitor HDD storage | `monitor-hdd-storage.sh` | media |
| Benchmark SSH performance | `test-ssh-performance.sh` | diagnostics |
| Diagnose qBittorrent seeding | `diagnose-qbittorrent-seeding.sh` | media |

### By Integration Status

**Automated (Integrated into System)** (12 scripts):

- **Claude Code Hooks** (5) → `.claude/settings.json`
  - All hooks run automatically during Claude Code sessions
- **qBittorrent/VPN** (7) → NixOS modules
  - `protonvpn-natpmp-portforward.sh` - systemd service
  - `show-protonvpn-port.sh` - system package
  - `monitor-protonvpn-portforward.sh` - system package
  - `verify-qbittorrent-vpn.sh` - system package
  - `test-vpn-port-forwarding.sh` - system package
  - `diagnose-qbittorrent-seeding.sh` - system package
  - `test-qbittorrent-seeding-health.sh` - system package

**Standalone (Manual Execution)** (11 scripts):

- Diagnostics (4), network tests (1), validation (1), templates (1)
- Run these manually for troubleshooting and testing

## 🛠️ Development

### Creating New Scripts

Use the interactive script generator:

```bash
# Create a new script from template
nix run .#new-script

# Prompts for:
# - Category: hooks, media, network, diagnostics, validation
# - Name: my-awesome-script
# - Description: What it does
# - Integration: none, nix-module, claude-hook, systemd
```

Templates are available in `scripts/templates/`.

### Script Standards

All scripts follow these standards:

1. **Standard header format** with metadata
2. **Proper shebang**: `#!/usr/bin/env bash`
3. **Error handling**: `set -euo pipefail`
4. **Help flag**: `--help` shows usage
5. **Exit codes**: 0=success, 1=error, 2=blocked/invalid
6. **Logging**: Color-coded output (✓ ✗ ⚠️ ℹ️)

See `scripts/templates/generic-script.sh` for the standard template.

### Testing Scripts

```bash
# Test a specific script
./scripts/validation/validate-config.sh

# Test all hooks
for hook in scripts/hooks/*.sh; do
  echo "Testing $hook..."
  "$hook" --help
done

```

## 📖 Documentation

- **Category READMEs**: Each category has detailed documentation
  - [hooks/README.md](hooks/README.md) - Claude Code hooks
  - [media/README.md](media/README.md) - qBittorrent & VPN
  - [network/README.md](network/README.md) - Network testing
  - [diagnostics/README.md](diagnostics/README.md) - Troubleshooting
  - [validation/README.md](validation/README.md) - Validation tools

- **Guides**:
  - [qBittorrent Setup Guide](../docs/QBITTORRENT_GUIDE.md) - Complete setup
  - [ProtonVPN Port Forwarding](../docs/PROTONVPN_PORT_FORWARDING_SETUP.md) - VPN config
  - [AI Assistant Guidelines](../CLAUDE.md) - AI assistant guidelines

## 🔧 Common Tasks

### Troubleshooting qBittorrent VPN

```bash
# Complete verification
./scripts/media/verify-qbittorrent-vpn.sh

# Monitor status
./scripts/media/monitor-protonvpn-portforward.sh

# Check port forwarding
./scripts/media/test-vpn-port-forwarding.sh

# Diagnose seeding issues
./scripts/media/diagnose-qbittorrent-seeding.sh

# Full health check
./scripts/media/test-qbittorrent-seeding-health.sh

# Test connectivity
./scripts/media/test-qbittorrent-connectivity.sh
```

### Testing Network Performance

```bash
# Test speeds
./scripts/network/test-sped.sh

# Compare VPN vs regular
./scripts/network/test-sped.sh  # Regular
sudo ip netns exec qbt ./scripts/network/test-sped.sh  # VPN
```

### Diagnosing SSH Slowness

```bash
# Quick diagnosis
./scripts/diagnostics/diagnose-ssh-slowness.sh jupiter

# Full benchmark
./scripts/diagnostics/test-ssh-performance.sh jupiter

# Apply recommended config to ~/.ssh/config
```

### Checking XFS Filesystems

```bash
# Check all XFS filesystems for modern features
./scripts/diagnostics/check-xfs-features.sh

# Shows status of: bigtime, inobtcount, reflink, rmapbt, crc, finobt
# Provides upgrade instructions for features that can be enabled
```

### Checking Gaming Setup

```bash
# Comprehensive gaming configuration validation
./scripts/diagnostics/check-gaming-setup.sh

# Validates:
# - Steam installation and dev config (shader compilation, HTTP2)
# - Kernel parameters (vm.max_map_count)
# - CPU governor and performance settings
# - GameMode and Ananicy-cpp status
# - Vulkan and graphics drivers
# - Proton-GE installation
# - Steam Input and uinput security
# - Network optimizations (TCP BBR)
# - Security settings (hidepid that breaks anti-cheat)
```

### Before System Rebuild

```bash
# Validate configuration
./scripts/validation/validate-config.sh

# If valid, rebuild
nh os switch
```

## ⚙️ Integration with System

### Automated Scripts (systemd)

These scripts run automatically via systemd:

```bash
# Check port forwarding timer
systemctl status protonvpn-portforward.timer
systemctl list-timers | grep protonvpn

# View logs
journalctl -u protonvpn-portforward.service -f
```

### Configured in NixOS

Port forwarding automation:

```nix
host.services.mediaManagement.qbittorrent.vpn.portForwarding = {
  enable = true;
  renewInterval = "45min";
  gateway = "10.2.0.1";
};
```

### Claude Code Hooks

Hooks run automatically during Claude Code sessions. Test specific hook:

```bash
echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | \
  ./scripts/hooks/block-dangerous-commands.sh
```

## 🚨 Important Notes

### Backward Compatibility

Scripts in the root directory are **symlinks** to their category locations:

```bash
scripts/load-context.sh → scripts/hooks/load-context.sh
scripts/optimize-mtu.sh → scripts/network/optimize-mtu.sh
```

This maintains backward compatibility with existing references. Always prefer using the category paths for new code.

### Never Run These Directly

Some scripts are integrated into the system and should not be run manually:

- `protonvpn-natpmp-portforward.sh` - Runs via systemd timer
- Claude Code hooks - Run automatically by Claude Code

Others are safe to run anytime:

- All diagnostic scripts
- Network testing scripts
- Validation scripts

## 📊 Dependencies

Common dependencies for scripts:

- `bash` - Shell interpreter
- `coreutils` - Basic utilities
- `iproute2` - Network namespace operations
- `iputils` - ping, nc
- `curl` - HTTP requests
- `jq` - JSON processing (for hooks)

Install missing dependencies:

```bash
# For quick testing of individual tools
, tool-name

# For a shell with multiple dependencies
nix-shell -p bash coreutils iproute2 iputils curl jq
```

Category-specific dependencies are listed in each category's README.

## 🔗 See Also

- [POG Scripts](../pkgs/pog-scripts/) - Interactive CLI tools (`nix run .#<name>`)
- [Templates](../templates/) - Module templates
- [AI Guidelines](../CLAUDE.md) - AI assistant rules
- [Contributing](../CONTRIBUTING.md) - Development workflow

---

**Last Updated**: 2025-01-21
**Scripts**: 27 total (7 hooks, 9 media, 3 network, 4 diagnostics, 2 validation, 1 template)
**Organization**: Cleaned and optimized (removed 42 obsolete scripts)
