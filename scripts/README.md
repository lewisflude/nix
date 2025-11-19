# Scripts Directory

Utility scripts for managing NixOS configuration and services.

## Claude Code Hook Scripts

These scripts are used by Claude Code hooks (see `.claude/settings.json`) to enforce code quality and safety standards.

### `block-dangerous-commands.sh`

**Hook**: PreToolUse (Bash)
**Purpose**: Blocks dangerous commands before execution

**Blocked operations**:

- System rebuilds (`nh os switch`, `nixos-rebuild`, `darwin-rebuild`)
- Destructive file operations (`rm -rf`, `mv to /dev/null`)
- Git force operations (`git push --force`, `git reset --hard`)
- Production host access (patterns: `prod*`, `production*`, `*-prod`, `*-production`)

**Exit codes**:

- `0`: Command allowed
- `2`: Command blocked (shown to Claude)

### `auto-format-nix.sh`

**Hook**: PostToolUse (Write|Edit)
**Purpose**: Automatically formats Nix files after editing

**Behavior**:

- Runs `nixfmt` on all `.nix` files after Write/Edit operations
- Blocks (exit 2) if formatting fails (indicates syntax errors)
- Skips non-Nix files silently

**Requirements**: `nixfmt` must be in PATH (available in `nix develop`)

### `strict-lint-check.sh`

**Hook**: PostToolUse (Write|Edit)
**Purpose**: Enforces code quality standards and architectural guidelines

**Checks**:

- **statix**: Nix antipattern detection
- **deadnix**: Unused code detection
- **with pkgs;**: Antipattern from CLAUDE.md
- **Module placement**: Validates system vs home-manager separation

**Exit codes**:

- `0`: All checks passed
- `2`: Issues found (blocks Claude, requires fixes)

### `load-context.sh`

**Hook**: SessionStart
**Purpose**: Loads project context when Claude Code starts

