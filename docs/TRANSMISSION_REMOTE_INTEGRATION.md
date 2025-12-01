# Transmission Port Forwarding with transmission-remote

## Overview

This document describes the integration of Transmission BitTorrent client with ProtonVPN NAT-PMP port forwarding, using `transmission-remote` for safe configuration updates.

## Critical Information

### ⚠️ NEVER Edit Config Files Directly

**IMPORTANT**: The **ONLY** safe way to update Transmission settings while it's running is using `transmission-remote`.

**Why?**

1. Transmission keeps its configuration in memory
2. Manual edits to `settings.json` are **overwritten** when the daemon shuts down
3. Transmission writes its in-memory config back to disk on exit
4. This means **manual edits are lost** on restart

### ✅ The Correct Method: transmission-remote

```bash
# Update port
transmission-remote HOST:PORT -n 'username:password' -p NEW_PORT

# Example
sudo ip netns exec qbt transmission-remote 127.0.0.1:9091 -n 'admin:secret' -p 55555
```

## Architecture

### Port Forwarding Automation

The ProtonVPN NAT-PMP port forwarding automation (`scripts/protonvpn-natpmp-portforward.sh`) supports **both qBittorrent and Transmission**:

```
ProtonVPN NAT-PMP → Automation Script → ┬→ qBittorrent (WebUI API)
                                         └→ Transmission (transmission-remote)
```

### How It Works

1. **Query NAT-PMP**: Script queries ProtonVPN for forwarded port
2. **Update qBittorrent**: Uses WebUI API (HTTP POST)
3. **Update Transmission**: Uses `transmission-remote` CLI utility
4. **Verify**: Checks both clients are listening on the new port

### Key Components

| Component | Purpose | Method |
|-----------|---------|--------|
| `protonvpn-natpmp-portforward.sh` | Main automation script | Systemd service + timer |
| `update-transmission-port.sh` | Manual port updates | Standalone helper script |
| `transmission-remote` | Official CLI tool | Pre-installed with Transmission |

## Configuration

### Enable Transmission in NixOS

```nix
host.services.mediaManagement.transmission = {
  enable = true;

  # WebUI configuration
  webUIPort = 9091;

  # Authentication (REQUIRED for transmission-remote)
  authentication = {
    enable = true;
    username = "admin";
    password = "your-password";  # Or use SOPS secrets
    useSops = false;  # Set true for SOPS integration
  };

  # Initial peer port (will be updated by NAT-PMP)
  peerPort = 62000;

  # VPN confinement (shares namespace with qBittorrent)
  vpn = {
    enable = true;
    namespace = "qbt";
  };
};
```

### Enable Transmission in Port Forwarding Service

```nix
# Configure systemd service
systemd.services.protonvpn-portforward = {
  environment = {
    TRANSMISSION_ENABLED = "true";
    TRANSMISSION_HOST = "127.0.0.1:9091";

    # Option 1: Use SOPS secrets (recommended)
    TRANSMISSION_USERNAME_FILE = "/run/secrets/transmission/rpc/username";
    TRANSMISSION_PASSWORD_FILE = "/run/secrets/transmission/rpc/password";

    # Option 2: Use plain strings (not recommended)
    # TRANSMISSION_USERNAME = "admin";
    # TRANSMISSION_PASSWORD = "secret";
  };
};
```

### Using SOPS Secrets

```nix
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

host.services.mediaManagement.transmission.authentication = {
  enable = true;
  useSops = true;
};
```

## Usage

### Manual Port Update

Use the helper script for manual updates:

```bash
# Update port
./scripts/update-transmission-port.sh 55555 -u admin -p secret

# Get session info
./scripts/update-transmission-port.sh info -u admin -p secret

# Update in VPN namespace (default)
./scripts/update-transmission-port.sh 64243 -u admin -p secret -n qbt

# Update on remote host
./scripts/update-transmission-port.sh 55555 --host jupiter:9091 -u admin -p secret --no-namespace
```

### Automatic Port Updates

The systemd timer handles automatic updates:

```bash
# Check timer status
systemctl status protonvpn-portforward.timer

# View recent runs
journalctl -u protonvpn-portforward.service --since "24 hours ago"

# Manual trigger
sudo systemctl start protonvpn-portforward.service

# Watch logs
journalctl -u protonvpn-portforward.service -f
```

### Verify Configuration

```bash
# Get current port
sudo ip netns exec qbt transmission-remote 127.0.0.1:9091 -n 'admin:secret' -si | grep "Peer port"

# Check listening
sudo ip netns exec qbt ss -tuln | grep <PORT>

# Full verification
./scripts/check-torrent-port.sh
```

## transmission-remote Commands

### Session Management

```bash
# Get session info (includes port, limits, etc.)
transmission-remote HOST:PORT -n 'user:pass' -si

# Get statistics
transmission-remote HOST:PORT -n 'user:pass' -st
```

### Port Configuration

```bash
# Update peer port
transmission-remote HOST:PORT -n 'user:pass' -p PORT

# Test port (external connectivity)
transmission-remote HOST:PORT -n 'user:pass' --port-test
```

### Speed Limits

```bash
# Set download limit (KB/s)
transmission-remote HOST:PORT -n 'user:pass' -d 5000

# Set upload limit (KB/s)
transmission-remote HOST:PORT -n 'user:pass' -u 1000

# Disable limits
transmission-remote HOST:PORT -n 'user:pass' -D  # Download unlimited
transmission-remote HOST:PORT -n 'user:pass' -U  # Upload unlimited
```

