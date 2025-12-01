# ProtonVPN Port Forwarding Setup - Complete

## Quick Verification

**One-liner to check everything:**

```bash
./scripts/test-vpn-port-forwarding.sh
```

**Manual quick checks:**

```bash
# 1. Get ProtonVPN port (UDP)
sudo ip netns exec qbt natpmpc -a 1 0 udp 60 -g 10.2.0.1 | grep "Mapped public port"

# 2. Get ProtonVPN port (TCP) - should match UDP
sudo ip netns exec qbt natpmpc -a 1 0 tcp 60 -g 10.2.0.1 | grep "Mapped public port"

# 3. Get qBittorrent port
sudo grep "Session\\Port" /var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf

# 4. Compare ports
echo "ProtonVPN: $(sudo ip netns exec qbt natpmpc -a 1 0 tcp 60 -g 10.2.0.1 2>/dev/null | grep 'Mapped public port' | awk '{print $4}')"
echo "qBittorrent: $(sudo grep 'Session\\Port' /var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf | cut -d'=' -f2)"

# 5. Check listening
sudo ip netns exec qbt ss -tulnp | grep qbittorrent

# 6. Check service
systemctl status protonvpn-portforward.service
```

## Overview

Automated NAT-PMP port forwarding for qBittorrent running in a VPN-confined namespace with ProtonVPN. This implementation follows ProtonVPN's official documentation exactly:

- **Lease Duration**: 60 seconds
- **Renewal Interval**: 45 seconds (75% of lease duration)
- **Protocol Support**: Both UDP and TCP port mappings

> **⚠️ Important:** ProtonVPN's NAT-PMP port forwarding is **IPv4-only**. Even though ProtonVPN provides IPv6 connectivity, port forwarding does not work for IPv6. Both torrent clients are configured to use IPv4 only. See [ProtonVPN IPv6 and Port Forwarding Limitations](./PROTONVPN_IPV6_PORTFORWARDING.md) for details.

## Architecture

```
???????????????????????????????????????????????????????????????
? Host Network (192.168.1.0/24)                              ?
?                                                             ?
?  ????????????????????????????????????????????????????????  ?
?  ? VPN Namespace: qbt                                   ?  ?
?  ?                                                       ?  ?
?  ?  ?????????????????????????????????????????????????   ?  ?
?  ?  ? WireGuard (wg0): 10.2.0.2/32                  ?   ?  ?
?  ?  ? Gateway: 10.2.0.1                              ?   ?  ?
?  ?  ? ProtonVPN Endpoint: 138.199.7.129:51820       ?   ?  ?
?  ?  ?????????????????????????????????????????????????   ?  ?
?  ?                                                       ?  ?
?  ?  ?????????????????????????????????????????????????   ?  ?
?  ?  ? qBittorrent                                    ?   ?  ?
?  ?  ? - Interface binding: qbt0                      ?   ?  ?
?  ?  ? - Torrent port: Dynamic (via NAT-PMP)         ?   ?  ?
?  ?  ? - WebUI: 8080 (bridged to host)               ?   ?  ?
?  ?  ?????????????????????????????????????????????????   ?  ?
?  ????????????????????????????????????????????????????????  ?
?                                                             ?
?  ????????????????????????????????????????????????????????  ?
?  ? Systemd Timer: protonvpn-portforward.timer          ?  ?
?  ? - Runs every: 45 minutes                             ?  ?
?  ? - Queries NAT-PMP for forwarded port                 ?  ?
?  ? - Updates qBittorrent configuration                  ?  ?
?  ? - Restarts qBittorrent if port changed               ?  ?
?  ????????????????????????????????????????????????????????  ?
???????????????????????????????????????????????????????????????
```

## Supported Clients

This setup supports **both qBittorrent and Transmission** running in the same VPN namespace:

