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

## Backup Scripts

### `backup-preview.sh`

Preview what will be backed up to Samsung Drive before running the actual backup.

**Usage:**

```bash
./scripts/backup-preview.sh
```

**Shows:**

- All directories that will be backed up
- Size of each directory
- File counts
- Total backup size
- Available space on Samsung Drive

**What's included:**

- **Music & Audio Production:**
  - Ableton Projects (`~/Music/Ableton/`) - ~41GB
  - Sample Library (`~/Music/Sample Library/`) - ~150MB
  - FastGarage Project
  - Music Projects
  - Guitar1 Project (from Desktop)
  - ModularPolyGrandJam Project

- **Ableton Application Support:**
  - Preferences, database, and Live configuration (`~/Library/Application Support/Ableton/`)

- **Max/MSP Projects:**
  - Max 8 and Max 9 projects

- **Development & Creative Projects:**
  - Code Projects (`~/Code/`) - ~61GB
  - Obsidian vaults
  - Unreal Projects

- **Audio Plugin Libraries & Samples:**
  - Toontrack Superior Drummer 3 (`~/Library/Application Support/Toontrack/Superior3/`) - ~224GB
  - FabFilter Plugin Presets (`~/Library/Application Support/FabFilter/`) - ~14MB
  - Sonarworks SoundID Reference (`~/Library/Application Support/Sonarworks/`) - ~126MB

- **Application Data & Workspaces:**
  - Obsidian Application Support (`~/Library/Application Support/obsidian/`)
  - Cursor Workspace Data (`~/Library/Application Support/Cursor/`) - ~2.1GB

- **Security & Configuration:**
  - SSH Keys (`~/.ssh/`)
  - GPG Keys (`~/.gnupg/`)
  - Existing Backups (`~/Backups/`) - ~2.3GB

**What's excluded (already in iCloud):**

- Photos (synced to iCloud)
- Most Documents (synced to iCloud)
- Desktop files (synced to iCloud, except Ableton projects)

### `backup-to-samsung-drive.sh`

Back up important files to Samsung Drive using rsync.

**Usage:**

```bash
# Run the backup
./scripts/backup-to-samsung-drive.sh
```

**Features:**

- Uses `rsync` for efficient incremental backups
- Preserves file attributes and permissions
- Creates timestamped backup directories
- Generates detailed logs
- Shows progress for each backup operation
- Skips directories that don't exist

**Backup location:**

```
/Volumes/Samsung Drive/Backups/<hostname>/
```

**Logs:**

Each backup creates a timestamped log file:

```
/Volumes/Samsung Drive/Backups/<hostname>/backup_YYYYMMDD_HHMMSS.log
```

**Requirements:**

- Samsung Drive must be mounted at `/Volumes/Samsung Drive`
- `rsync` (standard on macOS)

**Example output:**

```
=== Starting Backup to Samsung Drive ===
📦 Backing up Ableton Projects (41G)...
✓ Completed: Ableton Projects
📦 Backing up Sample Library (150M)...
✓ Completed: Sample Library
...
=== Backup Summary ===
Successful backups: 21
Total backup size: ~330 GB
✓ All backups completed successfully!
```

### `restore-from-samsung-drive.sh`

Restore important files from Samsung Drive backup to a new host.

**Usage:**

```bash
# Run the restore
./scripts/restore-from-samsung-drive.sh
```

**Features:**

- Lists available backups from all hostnames
- Interactive selection of which backup to restore
- Confirmation prompt before restoring (safety check)
- Uses `rsync` to restore files preserving attributes
- Restores all items that were backed up:
  - Music production files
  - Code projects
  - Audio plugin libraries
  - Application data
  - Security keys (SSH, GPG)
- Shows progress for each restore operation
- Skips items that don't exist in backup

**Restore process:**

1. Lists all available backups (by hostname)
2. Prompts you to select which backup to restore
3. Shows warning and asks for confirmation
4. Restores files to their original locations
5. Shows summary of successful/failed restores

**Example output:**

```
=== Restore from Samsung Drive ===

Available backups:
  1. Lewiss-MacBook-Pro (330G)

Select backup to restore from [hostname]: Lewiss-MacBook-Pro
Selected backup: Lewiss-MacBook-Pro

⚠ WARNING: This will restore files from backup to your current system.
Existing files may be overwritten.

Continue? [y/N]: y

=== Starting Restore ===
📥 Restoring Ableton Projects (41G)...
✓ Completed: Ableton Projects
...
=== Restore Summary ===
Successful restores: 21
✓ All restores completed successfully!
```

**Note:** The restore script will overwrite existing files. Make sure you want to restore before confirming.

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