**Output** (added to Claude's context):

- Current git branch
- Last 3 commits
- Working tree status

**Performance**: Minimal overhead (~100ms)

## qBittorrent & ProtonVPN Scripts

### `protonvpn-natpmp-portforward.sh`

Automated NAT-PMP port forwarding for qBittorrent via ProtonVPN.

**Usage:**

```bash
# Run manually (uses defaults from env or config)
./scripts/protonvpn-natpmp-portforward.sh

# Or with custom values
NAMESPACE=qbt VPN_GATEWAY=10.2.0.1 ./scripts/protonvpn-natpmp-portforward.sh
```

**What it does:**

1. Checks VPN namespace and connectivity
2. Queries NAT-PMP for forwarded port
3. Updates qBittorrent configuration
4. Restarts qBittorrent service
5. Verifies port is listening

**Systemd Integration:**
Runs automatically via systemd timer every 45 minutes when VPN is enabled.

### `test-vpn-port-forwarding.sh`

Quick one-liner verification for port forwarding status.

**Usage:**

```bash
# Run quick verification
./scripts/test-vpn-port-forwarding.sh

# Or with custom settings
NAMESPACE=qbt VPN_GATEWAY=10.2.0.1 ./scripts/test-vpn-port-forwarding.sh
```

**Quick Checks:**

1. ProtonVPN assigned port (via NAT-PMP)
2. qBittorrent configured port
3. Port matching verification
4. qBittorrent listening status
5. Port forwarding service status
6. External IP verification
7. qBittorrent service status

**Returns:**

- Exit code 0: All checks passed
- Exit code 1: Issues found (shows troubleshooting steps)

**Use when:**

- You want a fast status check
- After making configuration changes
- Before testing torrents
- To verify automation is working

### `monitor-protonvpn-portforward.sh`

Comprehensive monitoring script for VPN namespace and port forwarding status.

**Usage:**

```bash
# Run monitoring
./scripts/monitor-protonvpn-portforward.sh

# Or with custom namespace
NAMESPACE=qbt ./scripts/monitor-protonvpn-portforward.sh
```

**Checks:**

1. VPN namespace exists
2. WireGuard interface status
3. VPN connectivity (gateway ping, external IP)
4. NAT-PMP port forwarding
5. qBittorrent service status
6. qBittorrent configuration (port, interface binding)
7. Listening ports in namespace
8. Recent service logs

**Exit codes:**

- `0`: All checks passed
- `>0`: Number of failed checks

### `verify-qbittorrent-vpn.sh`

Interactive verification script following the setup guide checklist.

**Usage:**

```bash
./scripts/verify-qbittorrent-vpn.sh
```

**Phases:**

1. **Basic Connectivity**: Namespace, WireGuard, routing, gateway, external IP
2. **NAT-PMP**: Port forwarding queries and assignments
3. **qBittorrent**: Service status, configuration, port binding
4. **Summary**: Next steps and automation tips

### `monitor-hdd-storage.sh`

Monitor HDD storage usage and health for media services.

**Usage:**

```bash
# One-time report
./scripts/monitor-hdd-storage.sh

# Continuous monitoring
./scripts/monitor-hdd-storage.sh --continuous --interval 10
```

**Checks:**

- Disk space usage (SSD staging, HDD storage)
- HDD I/O utilization
- Service status
- Temperature readings (if available)

For complete qBittorrent setup and troubleshooting, see `docs/QBITTORRENT_GUIDE.md`.

## Network Performance Scripts

### qBittorrent Diagnostics

- `diagnose-qbittorrent-seeding.sh` - Diagnose seeding issues
- `test-qbittorrent-connectivity.sh` - Test qBittorrent connectivity
- `test-qbittorrent-seeding-health.sh` - Check seeding health

### SSH Performance

- `diagnose-ssh-slowness.sh` - Diagnose SSH performance issues
- `test-ssh-performance.sh` - Comprehensive SSH speed testing

### Network Testing

- `test-vlan2-speed.sh` - Test VLAN2 network speed
- `test-sped.sh` - Simple speed test wrapper

### Audio & Gaming

#### `diagnose-steam-audio.sh`

Comprehensive diagnostic tool for Steam/Proton audio issues with PipeWire.

**Usage:**

```bash
# Run diagnostics (Steam can be running or stopped)
./scripts/diagnose-steam-audio.sh
```

**Checks:**

1. PipeWire, PipeWire-Pulse, and WirePlumber service status
2. PulseAudio socket existence and permissions
3. Available audio sinks in PipeWire
4. Default sink configuration
5. WirePlumber device status
6. Steam process environment variables
7. Session audio environment variables
8. Test audio playback

**Common Issues:**

- **Games don't appear in audio mixer:** Missing `SDL_AUDIODRIVER=pulseaudio` or wrong `PULSE_SERVER`
- **No sound in games but other apps work:** Games using ALSA directly instead of PulseAudio
- **Intermittent audio failures:** No explicit default sink configured in WirePlumber

**Fixes:**

1. Restart Steam: `steam -shutdown && steam`
2. Add to game launch options: `SDL_AUDIODRIVER=pulseaudio %command%`
3. Check logs: `~/.local/share/Steam/logs/`
4. Enable debug logging: `PULSE_LOG=99 <game>`

### System Validation

- `validate-config.sh` - Validate Nix configuration before rebuild

## Requirements

Most scripts require:

- `bash` (standard)
- `iproute2` for network namespace operations
- `libnatpmp` for NAT-PMP queries (`natpmpc` command)
- `systemd` for service management
- `curl` for external connectivity tests

Install missing dependencies:

```bash
nix-shell -p libnatpmp
```

## Automation

The ProtonVPN port forwarding can be automated via systemd timer. Enable in your NixOS configuration:

```nix
host.services.mediaManagement.qbittorrent.vpn.portForwarding = {
  enable = true;  # Default: true when VPN is enabled
  renewInterval = "45min";  # Default: 45 minutes
  gateway = "10.2.0.1";  # Default: ProtonVPN gateway
};
```

Check timer status:

```bash
systemctl status protonvpn-portforward.timer
systemctl list-timers | grep protonvpn
```

View logs:

```bash
journalctl -u protonvpn-portforward.service -f
```

## Troubleshooting

**Port forwarding not working:**

1. Run verification: `./scripts/verify-qbittorrent-vpn.sh`
2. Check monitoring: `./scripts/monitor-protonvpn-portforward.sh`
3. View logs: `journalctl -u protonvpn-portforward -u qbittorrent -f`

**NAT-PMP errors:**

- Ensure VPN namespace exists: `ip netns list`
- Check VPN connectivity: `sudo ip netns exec qbt ping 10.2.0.1`
- Verify `natpmpc` is installed: `which natpmpc`

**qBittorrent not updating:**

- Check config permissions: `ls -la /var/lib/qBittorrent/`
- Verify service can write: `systemctl cat qbittorrent.service | grep ReadWrite`
- Check service status: `systemctl status qbittorrent`

**VPN namespace issues:**

- Check VPN service: `systemctl status qbt`
- View WireGuard status: `sudo ip netns exec qbt wg show`
- Verify SOPS secrets are decrypted: `ls -la /run/secrets/`