| Client | Integration | Port Update Method | Status |
|--------|-------------|-------------------|---------|
| **qBittorrent** | WebUI API | HTTP API calls | ✅ Full |
| **Transmission** | transmission-remote | CLI utility | ✅ Full |

Both clients share the same forwarded port from ProtonVPN and are automatically updated by the port forwarding automation.

## Components

### 1. VPN-Confinement Module

**File**: `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix`

Configures the VPN namespace using the VPN-Confinement flake input.

**Features**:

- Creates isolated network namespace `qbt`
- Configures WireGuard interface from SOPS secrets
- Sets up port mappings for WebUI access
- Opens torrent ports in VPN namespace firewall

### 2. Port Forwarding Automation Module

**File**: `modules/nixos/services/media-management/protonvpn-portforward.nix`

Manages automated NAT-PMP port forwarding.

**Features**:

- Systemd service for port forwarding updates
- Systemd timer for periodic renewal (every 45 minutes)
- Automatic qBittorrent configuration updates
- System-wide monitoring commands

### 3. Automation Script

**File**: `scripts/protonvpn-natpmp-portforward.sh`

Main script that handles port forwarding workflow for both qBittorrent and Transmission.

**Workflow**:

1. Checks VPN namespace exists and is reachable
2. Queries NAT-PMP gateway (10.2.0.1) for forwarded port (both UDP and TCP)
3. Verifies both protocols receive the same port assignment
4. **qBittorrent Update**: Compares with current config and updates via WebUI API if needed
5. **Transmission Update**: Updates port using `transmission-remote` CLI utility
6. Updates VPN namespace firewall rules for new port
7. Verifies ports are listening

**Important Notes**:

- **qBittorrent**: Uses WebUI API (HTTP POST requests)
- **Transmission**: Uses `transmission-remote` CLI utility (the **only** safe method)
  - ⚠️ **NEVER edit Transmission's `settings.json` while the daemon is running**
  - Manual edits are **overwritten** when Transmission restarts
  - Always use `transmission-remote` for live configuration changes

### 4. Monitoring Script

**File**: `scripts/monitor-protonvpn-portforward.sh`

Comprehensive health check for VPN and port forwarding.

**Checks**:

- VPN namespace status
- WireGuard interface and connectivity
- NAT-PMP port assignment
- qBittorrent service status
- Configuration correctness
- Port binding verification
- Recent service logs

### 5. Verification Script

**File**: `scripts/verify-qbittorrent-vpn.sh`

Interactive verification following the setup guide checklist.

**Phases**:

- Phase 1: Basic connectivity (namespace, WireGuard, routing, gateway)
- Phase 2: NAT-PMP port forwarding
- Phase 3: qBittorrent configuration
- Phase 4: Summary and next steps

## Configuration

### qBittorrent with Port Forwarding

Port forwarding is automatically enabled when VPN confinement is active:

```nix
host.services.mediaManagement.qbittorrent.vpn = {
  enable = true;
  namespace = "qbt";
  torrentPort = 62000;  # Initial port, will be updated by NAT-PMP

  portForwarding = {
    enable = true;              # Default: true
    renewInterval = "45min";    # How often to renew (ProtonVPN: 60s lease, 45min renewal)
    gateway = "10.2.0.1";       # ProtonVPN gateway
  };
};
```

### Transmission with Port Forwarding

Enable Transmission in the same VPN namespace:

```nix
host.services.mediaManagement.transmission = {
  enable = true;

  # WebUI configuration
  webUIPort = 9091;

  # Authentication (required for transmission-remote)
  authentication = {
    enable = true;
    username = "admin";
    password = "your-password";  # Or use SOPS secrets
    useSops = false;  # Set to true to use SOPS secrets
  };

  # Initial peer port (will be updated by NAT-PMP)
  peerPort = 62000;

  # VPN confinement (shares namespace with qBittorrent)
  vpn = {
    enable = true;
    namespace = "qbt";  # Same namespace as qBittorrent
  };
};
```

