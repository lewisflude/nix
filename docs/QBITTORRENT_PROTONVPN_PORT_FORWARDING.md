# qBittorrent ProtonVPN Port Forwarding Setup

**Date:** 2025-01-27
**Status:** ✅ Configured - ProtonVPN port forwarding via NAT-PMP

## Overview

This document describes how ProtonVPN port forwarding is configured for qBittorrent using NAT-PMP (NAT Port Mapping Protocol). Port forwarding enables incoming BitTorrent connections, improving download speeds and peer connectivity.

## Configuration

### Automatic Port Forwarding Service

A systemd service (`protonvpn-port-forwarding`) automatically forwards ports from ProtonVPN's gateway using `natpmpc`. The service:

1. **Runs inside the VPN namespace** (`qbittor`) to access ProtonVPN's gateway
2. **Forwards both UDP and TCP ports** for BitTorrent traffic (default: port 6881)
3. **Continuously renews port mappings** every 45 seconds (60-second lifetime)
4. **Starts automatically** after the VPN namespace is ready

### Service Details

- **Service name:** `protonvpn-port-forwarding.service`
- **Gateway IP:** `10.2.0.1` (ProtonVPN WireGuard default gateway)
- **BitTorrent port:** `6881` (configurable via `qbittorrent.bittorrent.port`)
- **Protocol:** Both UDP and TCP

### How It Works

1. **Service starts** after VPN namespace (`qbittor`) is ready
2. **natpmpc requests port forwarding** from ProtonVPN gateway (`10.2.0.1`)
3. **ProtonVPN assigns a public port** (e.g., 53186) and forwards it to our private port (6881)
4. **Port mapping is renewed** every 45 seconds to keep it active
5. **qBittorrent listens on port 6881** (private port inside the namespace)
6. **qBittorrent's NAT-PMP** should automatically detect the forwarded port and report it to trackers

**Port Configuration:**

- **qBittorrent listening port:** `6881` (private port inside VPN namespace)
- **ProtonVPN public port:** Randomly assigned (e.g., 53186), changes on reconnection
- **Port forwarding:** Public port → Private port 6881 (handled by ProtonVPN gateway)

## Requirements

### WireGuard Configuration

**IMPORTANT:** Your ProtonVPN WireGuard config file must be generated with **NAT-PMP (port forwarding) enabled**:

1. Sign in to [Proton VPN Account](https://account.protonvpn.com/account)
2. Go to **Account** → **Downloads** → **WireGuard configuration**
3. Select a **P2P server** (double-arrow icon)
4. When generating the config, ensure **"NAT-PMP (port forwarding)"** is **enabled**
5. Download and store the config in sops as `vpn-confinement-qbittorrent`

### Packages

The following packages are automatically included:

- `libnatpmp` - Provides `natpmpc` command
- `iproute2` - Provides `ip netns exec` for namespace access

## Verification

### Check Service Status

```bash
sudo systemctl status protonvpn-port-forwarding.service
```

### Check Service Logs

```bash
sudo journalctl -u protonvpn-port-forwarding.service -f
```

You should see output like:

```
Mon Jan 27 12:00:00 GMT 2025
Mapped public port 53186 to private port 6881 UDP, lifetime 60s
Mapped public port 53186 to private port 6881 TCP, lifetime 60s
```

### Verify Port Forwarding in qBittorrent

1. Open qBittorrent WebUI: `http://192.168.15.1:8080/`
2. Go to **Options** → **Connection**
3. Check **"Port forwarding status"** - should show as active
4. The **"Port used for communications"** should match the forwarded port

### Test from VPN Namespace

```bash
# Check if gateway is reachable
sudo ip netns exec qbittor ping -c 1 10.2.0.1

# Test NAT-PMP directly
sudo ip netns exec qbittor natpmpc -g 10.2.0.1
```

Expected output:

```
Mapped public port 53186 to private port 6881 UDP, lifetime 60s
```

## Troubleshooting

### Service Fails to Start

**Error:** "VPN namespace qbittor not found"

**Solution:** Ensure VPN-Confinement namespace is configured and starts before this service:

```bash
sudo systemctl status qbittor.service
```

### Port Forwarding Fails

**Error:** "UDP/TCP port forwarding failed"

**Possible causes:**

1. **WireGuard config doesn't have NAT-PMP enabled** - Regenerate config with NAT-PMP enabled
2. **Wrong gateway IP** - Verify gateway IP:

   ```bash
   sudo ip netns exec qbittor ip route | grep default
   ```

   Update `protonvpnGateway` in `qbittorrent-vpn-confinement.nix` if different
3. **Not connected to P2P server** - Ensure WireGuard config is for a P2P server
4. **Free ProtonVPN plan** - Port forwarding requires a paid plan

### qBittorrent Doesn't Use Forwarded Port

**Symptom:** Port forwarding works but qBittorrent shows "Not forwarded" in WebUI

**Solution:**

1. Ensure `PortForwardingEnabled = true` in qBittorrent config (already enabled)
2. qBittorrent's NAT-PMP should automatically detect the forwarded port
3. If not working, you may need to manually configure the port in qBittorrent WebUI

### Gateway IP is Different

If your ProtonVPN gateway IP is not `10.2.0.1`:

1. Find the actual gateway:

   ```bash
   sudo ip netns exec qbittor ip route | grep default
   ```

2. Update `protonvpnGateway` in `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix`:

   ```nix
   protonvpnGateway = "10.2.0.X"; # Replace with your gateway IP
   ```

## Configuration Files

- **VPN-Confinement config:** `modules/nixos/services/media-management/qbittorrent-vpn-confinement.nix`
- **qBittorrent config:** `modules/nixos/services/media-management/qbittorrent-standard.nix`
- **WireGuard config:** Stored in sops as `vpn-confinement-qbittorrent`

## Related Documentation

- [ProtonVPN Port Forwarding Manual Setup](https://protonvpn.com/support/port-forwarding-manual-setup)
- [qBittorrent NAT-PMP Enabled](./QBITTORRENT_NAT_PMP_ENABLED.md)
- [qBittorrent VPN Architecture](./QBITTORRENT_VPN_ARCHITECTURE.md)

## Notes

- **Port assignment:** ProtonVPN assigns a random public port (e.g., 53186), which forwards to your private port (6881)
- **Port changes:** The public port may change when reconnecting to VPN - the service handles this automatically
- **qBittorrent listening port:** Keep qBittorrent configured to listen on port **6881** (the private port). ProtonVPN forwards the public port to this port automatically.
- **qBittorrent NAT-PMP:** qBittorrent's built-in NAT-PMP should detect and use the forwarded port automatically. If it doesn't work, you may need to manually configure qBittorrent with the public port shown in the service logs.
- **Security:** Port forwarding only works through ProtonVPN's secure gateway - your real IP is never exposed

### Why Port 6881?

**qBittorrent should listen on port 6881** (your private port) because:

- It's the standard BitTorrent port and works well with port forwarding
- ProtonVPN forwards the assigned public port to port 6881 automatically
- qBittorrent's NAT-PMP should detect the forwarded port and report it to trackers
- The public port changes on each VPN reconnection, so hardcoding it isn't practical

If qBittorrent's NAT-PMP doesn't work automatically, you can manually check the assigned public port in the service logs and configure it in qBittorrent WebUI → Options → Connection → Port used for communications.
