# Systemd Monitoring Improvements

This document describes the safe monitoring improvements added to the NixOS configuration.

## Overview

The following new monitoring modules were added to improve visibility and reliability of critical services:

1. **Service Failure Notifications** - Alert when critical services fail
2. **qBittorrent VPN Health Check** - Ensure qBittorrent stays bound to VPN
3. **ProtonVPN Port Forward Monitor** - Ensure port forwarding stays fresh
4. **Boot Performance Analysis** - Track boot time performance

All changes are **non-breaking** and only add monitoring/notification capabilities without modifying existing service behavior.

## 1. Service Failure Notifications

**Module:** `modules/nixos/system/service-monitoring.nix`

### What It Does

- Creates a template service (`notify-failure@.service`) that logs detailed failure information
- Automatically attaches to critical services via `OnFailure=` directive
- Logs failure details to journald (viewable with `journalctl -u notify-failure@*`)
- Optionally sends email notifications when configured

### Configuration

```nix
services.systemd-monitoring = {
  enable = true;  # Default: enabled
  
  # Optional email notifications (requires working mail setup)
  enableEmailNotifications = false;  # Default: disabled (logs to journal)
  notificationEmail = "root@localhost";
  
  # Services to monitor (defaults to critical services)
  criticalServices = [
    "qbittorrent.service"
    "home-assistant.service"
    "protonvpn-portforward.service"
  ];
};
```

### How to Use

When a monitored service fails, check the logs:

```bash
# View failure notification details
journalctl -u notify-failure@qbittorrent.service

# View the failed service status
systemctl status qbittorrent.service

# View recent logs from failed service
journalctl -u qbittorrent.service -n 100
```

### Enable Email Notifications

To receive email alerts (requires configured mail system):

```nix
services.systemd-monitoring = {
  enableEmailNotifications = true;
  notificationEmail = "admin@example.com";
};
```

## 2. qBittorrent VPN Health Check

**Module:** `modules/nixos/services/media-management/qbittorrent/vpn-health-check.nix`

### What It Does

- Periodically verifies qBittorrent is properly bound to VPN namespace
- Checks VPN interface is up and functional
- Verifies external IP connectivity through VPN
- Automatically restarts qBittorrent if VPN binding check fails (optional)

### Configuration

```nix
host.services.mediaManagement.qbittorrent.vpn.healthCheck = {
  enable = true;  # Default: enabled when VPN is enabled
  checkInterval = "2min";  # Default: check every 2 minutes
  startDelay = "5min";  # Default: wait 5min after boot
  restartOnFailure = true;  # Default: auto-restart on failure
};
```

### How to Use

The health check runs automatically. To manually check status:

```bash
# View health check logs
journalctl -u qbittorrent-vpn-health.service

# Manually trigger health check
systemctl start qbittorrent-vpn-health.service

# Check timer status
systemctl status qbittorrent-vpn-health.timer
```

### Health Check Criteria

The service verifies:

1. ✓ qBittorrent service is running
2. ✓ VPN namespace exists
3. ✓ VPN interface is UP in namespace
4. ✓ Can obtain external IP through VPN

If any check fails and `restartOnFailure = true`, qBittorrent is automatically restarted.

## 3. ProtonVPN Port Forward Monitor

**Module:** `modules/nixos/services/media-management/protonvpn-portforward-monitor.nix`

### What It Does

- Monitors the age of the port forwarding state file
- Ensures port forward lease is being renewed regularly
- Automatically restarts the port forwarding timer if state becomes stale
- Prevents silent port forwarding failures

### Configuration

```nix
host.services.mediaManagement.qbittorrent.vpn.portForwarding.monitoring = {
  enable = true;  # Default: enabled when port forwarding enabled
  checkInterval = "5min";  # Default: check every 5 minutes
  maxAge = 300;  # Default: 5 minutes (in seconds)
  restartTimerOnStale = true;  # Default: auto-restart timer
};
```

### How to Use

The monitor runs automatically. To check status:

```bash
# View monitoring logs
journalctl -u protonvpn-portforward-monitor.service

# Manually trigger check
systemctl start protonvpn-portforward-monitor.service

# Check timer status
systemctl status protonvpn-portforward-monitor.timer

# View current port forward state
cat /var/lib/protonvpn-portforward.state
```

### What Gets Monitored

- **State file:** `/var/lib/protonvpn-portforward.state`
- **Max age:** 300 seconds (5 minutes) by default
- **Expected behavior:** File should update every 45 seconds (per ProtonVPN official renewal interval)

If state file is older than `maxAge`, the timer is restarted to force a renewal.

## 4. Boot Performance Analysis

**Module:** `modules/nixos/system/boot-analysis.nix`

### What It Does

- Automatically runs `systemd-analyze` after each boot
- Logs boot time, critical chain, and slowest units
- Helps identify boot performance regressions
- Disabled by default (opt-in)

### Configuration

```nix
services.boot-analysis = {
  enable = false;  # Default: disabled (opt-in)
  delay = "5min";  # Default: wait 5min after boot
};
```

### How to Use

Enable the service to get automatic boot analysis:

```nix
services.boot-analysis.enable = true;
```

After boot, view the analysis:

```bash
# View boot analysis logs
journalctl -u boot-analysis.service

# Or run manually anytime
systemd-analyze
systemd-analyze critical-chain
systemd-analyze blame | head -n 20
```

## Impact and Safety

### What Changed

**New files added:**
- `modules/nixos/system/service-monitoring.nix`
- `modules/nixos/system/boot-analysis.nix`
- `modules/nixos/services/media-management/qbittorrent/vpn-health-check.nix`
- `modules/nixos/services/media-management/protonvpn-portforward-monitor.nix`