### Enable Transmission in Port Forwarding Automation

The port forwarding service needs to know about Transmission:

```nix
# In your host configuration or the protonvpn-portforward module
systemd.services.protonvpn-portforward = {
  environment = {
    TRANSMISSION_ENABLED = "true";
    TRANSMISSION_HOST = "127.0.0.1:9091";
    TRANSMISSION_USERNAME_FILE = "/run/secrets/transmission/rpc/username";  # Or use plain string
    TRANSMISSION_PASSWORD_FILE = "/run/secrets/transmission/rpc/password";
  };
};
```

### Using SOPS Secrets for Transmission

For better security, use SOPS to manage Transmission credentials:

```nix
host.services.mediaManagement.transmission.authentication = {
  enable = true;
  useSops = true;
  # Credentials will be loaded from secrets
};

# SOPS secrets configuration
sops.secrets = {
  "transmission/rpc/username" = {
    owner = "transmission";
    group = "transmission";
    mode = "0440";
  };
  "transmission/rpc/password" = {
    owner = "transmission";
    group = "transmission";
    mode = "0440";
  };
};
```

## Usage

### Quick Status Check

```bash
# Run quick verification (fastest)
./scripts/test-vpn-port-forwarding.sh

# Exit code 0 = all checks passed
# Exit code 1 = issues found
```

### Manual Port Update

```bash
# Run port forwarding manually
sudo systemctl start protonvpn-portforward.service

# Check results
journalctl -u protonvpn-portforward.service -n 20
```

### Monitor Status

```bash
# Run comprehensive monitoring
monitor-protonvpn-portforward
# or
./scripts/monitor-protonvpn-portforward.sh

# Exit code 0 = all checks passed
# Exit code N = number of failed checks
```

### Initial Verification

```bash
# Run verification checklist
verify-qbittorrent-vpn
# or
./scripts/verify-qbittorrent-vpn.sh
```

### Check Automation

```bash
# Timer status
systemctl status protonvpn-portforward.timer
systemctl list-timers | grep protonvpn

# Service logs
journalctl -u protonvpn-portforward.service -f

# Recent executions
journalctl -u protonvpn-portforward.service --since "24 hours ago"
```

## Verification Checklist

### ? Phase 1: VPN Connectivity

- [ ] Namespace `qbt` exists
- [ ] WireGuard interface has IP 10.2.0.2/32
- [ ] Can ping VPN gateway 10.2.0.1
- [ ] External IP shows ProtonVPN address (not real IP)

```bash
sudo ip netns list | grep qbt
sudo ip netns exec qbt ip addr show
sudo ip netns exec qbt ping -c 3 10.2.0.1
sudo ip netns exec qbt curl -s https://api.ipify.org
```

### ? Phase 2: Port Forwarding

- [ ] `natpmpc` is available
- [ ] NAT-PMP query succeeds for both UDP and TCP
- [ ] Port is assigned (typically 49152-65535)
- [ ] Both protocols receive the same port
- [ ] Timer is active and scheduled

```bash
which natpmpc
# Test UDP mapping
sudo ip netns exec qbt natpmpc -a 1 0 udp 60 -g 10.2.0.1
# Test TCP mapping
sudo ip netns exec qbt natpmpc -a 1 0 tcp 60 -g 10.2.0.1
systemctl status protonvpn-portforward.timer
```

### ? Phase 3: Torrent Clients

#### qBittorrent

- [ ] Service is running
- [ ] Config file exists
- [ ] Port matches NAT-PMP assignment
- [ ] Interface binding is `qbt0`
- [ ] qBittorrent is listening on assigned port

```bash
systemctl status qbittorrent
sudo grep "Session\\Port" /var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf
sudo grep "InterfaceName" /var/lib/qBittorrent/qBittorrent/config/qBittorrent.conf
sudo ip netns exec qbt ss -tuln | grep <PORT>
```