### Torrent Management

```bash
# List all torrents
transmission-remote HOST:PORT -n 'user:pass' -l

# Add torrent
transmission-remote HOST:PORT -n 'user:pass' -a URL_OR_FILE

# Start all torrents
transmission-remote HOST:PORT -n 'user:pass' --start-all

# Stop all torrents
transmission-remote HOST:PORT -n 'user:pass' --stop-all

# Remove torrent (by ID)
transmission-remote HOST:PORT -n 'user:pass' -t ID --remove
```

## Troubleshooting

### Port Not Updating

**Symptoms**: Transmission still uses old port after automation runs

**Solutions**:

1. Check service logs:

   ```bash
   journalctl -u protonvpn-portforward.service -n 50 | grep -i transmission
   ```

2. Verify `transmission-remote` is available:

   ```bash
   which transmission-remote
   ```

3. Test manual update:

   ```bash
   sudo ip netns exec qbt transmission-remote 127.0.0.1:9091 -n 'admin:secret' -p 55555
   ```

4. Check credentials:

   ```bash
   # If using SOPS
   cat /run/secrets/transmission/rpc/username
   cat /run/secrets/transmission/rpc/password

   # If using config file
   sudo grep "rpc-username\|rpc-password" /var/lib/transmission/.config/transmission-daemon/settings.json
   ```

### Authentication Fails

**Symptoms**: `"Unauthorized User"` or `"401 Unauthorized"`

**Solutions**:

1. Verify authentication is enabled:

   ```bash
   sudo grep "rpc-authentication-required" /var/lib/transmission/.config/transmission-daemon/settings.json
   ```

2. Test credentials manually:

   ```bash
   sudo ip netns exec qbt transmission-remote 127.0.0.1:9091 -n 'admin:secret' -si
   ```

3. Check whitelist settings (should allow 127.0.0.1):

   ```bash
   sudo grep "rpc-whitelist" /var/lib/transmission/.config/transmission-daemon/settings.json
   ```

4. Temporarily disable auth for testing:

   ```nix
   host.services.mediaManagement.transmission.authentication.enable = false;
   ```

### Config Changes Lost

**Symptoms**: Manual edits to `settings.json` disappear after restart

**Solution**: This is **expected behavior**. You have two options:

1. **Use transmission-remote** (recommended):

   ```bash
   sudo ip netns exec qbt transmission-remote 127.0.0.1:9091 -n 'admin:secret' -p 55555
   ```

2. **Edit while stopped** (not recommended):

   ```bash
   sudo systemctl stop transmission
   sudo nano /var/lib/transmission/.config/transmission-daemon/settings.json
   sudo systemctl start transmission
   ```

### Namespace Issues

**Symptoms**: Cannot reach Transmission from automation script

**Solutions**:

1. Verify namespace exists:

   ```bash
   sudo ip netns list | grep qbt
   ```

2. Check Transmission is in namespace:

   ```bash
   systemctl status transmission | grep "Namespace"
   ```

3. Test connectivity:

   ```bash
   sudo ip netns exec qbt ping -c 3 127.0.0.1
   sudo ip netns exec qbt curl -s http://127.0.0.1:9091
   ```

## Comparison: qBittorrent vs Transmission

| Feature | qBittorrent | Transmission |
|---------|-------------|--------------|
| **Update Method** | WebUI API (HTTP) | `transmission-remote` CLI |
| **Authentication** | Optional (localhost bypass) | Required for RPC |
| **Config Format** | INI-style | JSON |
| **Config Safety** | Can edit while running | **NEVER edit while running** |
| **Port Update** | API call | CLI command |
| **Verification** | Parse config file | Query via CLI |

## Best Practices

1. ✅ **Always use `transmission-remote`** for live config changes
2. ✅ **Use SOPS secrets** for RPC credentials
3. ✅ **Enable authentication** for security
4. ✅ **Test manually** before relying on automation
5. ✅ **Monitor logs** for automation failures

6. ❌ **Never edit `settings.json`** while Transmission is running
7. ❌ **Don't hardcode credentials** in config files
8. ❌ **Don't assume config persists** without using `transmission-remote`

## Scripts Reference

| Script | Purpose | Usage |
|--------|---------|-------|
| `protonvpn-natpmp-portforward.sh` | Automated port updates | Systemd service |
| `update-transmission-port.sh` | Manual port updates | Standalone helper |
| `check-torrent-port.sh` | Verify port configuration | Diagnostic |
| `monitor-protonvpn-portforward.sh` | Health monitoring | Diagnostic |

## Resources

- **Main Documentation**: `docs/PROTONVPN_PORT_FORWARDING_SETUP.md`
- **Transmission Module**: `modules/nixos/services/media-management/transmission.nix`
- **Automation Script**: `scripts/protonvpn-natpmp-portforward.sh`
- **Helper Script**: `scripts/update-transmission-port.sh`
- **Official Manual**: `man transmission-remote`

## Summary

The integration uses `transmission-remote` as the **only safe method** for updating Transmission configuration while running. The automation script handles port forwarding updates automatically, and the helper script provides convenient manual control.

**Key Takeaway**: Never edit Transmission's config files directly. Always use `transmission-remote`.
