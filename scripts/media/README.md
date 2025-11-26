# Media Management Scripts

Scripts for managing qBittorrent, ProtonVPN port forwarding, and HDD storage monitoring. These scripts ensure your media server runs smoothly with proper VPN confinement and port forwarding.

**Integration**: NixOS modules in `modules/nixos/services/media-management/`

## Available Scripts (9 scripts)

### Port Forwarding & VPN

#### `protonvpn-natpmp-portforward.sh`

**Integration**: systemd service (automated)
**Purpose**: Automated NAT-PMP port forwarding for qBittorrent via ProtonVPN

**Usage**:

```bash
# Run manually (uses defaults from env or config)
./scripts/media/protonvpn-natpmp-portforward.sh

# Or with custom values
NAMESPACE=qbt VPN_GATEWAY=10.2.0.1 ./scripts/media/protonvpn-natpmp-portforward.sh
```

**What it does**:

1. Checks VPN namespace and connectivity
2. Queries NAT-PMP for forwarded port
3. Updates qBittorrent configuration
4. Restarts qBittorrent service
5. Verifies port is listening

**Systemd Integration**: Runs automatically via systemd timer every 45 minutes when VPN is enabled.

---

#### `show-protonvpn-port.sh`

**Integration**: systemd service helper
**Purpose**: Query NAT-PMP for the current forwarded port

**Usage**:

```bash
# Show current port
./scripts/media/show-protonvpn-port.sh

# With custom settings
NAMESPACE=qbt VPN_GATEWAY=10.2.0.1 ./scripts/media/show-protonvpn-port.sh
```

**Output**:

```
Current ProtonVPN forwarded port: 12345
```

---

#### `test-vpn-port-forwarding.sh`

**Integration**: systemd service helper
**Purpose**: Quick one-liner verification for port forwarding status

**Usage**:

```bash
# Run quick verification
./scripts/media/test-vpn-port-forwarding.sh

# Or with custom settings
NAMESPACE=qbt VPN_GATEWAY=10.2.0.1 ./scripts/media/test-vpn-port-forwarding.sh
```

**Quick Checks**:

1. ProtonVPN assigned port (via NAT-PMP)
2. qBittorrent configured port
3. Port matching verification
4. qBittorrent listening status
5. Port forwarding service status
6. External IP verification
7. qBittorrent service status

**Returns**:

- Exit code 0: All checks passed
- Exit code 1: Issues found (shows troubleshooting steps)

**Use when**:

- You want a fast status check
- After making configuration changes
- Before testing torrents
- To verify automation is working

---

#### `monitor-protonvpn-portforward.sh`

**Integration**: systemd service helper
**Purpose**: Comprehensive monitoring script for VPN namespace and port forwarding status

**Usage**:

```bash
# Run monitoring
./scripts/media/monitor-protonvpn-portforward.sh

# Or with custom namespace
NAMESPACE=qbt ./scripts/media/monitor-protonvpn-portforward.sh
```

**Checks**:

1. VPN namespace exists
2. WireGuard interface status
3. VPN connectivity (gateway ping, external IP)
4. NAT-PMP port forwarding
5. qBittorrent service status
6. qBittorrent configuration (port, interface binding)
7. Listening ports in namespace
8. Recent service logs

**Exit codes**:

- `0`: All checks passed
- `>0`: Number of failed checks

---

#### `verify-qbittorrent-vpn.sh`

**Integration**: systemd service helper
**Purpose**: Interactive verification script following the setup guide checklist

**Usage**:

```bash
./scripts/media/verify-qbittorrent-vpn.sh
```

**Phases**:

1. **Basic Connectivity**: Namespace, WireGuard, routing, gateway, external IP
2. **NAT-PMP**: Port forwarding queries and assignments
3. **qBittorrent**: Service status, configuration, port binding
4. **Summary**: Next steps and automation tips

**Use this after**:

- Initial qBittorrent VPN setup
- Configuration changes
- Troubleshooting connectivity issues

---

### qBittorrent Diagnostics

#### `diagnose-qbittorrent-seeding.sh`

**Integration**: standalone diagnostic tool
**Purpose**: Comprehensive qBittorrent seeding diagnostic script

**Usage**:

```bash
./scripts/media/diagnose-qbittorrent-seeding.sh
```

**Identifies**:

- VPN configuration issues
- Port forwarding problems
- Network connectivity issues
- qBittorrent configuration errors
- Peer discovery issues

---

#### `test-qbittorrent-connectivity.sh`

**Integration**: standalone diagnostic tool
**Purpose**: Test qBittorrent network connectivity and peer reachability

**Usage**:

```bash
./scripts/media/test-qbittorrent-connectivity.sh
```

**Tests**:

- External connectivity via VPN
- Port forwarding status
- Tracker connectivity
- DHT connectivity
- Peer connections

---

#### `test-qbittorrent-seeding-health.sh`

**Integration**: standalone diagnostic tool
**Purpose**: Full health check with qBittorrent API integration

