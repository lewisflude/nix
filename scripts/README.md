# Scripts Directory

**⚠️ IMPORTANT**: Do not add new scripts to this directory without explicit
permission. For new CLI tools, add a POG app in `pkgs/pog-scripts/` instead.
This directory holds one-off diagnostic shell scripts only — nothing here is
part of the flake, packaged, or run automatically.

## 📂 Directory Structure

```
scripts/
├── diagnostics/   5 scripts - System troubleshooting (SSH, XFS, gaming)
├── macos/         1 script  - macOS housekeeping
├── media/         8 scripts - qBittorrent, ProtonVPN, storage monitoring
└── validation/    2 scripts - Configuration and vulnerability checks
```

**Total**: 16 scripts across 4 categories. All are run manually.

## 🚀 Quick Start

```bash
# Find a script
find scripts/ -name "*vpn*"

# Run a diagnostic
./scripts/diagnostics/diagnose-ssh-slowness.sh jupiter

# Validate configuration
./scripts/validation/validate-config.sh
```

## 📚 Categories

### diagnostics/ — Troubleshooting

- `check-gaming-setup.sh` - Gaming configuration validation (GameMode,
  ananicy-cpp, Proton-GE, Vulkan, kernel params)
- `diagnose-ssh-slowness.sh` - SSH performance diagnostics
- `test-ssh-performance.sh` - SSH benchmarking
- `check-xfs-features.sh` - XFS feature verification (bigtime, inobtcount,
  reflink, rmapbt) for the mergerfs branches on jupiter
- `benchmark-xfs-before-after.sh` - XFS performance benchmarking

### macos/ — Host Housekeeping

- `move-to-jupiter.sh` - Move large, safe-to-archive Mac folders to jupiter
  (dry-run by default)

### media/ — qBittorrent & ProtonVPN

Diagnostics for the VPN-confined qBittorrent stack. Related modules:
`modules/qbittorrent.nix`, `modules/protonvpn-portforward.nix`.

- `verify-qbittorrent-vpn.sh` - Full VPN setup verification
- `diagnose-qbittorrent-seeding.sh` - Seeding diagnostics
- `test-qbittorrent-seeding-health.sh` - Seeding health check
- `test-qbittorrent-connectivity.sh` - TCP/uTP connectivity in the `qbt`
  namespace
- `monitor-protonvpn-portforward.sh` - Port forwarding monitoring
- `test-vpn-port-forwarding.sh` - Quick port forwarding verification
- `show-protonvpn-port.sh` - Show the currently mapped NAT-PMP port
- `monitor-hdd-storage.sh` - Disk utilization and I/O monitoring

### validation/ — Configuration Testing

- `validate-config.sh` - Dendritic anti-pattern scan (`with pkgs;`,
  `specialArgs`, direct constants imports) plus flake structure check
- `scan-vulnerabilities.sh` - CVE scan via vulnix

## 🛠️ Development

New CLI tools belong in `pkgs/pog-scripts/` (`nix run .#new-module` scaffolds
modules; see existing POG apps for the pattern). Scripts here are ad-hoc and
should follow the same basic conventions as the existing ones:

1. `#!/usr/bin/env bash` shebang
2. `set -euo pipefail`
3. Usage/`--help` output when arguments are required
4. Exit codes: 0=success, 1=error

## 🔗 See Also

- [POG Scripts](../pkgs/pog-scripts/) - Interactive CLI tools
  (`nix run .#<name>`)
- [Dendritic Pattern](../DENDRITIC_PATTERN.md) - Module authoring reference
- [AI Guidelines](../CLAUDE.md) - AI assistant rules
