# Scripts Directory

Utility scripts for NixOS configuration management, diagnostics, automation, and AI tool integration. Scripts are organized by category for easy discovery and maintenance.

## 📂 Directory Structure

```
scripts/
├── hooks/            7 scripts  - Claude Code integration hooks
├── media/            9 scripts  - qBittorrent, VPN, storage monitoring
├── network/          3 scripts  - Network testing and optimization
├── diagnostics/      3 scripts  - System troubleshooting tools
├── validation/       2 scripts  - Configuration validation
└── templates/                  - Script templates for new scripts
```

**Total**: 24 scripts across 5 categories

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
- `test-vlan2-speed.sh` - VLAN 2 speed testing
- `test-sped.sh` - Internet speed test

**Integration**: Standalone diagnostic tools

[📖 Full Documentation](network/README.md)

---

### [Diagnostics](diagnostics/README.md) - Troubleshooting (3 scripts)

Interactive diagnostic tools for identifying system issues.

**Key Scripts**:

- `diagnose-ssh-slowness.sh` - SSH performance diagnostics
- `test-ssh-performance.sh` - SSH benchmarking
- `diagnose-steam-audio.sh` - Steam/Proton audio issues

**Integration**: Standalone diagnostic tools

[📖 Full Documentation](diagnostics/README.md)

---

### [Validation](validation/README.md) - Configuration Testing (2 scripts)

Validate system configuration and AI tool setups before deployment.

**Key Scripts**:

- `validate-config.sh` - Validate Nix configuration
- `ai-tool-setup.sh` - Verify AI tool configurations

**Integration**: Standalone validation tools (use in pre-commit hooks)

[📖 Full Documentation](validation/README.md)

---

## 🔍 Finding the Right Script

### By Use Case

| I need to... | Script | Category |
|--------------|--------|----------|
| Check VPN port forwarding | `monitor-protonvpn-portforward.sh` | media |
| Diagnose slow SSH | `diagnose-ssh-slowness.sh` | diagnostics |
| Optimize network MTU | `optimize-mtu.sh` | network |
| Test speed through VLAN 2 | `test-vlan2-speed.sh` | network |
| Fix Steam audio issues | `diagnose-steam-audio.sh` | diagnostics |
| Validate config before rebuild | `validate-config.sh` | validation |
| Check AI tool setup | `ai-tool-setup.sh` | validation |
| Verify qBittorrent setup | `verify-qbittorrent-vpn.sh` | media |
| Monitor HDD storage | `monitor-hdd-storage.sh` | media |
| Benchmark SSH performance | `test-ssh-performance.sh` | diagnostics |

### By Integration Status

**Automated (Integrated into System)** (12 scripts):

- **Claude Code Hooks** (7) → `.claude/settings.json`
  - All hooks run automatically during Claude Code sessions
- **qBittorrent/VPN** (5) → NixOS modules
  - `protonvpn-natpmp-portforward.sh` - systemd service
  - `show-protonvpn-port.sh` - system package
  - `monitor-protonvpn-portforward.sh` - system package
  - `verify-qbittorrent-vpn.sh` - system package
  - `test-vpn-port-forwarding.sh` - system package

**Standalone (Manual Execution)** (12 scripts):

- All diagnostics, network tests, and validation tools
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

# Run validation on all scripts
./scripts/validation/ai-tool-setup.sh
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
  - [Script Organization Proposal](../docs/SCRIPT_ORGANIZATION_PROPOSAL.md) - Architecture
  - [AI Tools Guide](../AI_TOOLS.md) - AI assistant setup

## 🔧 Common Tasks

### Troubleshooting qBittorrent VPN

```bash
# Complete verification
./scripts/media/verify-qbittorrent-vpn.sh

# Monitor status
./scripts/media/monitor-protonvpn-portforward.sh

# Check port forwarding
./scripts/media/test-vpn-port-forwarding.sh

# Check specific port (64243)
./scripts/check-torrent-port-64243.sh

# Check any port
./scripts/check-torrent-port.sh 64243

# Update Transmission port manually
./scripts/update-transmission-port.sh 55555 -u admin -p secret

# Get Transmission session info
./scripts/update-transmission-port.sh info -u admin -p secret

# Diagnose seeding issues
./scripts/media/diagnose-qbittorrent-seeding.sh
```

### Optimizing Network Performance

```bash
# Discover optimal MTU
sudo ./scripts/network/optimize-mtu.sh

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

Hooks run automatically during Claude Code sessions. Check status:

```bash
# Validate hook setup
./scripts/validation/ai-tool-setup.sh

# Test specific hook
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
nix-shell -p bash coreutils iproute2 iputils curl jq
```

Category-specific dependencies are listed in each category's README.

## 🔗 See Also

- [POG Scripts](../pkgs/pog-scripts/) - Interactive CLI tools (`nix run .#<name>`)
- [Templates](../templates/) - Module templates
- [AI Guidelines](../CLAUDE.md) - AI assistant rules
- [Contributing](../CONTRIBUTING.md) - Development workflow

---

**Last Updated**: 2025-11-26
**Scripts**: 24 total (7 hooks, 9 media, 3 network, 3 diagnostics, 2 validation)
**Organization**: Phase 1 complete (categorized structure with backward compatibility)
