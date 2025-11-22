---
description: "Run diagnostic scripts for troubleshooting system issues"
---

# Diagnostic Tool Runner

Run diagnostic scripts to troubleshoot system issues in this Nix configuration.

## Available Diagnostic Scripts

### qBittorrent & VPN Diagnostics

1. **Full qBittorrent Seeding Diagnostics**
   ```bash
   ./scripts/diagnose-qbittorrent-seeding.sh
   ```
   Comprehensive diagnostics for qBittorrent seeding issues.

2. **qBittorrent Connectivity Test**
   ```bash
   ./scripts/test-qbittorrent-connectivity.sh
   ```
   Test qBittorrent network connectivity.

3. **qBittorrent VPN Verification**
   ```bash
   ./scripts/verify-qbittorrent-vpn.sh
   ```
   Verify qBittorrent is properly using VPN connection.

4. **ProtonVPN Port Forwarding Monitor**
   ```bash
   ./scripts/monitor-protonvpn-portforward.sh
   ```
   Check VPN port forwarding status.

5. **VPN Port Forwarding Test**
   ```bash
   ./scripts/test-vpn-port-forwarding.sh
   ```
   Quick port forwarding status check.

### SSH Performance Diagnostics

1. **SSH Slowness Diagnosis**
   ```bash
   ./scripts/diagnose-ssh-slowness.sh
   ```
   Troubleshoot slow SSH connections.

2. **SSH Performance Benchmarking**
   ```bash
   ./scripts/test-ssh-performance.sh
   ```
   Comprehensive SSH performance tests.

### Network Diagnostics

1. **VLAN2 Speed Test**
   ```bash
   ./scripts/test-vlan2-speed.sh
   ```
   Test network speed through VLAN 2.

2. **HDD Storage Monitoring**
   ```bash
   ./scripts/monitor-hdd-storage.sh
   ```
   Monitor HDD storage usage and health.

### System Diagnostics

1. **Steam Audio Diagnosis**
   ```bash
   ./scripts/diagnose-steam-audio.sh
   ```
   Diagnose Steam audio issues.

## Usage

You can specify which diagnostic to run:

**Arguments**:
- `$1` - Diagnostic name or "all" to run relevant diagnostics

**Examples**:
```
/diagnose qbittorrent
/diagnose ssh
/diagnose network
/diagnose all
```

## Your Task

Based on the argument provided (or if none, ask the user which diagnostic they want):

1. **Identify the diagnostic** - Determine which script(s) to run
2. **Run the appropriate scripts** - Execute using Bash tool
3. **Analyze results** - Review output for issues
4. **Provide recommendations** - Suggest fixes based on findings
5. **Document issues** - If problems found, explain clearly

## Important Notes

- Scripts are located in `./scripts/` directory
- All scripts output formatted results
- Some scripts may require specific services to be running
- Review script documentation in `scripts/README.md` for details

## Related Documentation

- `docs/QBITTORRENT_GUIDE.md` - qBittorrent setup and troubleshooting
- `docs/PROTONVPN_PORT_FORWARDING_SETUP.md` - VPN configuration
- `scripts/README.md` - Complete script documentation