#### Transmission (Optional)

- [ ] Service is running
- [ ] Port matches NAT-PMP assignment
- [ ] Transmission is listening on assigned port

```bash
systemctl status transmission
# Get current port
sudo ip netns exec qbt transmission-remote 127.0.0.1:9091 -n 'username:password' -si | grep "Peer port"
# Check listening
sudo ip netns exec qbt ss -tuln | grep <PORT>
```

### ? Phase 4: External Connectivity

- [ ] Port is open externally (test at <https://www.yougetsignal.com/tools/open-ports/>)
- [ ] Torrents show incoming peer connections
- [ ] Trackers report correct port

## Manual Port Configuration

### Transmission: Using transmission-remote

**⚠️ CRITICAL**: The **ONLY** safe way to update Transmission settings while it's running is using `transmission-remote`. Never edit `settings.json` manually when the daemon is running.

#### Update Port Manually

```bash
# Basic syntax
transmission-remote [HOST:PORT] -n 'username:password' -p [NEW_PORT]

# Example: Update to port 55555
sudo ip netns exec qbt transmission-remote 127.0.0.1:9091 -n 'admin:secret' -p 55555

# Without authentication (if auth disabled)
sudo ip netns exec qbt transmission-remote 127.0.0.1:9091 -p 55555

# From host network (if WebUI accessible)
transmission-remote jupiter:9091 -n 'admin:secret' -p 55555
```

#### Verify Port Change

```bash
# Get session info (includes port)
sudo ip netns exec qbt transmission-remote 127.0.0.1:9091 -n 'admin:secret' -si

# Check specific port
sudo ip netns exec qbt transmission-remote 127.0.0.1:9091 -n 'admin:secret' -si | grep "Peer port"

# Verify listening
sudo ip netns exec qbt ss -tuln | grep 55555
```

#### Common transmission-remote Commands

```bash
# Get session info
transmission-remote HOST:PORT -n 'user:pass' -si

# Update port
transmission-remote HOST:PORT -n 'user:pass' -p PORT

# Enable port test
transmission-remote HOST:PORT -n 'user:pass' --port-test

# Set download/upload limits
transmission-remote HOST:PORT -n 'user:pass' -d 5000  # Download KB/s
transmission-remote HOST:PORT -n 'user:pass' -u 1000  # Upload KB/s

# List all torrents
transmission-remote HOST:PORT -n 'user:pass' -l
```

### qBittorrent: Using WebUI API

qBittorrent uses HTTP API calls (handled automatically by the port forwarding script).

## Troubleshooting

### NAT-PMP Fails

**Symptoms**: `readnatpmpresponseorretry returned -7 (FAILED)`

**Solutions**:

1. Check VPN connectivity: `sudo ip netns exec qbt ping 10.2.0.1`
2. Verify route exists: `sudo ip netns exec qbt ip route | grep 10.2.0`
3. Check WireGuard handshake: `sudo ip netns exec qbt wg show`
4. Verify ProtonVPN account has port forwarding enabled

### Transmission Port Not Updating

**Symptoms**: Transmission still uses old port after NAT-PMP renewal

**Solutions**:

1. Check service logs: `journalctl -u protonvpn-portforward.service -n 50 | grep -i transmission`
2. Verify `transmission-remote` is available: `which transmission-remote`
3. Check credentials are configured correctly
4. Manually update port to test:

   ```bash
   sudo ip netns exec qbt transmission-remote 127.0.0.1:9091 -n 'admin:password' -p 55555
   ```

5. Verify Transmission authentication is working:

   ```bash
   sudo ip netns exec qbt transmission-remote 127.0.0.1:9091 -n 'admin:password' -si
   ```

### Transmission Authentication Fails

**Symptoms**: `"Unauthorized User"` or `"401 Unauthorized"`

**Solutions**:

1. Verify credentials in Transmission config:

   ```bash
   sudo grep "rpc-username\|rpc-password" /var/lib/transmission/.config/transmission-daemon/settings.json
   ```

2. Check if authentication is enabled:

   ```bash
   sudo grep "rpc-authentication-required" /var/lib/transmission/.config/transmission-daemon/settings.json
   ```

3. If using SOPS secrets, verify they're loaded:

   ```bash
   ls -la /run/secrets/transmission/rpc/
   cat /run/secrets/transmission/rpc/username
   ```

4. Test with authentication disabled (temporarily):

   ```nix
   host.services.mediaManagement.transmission.authentication.enable = false;
   ```

### Transmission Config Changes Overwritten

**Symptoms**: Manual edits to `settings.json` are lost after restart

**Solution**: This is **expected behavior**. Transmission overwrites `settings.json` on shutdown with its in-memory configuration. You have two options:

1. **Use transmission-remote** (recommended):

   ```bash
   sudo ip netns exec qbt transmission-remote 127.0.0.1:9091 -n 'admin:password' -p 55555
   ```

2. **Edit while stopped** (not recommended for port forwarding):

   ```bash
   sudo systemctl stop transmission
   sudo nano /var/lib/transmission/.config/transmission-daemon/settings.json
   sudo systemctl start transmission
   ```

⚠️ **Never edit the config file while Transmission is running!**

### Port Not Updating

**Symptoms**: qBittorrent still uses old port

**Solutions**:

1. Check service logs: `journalctl -u protonvpn-portforward.service -n 50`
2. Verify config permissions: `ls -la /var/lib/qBittorrent/`
3. Run manual update: `sudo systemctl start protonvpn-portforward.service`
4. Check qBittorrent logs: `journalctl -u qbittorrent -n 50`

### Timer Not Running

**Symptoms**: Port forwarding doesn't renew automatically

**Solutions**:

1. Check timer status: `systemctl status protonvpn-portforward.timer`
2. Enable timer: `sudo systemctl enable protonvpn-portforward.timer`
3. Start timer: `sudo systemctl start protonvpn-portforward.timer`
4. Check next run: `systemctl list-timers | grep protonvpn`

### VPN Namespace Not Found

**Symptoms**: `ERROR: Namespace 'qbt' does not exist`

**Solutions**:

1. Check namespace service: `systemctl status qbt.service`
2. List namespaces: `sudo ip netns list`
3. Restart VPN: `sudo systemctl restart qbt.service`
4. Check SOPS secrets: `ls -la /run/secrets/ | grep vpn`

## Quick Reference: transmission-remote Commands

Essential `transmission-remote` commands for managing Transmission:

```bash
# Session info (shows all settings including port)
transmission-remote HOST:PORT -n 'user:pass' -si

# Update peer port (the safe way!)
transmission-remote HOST:PORT -n 'user:pass' -p PORT

# Port test (test if port is open externally)
transmission-remote HOST:PORT -n 'user:pass' --port-test

# Get statistics
transmission-remote HOST:PORT -n 'user:pass' -st

# List torrents
transmission-remote HOST:PORT -n 'user:pass' -l

# Add torrent
transmission-remote HOST:PORT -n 'user:pass' -a URL_OR_FILE

# Start/stop all torrents
transmission-remote HOST:PORT -n 'user:pass' --start-all
transmission-remote HOST:PORT -n 'user:pass' --stop-all

# Set speed limits (KB/s)
transmission-remote HOST:PORT -n 'user:pass' -d 5000  # Download
transmission-remote HOST:PORT -n 'user:pass' -u 1000  # Upload

# Helper script (with better error handling and validation)
./scripts/update-transmission-port.sh PORT -u user -p pass
./scripts/update-transmission-port.sh info -u user -p pass
```

**See also**: `man transmission-remote` for complete command reference

## Migration from Old Setup

The following components have been **removed** and **replaced**:

### ? Removed

- `modules/nixos/services/protonvpn-natpmp.nix` - Old service (ran from host)
- `services.protonvpn-natpmp.enable = true;` - Old configuration
- `scripts/get-protonvpn-forwarded-port.sh` - Outdated script
- `scripts/test-protonvpn-port-forwarding.sh` - Outdated script
- `scripts/find-protonvpn-forwarded-port.sh` - Outdated script

### ? New Implementation

- `modules/nixos/services/media-management/protonvpn-portforward.nix` - New module
- `scripts/protonvpn-natpmp-portforward.sh` - Full automation script
- `scripts/monitor-protonvpn-portforward.sh` - Monitoring script
- `scripts/verify-qbittorrent-vpn.sh` - Verification script
- Automatic systemd timer-based renewal
- Proper VPN namespace execution

### Key Differences

| Old | New |
|-----|-----|
| Ran from host network | Runs inside VPN namespace |
| Simple while loop | Proper systemd service + timer |
| No config updates | Automatically updates qBittorrent |
| No verification | Comprehensive monitoring |
| No error handling | Full error handling and logging |

## Files Modified

### Core Configuration

- `flake.nix` - Added VPN-Confinement input
- `hosts/jupiter/configuration.nix` - Removed old service
- `hosts/jupiter/default.nix` - Enabled VPN for qBittorrent

### Modules

- `modules/nixos/services/default.nix` - Removed old import
- `modules/nixos/services/media-management/default.nix` - Added new import
- `modules/nixos/services/media-management/protonvpn-portforward.nix` - New module
- `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix` - VPN setup
- `modules/nixos/services/media-management/qbittorrent.nix` - Updated for VPN

### Scripts (New)

- `scripts/protonvpn-natpmp-portforward.sh` - Automation
- `scripts/monitor-protonvpn-portforward.sh` - Monitoring
- `scripts/verify-qbittorrent-vpn.sh` - Verification

### Scripts (Updated)

- `scripts/diagnose-qbittorrent-seeding.sh` - Updated namespace `qbt`
- `scripts/test-qbittorrent-seeding-health.sh` - Updated namespace `qbt`
- `scripts/test-qbittorrent-connectivity.sh` - Updated namespace `qbt`

### Documentation

- `scripts/README.md` - Added new scripts documentation
- `docs/QBITTORRENT_VPN_MIGRATION_COMPLETE.md` - Updated namespaces
- `docs/QBITTORRENT_SEEDING_TROUBLESHOOTING.md` - Updated namespaces
- `CLAUDE.md` - Updated scripts list

## Success Criteria

? **Port forwarding is working correctly when:**

1. ? NAT-PMP query returns a valid port
2. ? qBittorrent config file shows the same port
3. ? qBittorrent is listening on the assigned port
4. ? External port checker confirms port is open
5. ? Torrents show incoming peer connections
6. ? Traffic only goes through VPN (no leaks)
7. ? Port forwarding persists across service restarts
8. ? NAT-PMP lease renews automatically every ~45 min
9. ? Timer shows next scheduled run
10. ? Monitoring script reports 0 issues

## Next Steps

1. **Rebuild system** to apply all changes:

   ```bash
   nh os switch
   ```

2. **Run verification**:

   ```bash
   ./scripts/verify-qbittorrent-vpn.sh
   ```

3. **Monitor for 24 hours** to ensure renewals work:

   ```bash
   watch -n 300 'systemctl list-timers | grep protonvpn'
   journalctl -u protonvpn-portforward.service -f
   ```

4. **Test torrents**:
   - Add a test torrent (Ubuntu ISO, etc.)
   - Verify incoming connections in qBittorrent WebUI
   - Check port at <https://www.yougetsignal.com/tools/open-ports/>

5. **Set up monitoring** (optional):
   - Add to cron or systemd timer for daily health checks
   - Monitor qBittorrent seeding ratios
   - Track port changes over time