**Usage**:

```bash
./scripts/media/test-qbittorrent-seeding-health.sh
```

**Checks**:

- Service status
- API accessibility
- Torrent states
- Upload/download rates
- Connection statistics
- Recent errors

---

### Storage Monitoring

#### `monitor-hdd-storage.sh`

**Integration**: referenced in POG scripts
**Purpose**: Monitor HDD storage usage and health for media services

**Usage**:

```bash
# One-time report
./scripts/media/monitor-hdd-storage.sh

# Continuous monitoring
./scripts/media/monitor-hdd-storage.sh --continuous --interval 10
```

**Checks**:

- Disk space usage (SSD staging, HDD storage)
- HDD I/O utilization
- Service status (qBittorrent, Jellyfin, etc.)
- Temperature readings (if available)

**Output**:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 HDD Storage Monitor
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💾 Storage Status:
  SSD Staging (/mnt/staging):     12.5G / 500G (3%)
  HDD Storage (/mnt/storage):     8.2T / 24T (34%)

📈 I/O Utilization:
  sda: 5% busy
  sdb: 12% busy

✅ Service Status:
  qBittorrent: active (running)
  Jellyfin: active (running)
```

---

## NixOS Module Integration

These scripts are integrated into your NixOS configuration:

### Port Forwarding Service

```nix
# modules/nixos/services/media-management/protonvpn-portforward.nix
systemd.services.protonvpn-portforward = {
  script = builtins.readFile ../../../../scripts/media/protonvpn-natpmp-portforward.sh;
  # Runs automatically every 45 minutes
};
```

### Helper Scripts

```nix
# modules/nixos/services/media-management/protonvpn-portforward.nix
environment.systemPackages = [
  (pkgs.writeShellScriptBin "show-protonvpn-port"
    (builtins.readFile ../../../../scripts/media/show-protonvpn-port.sh))
  (pkgs.writeShellScriptBin "monitor-protonvpn-portforward"
    (builtins.readFile ../../../../scripts/media/monitor-protonvpn-portforward.sh))
  (pkgs.writeShellScriptBin "verify-qbittorrent-vpn"
    (builtins.readFile ../../../../scripts/media/verify-qbittorrent-vpn.sh))
  (pkgs.writeShellScriptBin "test-vpn-port-forwarding"
    (builtins.readFile ../../../../scripts/media/test-vpn-port-forwarding.sh))
];
```

## Automation

The ProtonVPN port forwarding is fully automated. Configure in your NixOS config:

```nix
host.services.mediaManagement.qbittorrent.vpn.portForwarding = {
  enable = true;  # Default: true when VPN is enabled
  renewInterval = "45min";  # Default: 45 minutes
  gateway = "10.2.0.1";  # Default: ProtonVPN gateway
};
```

**Check timer status**:

```bash
systemctl status protonvpn-portforward.timer
systemctl list-timers | grep protonvpn
```

**View logs**:

```bash
journalctl -u protonvpn-portforward.service -f
```

## Troubleshooting

### Port forwarding not working

1. Run verification: `./scripts/media/verify-qbittorrent-vpn.sh`
2. Check monitoring: `./scripts/media/monitor-protonvpn-portforward.sh`
3. View logs: `journalctl -u protonvpn-portforward -u qbittorrent -f`

### NAT-PMP errors

- Ensure VPN namespace exists: `ip netns list`
- Check VPN connectivity: `sudo ip netns exec qbt ping 10.2.0.1`
- Verify `natpmpc` is installed: `which natpmpc`

### qBittorrent not updating

- Check config permissions: `ls -la /var/lib/qBittorrent/`
- Verify service can write: `systemctl cat qbittorrent.service | grep ReadWrite`
- Check service status: `systemctl status qbittorrent`

### VPN namespace issues

- Check VPN service: `systemctl status qbt`
- View WireGuard status: `sudo ip netns exec qbt wg show`
- Verify SOPS secrets are decrypted: `ls -la /run/secrets/`

## Dependencies

Required packages:

- `iproute2` - Network namespace operations
- `libnatpmp` - NAT-PMP queries (`natpmpc` command)
- `systemd` - Service management
- `curl` - External connectivity tests
- `wireguard-tools` - WireGuard status

Install missing dependencies:

```bash
nix-shell -p libnatpmp wireguard-tools
```

## Documentation

For complete setup and troubleshooting guides:

- [qBittorrent Setup Guide](../../docs/QBITTORRENT_GUIDE.md)
- [ProtonVPN Port Forwarding Setup](../../docs/PROTONVPN_PORT_FORWARDING_SETUP.md)
- [qBittorrent VPN Optimization](../../docs/QBITTORRENT_VPN_OPTIMIZATION.md)

## See Also

- [Network Scripts](../network/README.md) - MTU optimization
- [Diagnostic Scripts](../diagnostics/README.md) - General troubleshooting
- [Script Organization Proposal](../../docs/SCRIPT_ORGANIZATION_PROPOSAL.md)