**Modified files:**
- `modules/nixos/system/default.nix` - Added new module imports
- `modules/nixos/services/media-management/default.nix` - Added monitor import
- `modules/nixos/services/media-management/qbittorrent/default.nix` - Added health check import

### What Didn't Change

- ✅ No existing service configurations were modified
- ✅ No service behavior changes (only monitoring added)
- ✅ All monitoring is non-intrusive
- ✅ Auto-restart features are optional and safe (enable existing systemd restart logic)
- ✅ No new dependencies added
- ✅ No breaking changes

### Safety Features

1. **Failure notifications** - Only logs by default, email requires explicit opt-in
2. **Health checks** - Run as separate services, don't block main services
3. **Auto-restart** - Uses systemd's built-in restart logic, respects rate limits
4. **Monitoring** - Read-only operations with timeouts and error handling
5. **Boot analysis** - Disabled by default, runs after boot completes

## Verification

After rebuilding, verify the changes:

```bash
# Check that monitoring service is available
systemctl status notify-failure@.service

# Check qBittorrent health check timer is active
systemctl status qbittorrent-vpn-health.timer

# Check port forward monitor timer is active
systemctl status protonvpn-portforward-monitor.timer

# List all new timers
systemctl list-timers | grep -E "(qbittorrent-vpn-health|protonvpn-portforward-monitor)"

# Check for any service failures
systemctl --failed
```

## Monitoring in Action

### Example: Service Failure Notification

When a monitored service fails:

```
Jan 22 12:34:56 jupiter systemd[1]: qbittorrent.service: Failed with result 'exit-code'.
Jan 22 12:34:56 jupiter systemd[1]: Starting Notify about failed qbittorrent.service...
Jan 22 12:34:56 jupiter service-failure-notification[12345]: ========================================
Jan 22 12:34:56 jupiter service-failure-notification[12345]: CRITICAL: Service qbittorrent.service has failed
Jan 22 12:34:56 jupiter service-failure-notification[12345]: ========================================
Jan 22 12:34:56 jupiter service-failure-notification[12345]: ● qbittorrent.service - qBittorrent-nox
Jan 22 12:34:56 jupiter service-failure-notification[12345]:      Loaded: loaded (/etc/systemd/system/qbittorrent.service; enabled)
Jan 22 12:34:56 jupiter service-failure-notification[12345]:      Active: failed (Result: exit-code)
```

### Example: VPN Health Check Success

```
Jan 22 12:35:00 jupiter qbittorrent-vpn-health[12350]: Checking qBittorrent VPN binding...
Jan 22 12:35:01 jupiter qbittorrent-vpn-health[12350]: ✓ VPN health check passed
Jan 22 12:35:01 jupiter qbittorrent-vpn-health[12350]:   Namespace: qbt
Jan 22 12:35:01 jupiter qbittorrent-vpn-health[12350]:   Interface: proton0
Jan 22 12:35:01 jupiter qbittorrent-vpn-health[12350]:   External IP: 185.107.56.123
```

### Example: Port Forward Monitor

```
Jan 22 12:36:00 jupiter protonvpn-portforward-monitor[12360]: Checking ProtonVPN port forward freshness...
Jan 22 12:36:00 jupiter protonvpn-portforward-monitor[12360]: ✓ Port forward is fresh (42s old)
Jan 22 12:36:00 jupiter protonvpn-portforward-monitor[12360]:   Public port: 12345
Jan 22 12:36:00 jupiter protonvpn-portforward-monitor[12360]:   Private port: 12345
```

## Troubleshooting

### Disable a Specific Monitor

```nix
# Disable VPN health check
host.services.mediaManagement.qbittorrent.vpn.healthCheck.enable = false;

# Disable port forward monitor
host.services.mediaManagement.qbittorrent.vpn.portForwarding.monitoring.enable = false;

# Disable failure notifications
services.systemd-monitoring.enable = false;
```

### Adjust Check Intervals

```nix
# Less frequent VPN health checks
host.services.mediaManagement.qbittorrent.vpn.healthCheck.checkInterval = "5min";

# More frequent port forward monitoring
host.services.mediaManagement.qbittorrent.vpn.portForwarding.monitoring.checkInterval = "2min";
```

### Disable Auto-Restart

```nix
# Don't auto-restart on VPN health check failure
host.services.mediaManagement.qbittorrent.vpn.healthCheck.restartOnFailure = false;

# Don't auto-restart port forward timer
host.services.mediaManagement.qbittorrent.vpn.portForwarding.monitoring.restartTimerOnStale = false;
```

## Next Steps

1. **Rebuild system** to activate monitoring:
   ```bash
   nh os switch
   ```

2. **Monitor logs** for a few days to ensure everything works:
   ```bash
   journalctl -f | grep -E "(notify-failure|vpn-health|portforward-monitor)"
   ```

3. **Consider enabling email notifications** once mail is configured:
   ```nix
   services.systemd-monitoring.enableEmailNotifications = true;
   ```

4. **Enable boot analysis** if you want to track boot performance:
   ```nix
   services.boot-analysis.enable = true;
   ```

## References

- [Systemd Patterns in NixOS](./SYSTEMD_PATTERNS_NIXOS.md) - Full guide to systemd patterns
- [systemd.service(5)](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
- [systemd.timer(5)](https://www.freedesktop.org/software/systemd/man/systemd.timer.html)
- [systemd-analyze(1)](https://www.freedesktop.org/software/systemd/man/systemd-analyze.html)
